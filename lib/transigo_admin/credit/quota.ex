defmodule TransigoAdmin.Credit.Quota do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "quota" do
    field :quota_transigo_uid, :string, source: :quota_transigoUID
    field :quota_usd, :float, source: :quota_USD
    field :credit_days_quota, :integer
    field :credit_request_date, :date
    field :token, :string
    field :marketplace_transactions, :integer

    field :marketplace_total_transaction_sum_usd, :float,
      source: :marketplace_total_transaction_sum_USD

    field :marketplace_transactions_last_12_months, :integer

    field :marketplace_total_transaction_sum_usd_last_12_months, :float,
      source: :marketplace_total_transaction_sum_USD_last_12_months

    field :marketplace_number_disputes, :integer
    field :marketplace_number_adverse_disputes, :integer
    field :credit_status, :string, source: :creditStatus
    field :funding_source_url, :string
    field :credit_terms, :string, default: "open_account"
    field :plaid_underwriting_result, :float
    field :eh_grade, :map
    field :eh_grade_job_url, :string
    field :plaid_form_result, :map

    belongs_to :importer, TransigoAdmin.Account.Importer

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @available_attrs [
    :quota_transigo_uid,
    :quota_usd,
    :credit_days_quota,
    :credit_request_date,
    :token,
    :marketplace_transactions,
    :marketplace_total_transaction_sum_usd,
    :marketplace_transactions_last_12_months,
    :marketplace_total_transaction_sum_usd_last_12_months,
    :marketplace_number_disputes,
    :marketplace_number_adverse_disputes,
    :credit_status,
    :funding_source_url,
    :credit_terms,
    :plaid_underwriting_result,
    :eh_grade,
    :eh_grade_job_url,
    :plaid_form_result,
    :importer_id
  ]

  @required_attrs [
    :quota_transigo_uid,
    :quota_USD,
    :credit_request_date,
    :token,
    :marketplace_transactions,
    :marketplace_total_transaction_sum_usd,
    :marketplace_transactions_last_12_months,
    :marketplace_total_transaction_sum_usd_last_12_months,
    :marketplace_number_disputes,
    :marketplace_number_adverse_disputes,
    :credit_status,
    :funding_source_url,
    :credit_terms,
    :importer_id
  ]

  @doc false
  def changeset(quota, attrs) do
    quota
    |> cast(attrs, @available_attrs)
    |> validate_required(@required_attrs)
  end
end
