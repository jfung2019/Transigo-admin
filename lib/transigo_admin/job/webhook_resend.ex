defmodule TransigoAdmin.Job.WebhookResend do
  use Oban.Worker, queue: :webhook, max_attempts: 5

  alias TransigoAdmin.{Account, Account.WebhookUserEvent, Job.Helper}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{state: state}}) do
    Account.list_webhook_user_event_by_state(state)
    |> Enum.each(&resend_event(&1))

    :ok
  end

  defp resend_event(%WebhookUserEvent{retry_number: retries} = user_event) do
    payload =
      %{
        event: user_event.webhook_event.event,
        result: user_event.webhook_event.result,
        metadata: %{
          currentDateTime: Timex.now(),
          originalDateTime: user_event.inserted_at,
          retryNumber: retries + 1
        }
      }
      |> Jason.encode!()

    case Helper.post_webhook_event(user_event.user, payload) do
      {:ok, %{status_code: 200}} ->
        Account.update_webhook_user_event(user_event, %{
          state: "success",
          retry_number: retries + 1
        })

      {:error, _} ->
        resend_later(user_event)
    end
  end

  defp resend_later(%WebhookUserEvent{state: "init_send_fail", retry_number: 4} = user_event) do
    Account.update_webhook_user_event(user_event, %{
      state: "first_resend_fail",
      retry_number: 5
    })
  end

  defp resend_later(%WebhookUserEvent{state: "first_resend_fail", retry_number: 9} = user_event) do
    Account.update_webhook_user_event(user_event, %{
      state: "second_resend_fail",
      retry_number: 10
    })
  end

  defp resend_later(%WebhookUserEvent{state: "second_resend_fail", retry_number: 12} = user_event) do
    Account.update_webhook_user_event(user_event, %{
      state: "all_attempts_failed",
      retry_number: 13
    })
  end

  defp resend_later(%WebhookUserEvent{retry_number: retries} = user_event),
    do: Account.update_webhook_user_event(user_event, %{retry_number: retries + 1})
end
