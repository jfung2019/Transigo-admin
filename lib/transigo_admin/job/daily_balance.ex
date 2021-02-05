defmodule TransigoAdmin.Job.DailyBalance do
  use Oban.Worker, queue: :default

  alias TransigoAdmin.{Credit, Job.Helper}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Credit.list_transactions_by_state("down_payment_done")
    |> Enum.map(&Helper.move_transaction_to_state(&1, "moved_to_payment"))
    |> Enum.reject(&is_nil(&1))
    |> format_webhook_result()
    |> Helper.notify_api_users("daily_balance")
  end

  def format_webhook_result(transactions) do
    total = Helper.cal_total_sum(transactions)

    %{
      totalRemitSum: total.sum,
      dailyTransaction: transactions
    }
  end
end