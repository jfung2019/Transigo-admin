defmodule TransigoAdmin.Job.DailyBalance do
  @moduledoc """
  list transaction with state down_payment_done and update those to moved_to_payment
  send the sum and transaction uids that are updated to registered webhook users

  check if the transaction satisfy all the conditions:
  1.Importer has accepted the offer, and
  2.Importer has signed documents, and
  3.Importer has remitted the downpayment to marketplace, and
  4.Exporter has signed documents, and
  5.Transigo has signed documents

  """
  import Ecto.Query, warn: false

  use Oban.Worker, queue: :transaction, max_attempts: 1

  alias TransigoAdmin.{Credit.Offer, Job.HelperApi}

  alias TransigoAdmin.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    do_daily_balance()
    :ok
  end

  def do_daily_balance() do
    load_all_acceptance_offer()
    |> Enum.map(&check_offer_transaction_state(&1, "down_payment_done"))
    |> Enum.filter(fn t -> t.hs_signing_status == "all_signed" end)
    |> Enum.map(&HelperApi.move_transaction_to_state(&1, "moved_to_payment"))
    |> Enum.reject(&is_nil(&1))
    |> format_webhook_result()
    |> HelperApi.notify_api_users("daily_balance")
  end

  def format_webhook_result(transactions) do
    total = HelperApi.cal_total_sum(transactions)

    %{
      totalRemitSum: total.sum,
      dailyTransactions: transactions
    }
  end

  @doc """
  List all the offer with offer_accepted_declined == "A"
  and preload that offer with transaction
  """
  def load_all_acceptance_offer() do
    from(
      o in Offer,
      where: o.offer_accepted_declined == "A",
      preload: [:transaction]
    )
    |> Repo.all()
  end

  @doc """
  List all the transaction with transaction_state == "down_payment_done"
  """

  def check_offer_transaction_state(nil, _state), do: {:error, "No acceptance offer found"}

  def check_offer_transaction_state(
        %Offer{transaction: %{transaction_state: state} = transaction},
        state
      ),
      do: transaction

  def check_offer_transaction_state(_offer, _state), do: nil
end
