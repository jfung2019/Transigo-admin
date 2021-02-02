defmodule TransigoAdmin.Credit do
  import Ecto.Query, warn: false

  alias TransigoAdmin.Repo
  alias TransigoAdmin.Credit.Transaction

  def list_transactions_due_in_3_days() do
    from(
      t in Transaction,
      where:
        fragment(
          "(? + make_interval(days => ?))::date = (NOW() + make_interval(days => 3))::date",
          t.invoice_date,
          t.credit_term_days
        ) and t.transaction_state == "originated"
    )
    |> Repo.all()
  end

  def list_transactions_due_today() do
    from(
      t in Transaction,
      where:
        fragment(
          "(? + make_interval(days => ?))::date = NOW()::date",
          t.invoice_date,
          t.credit_term_days
        ) and t.transaction_state in ["email_sent", "originated"]
    )
    |> Repo.all()
  end

  def list_transactions_with_repaid_pulled() do
    from(t in Transaction, where: t.transaction_state == "pull_initiated")
    |> Repo.all()
  end

  def update_transaction(transaction, attrs \\ %{}) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end
end
