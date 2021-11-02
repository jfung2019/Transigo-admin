defmodule TransigoAdmin.Job.HourlyAssignment do
  @moduledoc """
  List the transaction that has  the state of originated
  generate assignment notice and send it to importer
  """
  use Oban.Worker, queue: :transaction, max_attempts: 1

  alias TransigoAdmin.{Credit, Credit.Transaction}
  alias SendGrid.{Mail, Email}

  @hs_api Application.compile_env(:transigo_admin, :hs_api)

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Credit.list_transactions_by_state("assignment_signed", [:exporter, importer: [:contact]])
    |> Enum.each(&send_assignment_notice/1)

    :ok
  end

  defp send_assignment_notice(%Transaction{} = transaction) do
    case get_signed_assignment_notice(transaction) do
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

            :ok

          _ ->
            :error
        end

      {:error, _} ->
        :error
    end
  end

  defp get_signed_assignment_notice(%Transaction{} = transaction) do
    with {:ok, file_url} <-
           @hs_api.get_signature_file_url(transaction.hellosign_assignment_signature_request_id),
         {:ok, %{status_code: 200, body: pdf_content}} <- HTTPoison.get(file_url),
         {:ok, temp} <- Briefly.create(extname: ".pdf"),
         :ok <- File.write(temp, pdf_content) do
      {:ok, temp}
    end
  end

  defp mark_transaction_as_assigned(:ok, %Transaction{} = transaction),
    do: Credit.update_transaction(transaction, %{transaction_state: "assigned"})

  defp mark_transaction_as_assigned(error, _transaction), do: error
end
