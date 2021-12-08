defmodule TransigoAdmin.Job.HelperApi do
  alias TransigoAdmin.Account.{User, WebhookEvent}
  alias TransigoAdmin.Credit.Transaction

  @callback notify_api_users(map, String.t()) :: [tuple]
  @callback post_webhook_event(User.t(), map) :: tuple
  @callback send_webhook_event(User.t(), String.t(), Webhook.t()) :: tuple
  @callback cal_total_sum(map) :: map
  @callback move_transaction_to_state(Transaction.t(), String.t()) :: map | nil
  @callback put_datetime(map, Transaction.t()) :: map
  @callback get_transigo_doc_info :: String.t()

  def notify_api_users(result, event), do: impl().notify_api_users(result, event)

  def post_webhook_event(%User{webhook: nil}, _payload),
    do: impl().post_webhook_event(%User{webhook: nil}, _payload)

  def post_webhook_event(%User{webhook: webhook}, payload),
    do: impl().post_webhook_event(%User{webhook: webhook}, payload)

  def send_webhook_event(%User{id: user_id} = user, payload, %WebhookEvent{id: event_id}),
    do: impl().send_webhook_event(%User{id: user_id} = user, payload, %WebhookEvent{id: event_id})

  def cal_total_sum(transactions), do: impl().cal_total_sum(transactions)

  def move_transaction_to_state(%Transaction{} = transaction, state),
    do: impl().move_transaction_to_state(%Transaction{} = transaction, state)

  def put_datetime(result, %Transaction{transaction_state: "moved_to_payment"} = transaction),
    do:
      impl().put_datetime(
        result,
        %Transaction{transaction_state: "moved_to_payment"} = transaction
      )

  def put_datetime(result, %Transaction{transaction_state: "rev_share_to_be_paid"} = transaction),
    do:
      impl().put_datetime(
        result,
        %Transaction{transaction_state: "rev_share_to_be_paid"} = transaction
      )

  def get_transigo_doc_info(), do: impl().get_transigo_doc_info()

  defp impl, do: Application.get_env(:transigo_admin, __MODULE__)[:adapter]
end
