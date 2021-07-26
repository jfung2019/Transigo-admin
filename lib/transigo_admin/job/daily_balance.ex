defmodule TransigoAdmin.Job.DailyBalance do
  @moduledoc """
  list transaction with state down_payment_done and update those to moved_to_payment
  send the sum and transaction uids that are updated to registered webhook users
  """
  use Oban.Worker, queue: :transaction, max_attempts: 1

  alias TransigoAdmin.{Credit, Job.Helper}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Credit.list_transactions_by_state("down_payment_done")
    |> Enum.map(&Helper.move_transaction_to_state(&1, "moved_to_payment"))
    |> Enum.reject(&is_nil(&1))
    |> format_webhook_result()
    |> Helper.notify_api_users("daily_balance")

    :ok
  end

  def format_webhook_result(transactions) do
    total = Helper.cal_total_sum(transactions)

    %{
      totalRemitSum: total.sum,
      dailyTransactions: transactions
    }
  end
end
