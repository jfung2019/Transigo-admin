defmodule TransigoAdmin.Job.DailyRepayment do
  @moduledoc """
  send transaction due email to importers with transaction due in 3 days
  create dwolla transfer for transaction due today
  for transaction that had dwolla transfer created, send webhook event to users
  """
  use Oban.Worker, queue: :transaction, max_attempts: 1

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
    |> format_webhook_result()
    |> Helper.notify_api_users("daily_repayment")

    :ok
  end

  defp send_transaction_due_email(%Transaction{} = transaction) do
    contact = TransigoAdmin.Account.get_contact_by_importer(transaction.importer_id)

    repaid_amount =
      transaction.second_installment_usd
      |> :erlang.float_to_binary(decimals: 2)

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
    repaid_value =
      transaction.second_installment_usd
      |> :erlang.float_to_binary(decimals: 2)

    request_body = %{
      _links: %{
        source: %{
          href: get_funding_source_url(transaction.importer_id)
        },
        destination: %{
          href: Application.get_env(:transigo_admin, :dwolla_master_funding_source)
        }
      },
      amount: %{
        currency: "USD",
        value: repaid_value
      }
    }

    case @dwolla_api.dwolla_post("transfers", access_token, request_body) do
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
            {:error, body}
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

            %{
              transactionUID: transaction.transaction_uid,
              sum: Float.round(transaction.second_installment_usd, 2),
              transactionDatetime: transaction.repaid_datetime
            }

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  defp format_webhook_result(transactions) do
    total = Helper.cal_total_sum(transactions)

    %{
      repaymentSum: total.sum,
      dailyRepayments: transactions
    }
  end

  defp get_funding_source_url(importer_id) do
    case Credit.find_granted_quota(importer_id) do
      %{funding_source_url: funding_source_url} ->
        funding_source_url

      _ ->
        nil
    end
  end
end
