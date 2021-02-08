defmodule TransigoAdmin.Job.Helper do
  alias TransigoAdmin.{Account, Account.User}
  alias TransigoAdmin.{Credit, Credit.Transaction}

  def notify_api_users(result, event) do
    payload =
      %{
        event: event,
        result: result
      }
      |> Jason.encode!()

    Account.list_users_with_webhook()
    |> Enum.each(&post_webhook_event(&1, payload))
  end

  defp post_webhook_event(%User{webhook: webhook}, payload),
    do: HTTPoison.post(webhook, payload, [{"Content-Type", "application/json"}])

  def cal_total_sum(transactions),
    do:
      Enum.reduce(transactions, %{sum: 0}, fn %{sum: sum}, acc ->
        %{sum: acc.sum + sum}
      end)

  def move_transaction_to_state(%Transaction{} = transaction, state) do
    case Credit.update_transaction(transaction, %{transaction_state: state}) do
      {:ok, transaction} ->
        %{
          transctionUID: transaction.transaction_UID,
          sum: Float.round(transaction.financed_sum, 2),
          transactionDateTime: transaction.repaid_datetime
        }

      {:error, _} ->
        nil
    end
  end
end
