defmodule TransigoAdmin.Credit do
  import Ecto.Query, warn: false

  alias TransigoAdmin.Repo
  alias Absinthe.Relay

  alias TransigoAdmin.Credit.{Transaction, Quota, Marketplace, Offer}

  def list_transactions_due_in_3_days() do
    from(
      t in Transaction,
      where:
        fragment(
          "(? + make_interval(days => ?))::date = (NOW() + make_interval(days => 3))::date",
          t.invoice_date,
          t.credit_term_days
        ) and t.transaction_state == "assigned"
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
        ) and t.transaction_state in ["email_sent", "assigned"]
    )
    |> Repo.all()
  end

  def list_transactions_status_originated() do
    from(t in Transaction,
      where: t.transaction_state == "originated",
      preload: [:exporter, importer: [:contact]]
    )
    |> Repo.all()
  end

  def list_transactions_by_state(state) do
    from(t in Transaction, where: t.transaction_state == ^state)
    |> Repo.all()
  end

  def list_transactions_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"
    hs_status = "%#{Map.get(pagination_args, :hs_signing_status)}%"
    transaction_status = "%#{Map.get(pagination_args, :transaction_status)}%"

    from(t in Transaction,
      left_join: e in assoc(t, :exporter),
      left_join: i in assoc(t, :importer),
      where:
        (ilike(i.business_name, ^keyword) or ilike(e.business_name, ^keyword)) and
          ilike(t.hs_signing_status, ^hs_status) and
          ilike(t.transaction_state, ^transaction_status)
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
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
      where: i.id == ^importer_id and q.credit_status in ["granted", "partial"]
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

  def list_quotas_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"
    credit_status = "%#{Map.get(pagination_args, :credit_status)}%"

    from(q in Quota,
      left_join: i in assoc(q, :importer),
      where: ilike(i.business_name, ^keyword) and ilike(q.credit_status, ^credit_status)
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  def create_offer(attrs \\ %{}) do
    %Offer{}
    |> Offer.changeset(attrs)
    |> Repo.insert()
  end

  def list_offers_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"

    query =
      from(o in Offer,
        left_join: t in assoc(o, :transaction),
        left_join: e in assoc(t, :exporter),
        left_join: i in assoc(t, :importer),
        where: ilike(i.business_name, ^keyword) or ilike(e.business_name, ^keyword)
      )

    case check_accept_decline(Map.get(pagination_args, :accepted)) do
      nil ->
        query

      accept_decline ->
        query
        |> where([o], ilike(o.offer_accepted_declined, ^accept_decline))
    end
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  defp check_accept_decline(nil), do: nil

  defp check_accept_decline(true), do: "A"

  defp check_accept_decline(false), do: "D"

  def datasource, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(queryable, _), do: queryable
end
