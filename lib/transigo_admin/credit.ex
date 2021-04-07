defmodule TransigoAdmin.Credit do
  import Ecto.Query, warn: false

  alias TransigoAdmin.Repo
  alias TransigoAdmin.Credit.{Transaction, Quota, Marketplace}

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
    from(t in Transaction,
      where:
        fragment(
          "(? + make_interval(days => ?))::date <= NOW()::date",
          t.invoice_date,
          t.credit_term_days
        ) and t.transaction_state in ["email_sent", "originated"]
    )
    |> Repo.all()
  end

  def list_transactions_by_state(state) do
    from(t in Transaction, where: t.transaction_state == ^state)
    |> Repo.all()
  end

  def get_transaction!(id), do: Repo.get!(Transaction, id)

  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def update_transaction(transaction, attrs \\ %{}) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  def create_quota(attrs \\ %{}) do
    %Quota{}
    |> Quota.changeset(attrs)
    |> Repo.insert()
  end

  def get_quota!(id), do: Repo.get!(Importer, id)

  def find_granted_quota(importer_id) do
    from(q in Quota,
      left_join: i in assoc(q, :importer),
      where: i.id == ^importer_id and q.creditStatus in ["granted", "partial"]
    )
    |> Repo.one()
  end

  def create_marketplace(attrs \\ %{}) do
    %Marketplace{}
    |> Marketplace.changeset(attrs)
    |> Repo.insert()
  end

  def update_quota(quota, attrs \\ %{}) do
    quota
    |> Quota.changeset(attrs)
    |> Repo.update()
  end

  def delete_quota(%Quota{} = quota), do: Repo.delete(quota)

  def list_quota_with_pending_eh_job() do
    from(q in Quota,
      where: not is_nil(q.eh_grade_job_url) and is_nil(q.eh_grade)
    )
    |> Repo.all()
  end

  def list_quota_with_eh_cover() do
    from(q in Quota, where: not is_nil(q.eh_cover))
    |> Repo.all()
  end
end
