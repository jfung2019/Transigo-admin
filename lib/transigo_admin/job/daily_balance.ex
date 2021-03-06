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

  require Logger

  use Oban.Worker, queue: :transaction, max_attempts: 1

  alias TransigoAdmin.{
    Credit.Offer,
    Credit.Quota,
    Credit.Transaction,
    Job.HelperApi,
    Credit,
    Account.Importer,
    Account.Exporter,
    Repo
  }

  alias Decimal

  alias TransigoAdmin.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    do_daily_balance()
    :ok
  end

  def do_daily_balance() do
    transactions = get_daily_balance_transactions()

    send_report_result = transactions |> create_and_send_report()

    Logger.info("The send_report_result is: is -> #{send_report_result}")

    # if email_state return :ok , do notify_webhook, else return :error, break  
    case send_report_result do
      :ok -> transactions |> notify_webhook()
      {:error, _} -> send_report_result
    end
  end

  def create_and_send_report(transactions) do
    transactions
    |> Repo.preload([:exporter, importer: :quota])
    |> create_report()
    |> HelperApi.send_report()
  end

  def notify_webhook(transactions) do
    transactions
    |> Enum.map(&HelperApi.move_transaction_to_state(&1, :moved_to_payment))
    |> Enum.reject(&is_nil/1)
    |> format_webhook_result()
    |> HelperApi.notify_api_users("daily_balance")
  end

  def get_daily_balance_transactions() do
    load_all_acceptance_offer()
    |> Enum.map(&check_offer_transaction_state(&1, :down_payment_done))
    |> Enum.filter(fn
      %_{} = t -> t.hs_signing_status == :all_signed
      _ -> false
    end)
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
  List all the transaction with transaction_state == :down_payment_done
  """
  def check_offer_transaction_state(
        %Offer{transaction: %{transaction_state: state} = transaction},
        state
      ),
      do: transaction

  def check_offer_transaction_state(_offer, _state), do: nil

  def create_report(transactions) do
    rows =
      transactions
      |> Enum.map(&create_report_row/1)

    [
      [
        "Date",
        "Transaction_uid",
        "Importer_uid",
        "Exporter_uid",
        "Factoring_price",
        "Total_open_factoring_price",
        "Quota_usd",
        "Signed_docs",
        "Credit_insurance_number"
      ]
      | rows
    ]
    |> CSV.encode()
  end

  def create_report_row(%Transaction{
        importer_id: importer_id,
        transaction_uid: transaction_uid,
        financed_sum: financed_sum,
        hs_signing_status: hs_signing_status,
        importer: %Importer{
          importer_transigo_uid: importer_transigo_uid,
          quota: %Quota{
            quota_usd: quota_usd,
            eh_grade: eh_grade
          }
        },
        exporter: %Exporter{
          exporter_transigo_uid: exporter_transigo_uid
        }
      }) do
    [
      Timex.today(),
      transaction_uid,
      importer_transigo_uid,
      exporter_transigo_uid,
      financed_sum |> Decimal.from_float() |> Decimal.to_string(:normal),
      Credit.get_total_open_factoring_price(importer_id)
      |> Decimal.from_float()
      |> Decimal.to_string(:normal),
      quota_usd |> Decimal.from_float() |> Decimal.to_string(:normal),
      hs_signing_status,
      unless(is_nil(eh_grade), do: eh_grade["policy"]["policyId"], else: nil)
    ]
  end
end
