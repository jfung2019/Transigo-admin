defmodule TransigoAdmin.Job.DailyAssignment do
  use Oban.Worker, queue: :transaction, max_attempts: 5

  alias TransigoAdmin.{Credit, Credit.Transaction, Job.Helper}
  alias SendGrid.{Mail, Email}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Credit.list_transactions_status_originated()
    |> Enum.each(&send_assignment_notice(&1))

    :ok
  end

  defp list_transactions_status_originated(%Transaction{} = transaction) do
    case download_assignment_notice(transaction) do
      {:ok, filename} ->
        Email.build()
        |> Email.put_from("tcaas@transigo.io", "Transigo")
        |> Email.add_to(transaction.importer.contact.email)
        |> Email.put_subject("Transigo Assignment Notice")
        |> Email.put_text("Transigo Assignment Notice for credits")
        |> Email.add_attachment(%{content: "pdf", filename: filename})
        |> Mail.send()

        File.rm(filename)

        :ok

      {:error, _} ->
        :error
    end
  end

  defp download_assignment_notice(%{
         transaction_uid: transaction_uid,
         importer: importer,
         invoice_date: invoice_date,
         invoice_ref: invoice_ref,
         credit_term_days: credit_term_days
       }) do
    case download_invoice_file(transaction_uid) do
      {:ok, invoice_file} ->
        invoice_file_basename = Path.basename(invoice_file)

        payload = [
          {"closing_date", ""},
          {"document_signature_date", ""},
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
          {"tags", true},
          {"transigo",
            Jason.encode!(%{
              address: "7400 Beaufont Springs Drive, Suite 300 PMB#9655, Richmond, VA 23225, USA",
              contact: "Nir Tal",
              contact_email: "nir@transigo.io",
              name: "Transigo, Inc.",
              phone: "888-783-6052",
              snail_mail:
                "Transigo Inc., 7400 Beaufont Springs Drive, Suite 300 PMB#9655 Richmond, VA 23225",
              support_email: "support@transigo.io"
            })}
        ]

        {:error, _} ->
          :error
    end
  end

  defp get_importer_address(importer) do
  end
end
