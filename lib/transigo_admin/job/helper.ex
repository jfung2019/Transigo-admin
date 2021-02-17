defmodule TransigoAdmin.Job.Helper do
  alias TransigoAdmin.{Account, Account.User, Account.WebhookEvent}
  alias TransigoAdmin.{Credit, Credit.Transaction}

  def notify_api_users(result, event) do
    now = Timex.now()

    payload =
      %{
        event: event,
        result: result,
        metadata: %{
          currentDateTime: now,
          originalDateTime: now,
          retryNumber: 0
        }
      }
      |> Jason.encode!()

    {:ok, webhook_event} = Account.create_webhook_event(%{event: event, result: result})

    Account.list_users()
    |> Enum.each(&send_webhook_event(&1, payload, webhook_event))
  end

  def post_webhook_event(%User{webhook: webhook}, payload),
    do: HTTPoison.post(webhook, payload, [{"Content-Type", "application/json"}])

  def send_webhook_event(%User{id: user_id} = user, payload, %WebhookEvent{id: event_id}) do
    {:ok, user_event} =
      Account.create_webhook_user_event(%{user_id: user_id, webhook_event_id: event_id})

    case post_webhook_event(user, payload) do
      {:ok, %{status_code: 200}} ->
        Account.update_webhook_user_event(user_event, %{state: "success"})

      _ ->
        Account.update_webhook_user_event(user_event, %{state: "init_send_fail"})
    end
  end

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
