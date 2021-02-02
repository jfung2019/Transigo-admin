defmodule TransigoAdmin.Job.Helper do
  alias TransigoAdmin.{Account, Account.User}

  def notify_api_users(result, event) do
    Account.list_users_with_webhook()
    |> Enum.each(&post_webhook_event(&1, event, result))
  end

  defp post_webhook_event(%User{webhook: webhook}, event, result) do
    payload =
      %{
        event: event,
        result: result
      }
      |> Jason.encode!()

    HTTPoison.post(webhook, payload, [{"Content-Type", "application/json"}])
  end
end
