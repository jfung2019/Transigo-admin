defmodule TransigoAdmin.Job.DailyAssignment do
  use Oban.Worker, queue: :transaction, max_attempts: 5

  alias TransigoAdmin.{Credit, Credit.Transaction, Job.Helper}
  alias SendGrid.{Mail, Email}

  @util_api Application.compile_env(:transigo_admin, :util_api)
  @s3_api Application.compile_env(:transigo_admin, :s3_api)
  @hs_api Application.compile_env(:transigo_admin, :hs_api)

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Credit.list_transactions_status_originated()
    |> Enum.each(&send_assignment_notice(&1))

    :ok
  end

  defp send_assignment_notice(%Transaction{} = transaction) do
    case download_assignment_notice(transaction) do
      {:ok, filename} ->
        case File.read(filename) do
          {:ok, content} ->
            Email.build()
            |> Email.put_from("tcaas@transigo.io", "Transigo")
            |> Email.add_to(transaction.importer.contact.email)
            |> Email.put_subject("Transigo Assignment Notice")
            |> Email.put_text("Transigo Assignment Notice for credits")
            |> Email.add_attachment(%{
              content: Base.encode64(content),
              filename: Path.basename(filename),
              type: "application/pdf",
              disposition: "attachment"
            })
            |> Mail.send()
            |> mark_transaction_as_assigned(transaction)

            File.rm(filename)

            :ok

          _ ->
            :error
        end

      {:error, _} ->
        :error
    end
  end

  defp download_assignment_notice(
         %{
           transaction_uid: transaction_uid,
           importer: importer,
           invoice_date: invoice_date,
           invoice_ref: invoice_ref,
           credit_term_days: credit_term_days,
           hellosign_signature_request_id: hs_request_id
         } = transaction
       ) do
    case @s3_api.download_invoice_file(transaction) do
      {:ok, invoice_file} ->
        invoice_file_basename = Path.basename(invoice_file)

        result =
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
               name: importer.business_name
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
          |> @util_api.generate_assignment_notice(transaction_uid)

        File.rm(invoice_file)

        result

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

  defp mark_transaction_as_assigned(:ok, transaction),
    do: Credit.update_transaction(transaction, %{transaction_state: "assigned"})

  defp mark_transaction_as_assigned(error, _transaction), do: error
end
