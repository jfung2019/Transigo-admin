defmodule TransigoAdmin.Job.MonthlyRevShare do
  use Oban.Worker, queue: :default

  alias TransigoAdmin.{Credit, Job.Helper}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Credit.list_transactions_by_state("repaid")
    |> Enum.map(&Helper.move_transaction_to_state(&1, "rev_share_to_be_paid"))
    |> Enum.reject(&is_nil(&1))
    |> format_webhook_result()
    |> Helper.notify_api_users("monthly_rev_share")
  end

  def format_webhook_result(transactions) do
    total = Helper.cal_total_sum(transactions)

    %{
      totalRemitSum: total.sum,
      monthlyTransaction: transactions
    }
  end
end
