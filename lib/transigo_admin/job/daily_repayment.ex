defmodule TransigoAdmin.Job.DailyRepayment do
  use Oban.Worker, queue: :default, max_attempts: 5

  import Ecto.Query, warn: false

  alias TransigoAdmin.{Credit, Credit.Transaction, Job.Helper}
  alias SendGrid.{Mail, Email}

  @dwolla_api Application.compile_env(:transigo_admin, :dwolla_api)

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # notify customers of the dwolla pull
    Credit.list_transactions_due_in_3_days()
    |> Enum.each(&send_transaction_due_email(&1))

    {:ok, access_token} = @dwolla_api.dwolla_auth()

    # create transfer from customer to Transigo
    Credit.list_transactions_due_today()
    |> Enum.each(&create_dwolla_transfer(&1, access_token))

    # check transfer status
    Credit.list_transactions_by_state("pull_initiated")
    |> Enum.map(&check_transaction_dwolla_status(&1, access_token))
    |> Enum.reject(&is_nil(&1))
    |> Helper.notify_api_users("daily_repayment")

    :ok
  end

  defp send_transaction_due_email(%Transaction{} = transaction) do
    contact = TransigoAdmin.Account.get_contact_by_importer(transaction.importer_id)

    repaid_amount =
      transaction.second_installment_USD
      |> Float.round(2)
      |> Float.to_string()

    message =
      "You have a transaction due in 3 days. Please have USD#{repaid_amount} ready in your account."

    Email.build()
    |> Email.put_from("tcaas@transigo.io", "Transigo")
    |> Email.add_to(contact.email)
    |> Email.put_subject("Transaction Dues in 3 days")
    |> Email.put_text(message)
    |> Mail.send()

    transaction
    |> Credit.update_transaction(%{transaction_state: "email_sent"})
  end

  defp create_dwolla_transfer(%Transaction{} = transaction, access_token) do
    %{importer_id: importer_id, second_installment_USD: repaid_value} = transaction
    %{funding_source_url: funding_source_url} = Credit.find_granted_quota(importer_id)
    repaid_value = Float.round(repaid_value, 2)

    body =
      %{
        _links: %{
          source: %{href: funding_source_url},
          destination: %{
            href: Application.get_env(:transigo_admin, :dwolla_master_funding_source)
          }
        },
        amount: %{
          currency: "USD",
          value: repaid_value
        }
      }

    case @dwolla_api.dwolla_post("transfers", access_token, body) do
      {:ok, %{headers: headers, body: body}} ->
        case Enum.into(headers, %{}) do
          %{"Location" => transfer_url} ->
            attrs = %{
              transaction_state: "pull_initiated",
              dwolla_repayment_transfer_url: transfer_url
            }

            Credit.update_transaction(transaction, attrs)

          _ ->
            # failed to create transfer
            {:error, Jason.decode!(body)}
        end

      {:error, _} = error_tuple ->
        error_tuple
    end
  end

  defp check_transaction_dwolla_status(%Transaction{} = transaction, access_token) do
    case @dwolla_api.dwolla_get(transaction.dwolla_repayment_transfer_url, access_token) do
      {:ok, %{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"status" => "processed"}} ->
            attrs = %{transaction_state: "repaid", repaid_datetime: Timex.now()}
            {:ok, transaction} = Credit.update_transaction(transaction, attrs)

            repaid_amount =
              transaction.second_installment_USD
              |> Float.round(2)

            %{
              transactionUID: transaction.transaction_UID,
              repaymentSum: repaid_amount,
              transactionDatetime: transaction.repaid_datetime
            }

          _ ->
            nil
        end

      _ ->
        nil
    end
  end
end
