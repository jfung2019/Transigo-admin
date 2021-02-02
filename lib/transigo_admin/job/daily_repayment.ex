defmodule TransigoAdmin.Job.DailyRepayment do
  use Oban.Worker, queue: :default

  import Ecto.Query, warn: false

  alias TransigoAdmin.{Credit, Credit.Transaction, Job.Helper}
  alias SendGrid.{Mail, Email}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # notify customers of the dwolla pull
    Credit.list_transactions_due_in_3_days()
    |> Enum.each(&send_transaction_due_email(&1))

    # create transfer from customer to Transigo
    Credit.list_transactions_due_today()
    |> Enum.each(&create_dwolla_transfer(&1))

    # check transfer status
    Credit.list_transactions_with_repaid_pulled()
    |> Enum.map(&check_transaction_dwolla_status(&1))
    |> Enum.reject(&is_nil(&1))
    |> Helper.notify_api_users("daily_repayment")
  end

  defp send_transaction_due_email(%Transaction{} = transaction) do
    contact = TransigoAdmin.Account.get_contact_by_importer(transaction.importer_id)

    repaid_amount =
      transaction.second_installment_USD
      |> Decimal.round(2)
      |> Decimal.to_string()

    message =
      "You have a transaction due in 3 days. Please have #{repaid_amount} ready in your dwolla account."

    Email.build()
    |> Email.put_from("tcaas@transigo.io", "Transigo")
    |> Email.add_to(contact.email)
    |> Email.put_subject("Transaction Dues in 3 days")
    |> Email.put_text(message)
    |> Mail.send()

    transaction
    |> Credit.update_transaction(%{transaction_state: "email_sent"})
  end

  defp create_dwolla_transfer(%Transaction{}) do
  end

  defp check_transaction_dwolla_status(%Transaction{}) do
  end
end
