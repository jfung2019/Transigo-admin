defmodule TransigoAdmin.Job.DailyAssignment do
  @moduledoc """
  List the transaction that has  the state of originated
  generate assignment notice and send it to importer
  """
  use Oban.Worker, queue: :transaction, max_attempts: 1

  alias TransigoAdmin.{Credit, Credit.Transaction, Job.Helper}

  @util_api Application.compile_env(:transigo_admin, :util_api)
  @s3_api Application.compile_env(:transigo_admin, :s3_api)
  @hs_api Application.compile_env(:transigo_admin, :hs_api)

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Credit.list_transactions_by_state("originated", [:exporter, importer: [:contact]])
    |> Enum.each(&generate_sign_assignment/1)

    :ok
  end

  def generate_sign_assignment(%Transaction{} = transaction) do
    with {:ok, assignment_path} <- download_assignment_notice(transaction),
         {:ok, assignment_payload} <- get_assignment_payload(assignment_path),
         {:ok, %{"signature_request" => %{"signature_request_id" => req_id}} = _sign_req} <-
           @hs_api.create_signature_request(assignment_payload) do
      Credit.update_transaction(transaction, %{
        transaction_state: "assignment_awaiting",
        hellosign_assignment_signature_request_id: req_id
      })
    else
      _ ->
        {:error, message: "failed to create signature request for assignment"}
    end
  end

  defp get_assignment_payload(assignment_path) do
    assignment_basename = Path.basename(assignment_path)

    payload = [
      {"client_id", Application.get_env(:transigo_admin, :hs_client_id)},
      {"test_mode", Application.get_env(:transigo_admin, :hellosign_test_mode)},
      {"use_text_tags", "1"},
      {"hide_text_tags", "1"},
      {:file, assignment_path, {"form-data", [name: "file[0]", filename: assignment_basename]},
       []},
      {"signers[1][name]", "Nir Tal"},
      {"signers[1][email_address]", "nir.tal@transigo.io"}
    ]

    {:ok, payload}
  end

  defp download_assignment_notice(
         %Transaction{} =
           %{
             transaction_uid: transaction_uid,
             importer: importer,
             invoice_date: invoice_date,
             invoice_ref: invoice_ref,
             credit_term_days: credit_term_days,
             hellosign_signature_request_id: hs_request_id
           } = transaction
       ) do
    case @s3_api.download_file(transaction, :invoice) do
      {:ok, invoice_file} ->
        invoice_file_basename = Path.basename(invoice_file)

        [
          {"closing_date", get_hs_doc_create_date(hs_request_id)},
          {"document_signature_date", Timex.now() |> Timex.format!("{ISOdate}")},
          {"financier", "Transigo"},
          {"fname", "#{transaction_uid}_assignment"},
          {"importer",
           Jason.encode!(%{
             address: get_importer_address(importer),
             contact: "#{importer.contact.first_name} #{importer.contact.last_name}",
             email: importer.contact.email,
             name: importer.business_name,
             bank_account: importer.bank_account,
             bank_name: importer.bank_name
           })},
          {"invoice",
           Jason.encode!(%{
             invoice_date: invoice_date,
             invoice_fname: invoice_file_basename,
             invoice_num: invoice_ref,
             second_installment_date: Timex.shift(invoice_date, days: credit_term_days)
           })},
          {:file, invoice_file,
           {"form-data", [name: "invoice_file", filename: invoice_file_basename]}, []},
          {"tags", "true"},
          {"transigo", Helper.get_transigo_doc_info()}
        ]
        |> @util_api.generate_assignment_notice()

      {:error, _} ->
        :error
    end
  end

  defp get_importer_address(%{
         business_address_street_address: street,
         business_address_city: city,
         business_address_state: state,
         business_address_zip: zip,
         business_address_country: country
       }) do
    "#{street}, #{city}, #{state}, #{zip}, #{country}"
  end

  def get_hs_doc_create_date(hs_request_id) do
    case @hs_api.get_signature_request(hs_request_id) do
      {:ok, %{"signature_request" => %{"created_at" => created_at}}} ->
        DateTime.from_unix!(created_at, :second)
        |> Timex.format!("{ISOdate}")

      _ ->
        nil
    end
  end
end
