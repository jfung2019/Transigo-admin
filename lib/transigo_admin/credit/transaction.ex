defmodule TransigoAdmin.Credit.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  schema "transaction" do
    field :transaction_UID, :string
    field :credit_term_days, :integer
    field :financier, :string
    field :down_payment_USD, :decimal
    field :factoring_fee_USD, :decimal
    field :transaction_state, :string
    field :financed_sum, :decimal
    field :invoice_date, :date
    field :hellosign_signature_request_id, :string
    field :hs_signing_status, :string, default: "awaiting_signature"
    field :second_installment_USD, :decimal
    field :repaid_datetime, :utc_datetime
    field :dwolla_repayment_transfer_url, :string

    belongs_to :importer, TransigoAdmin.Account.Importer
    belongs_to :exporter, TransigoAdmin.Account.Exporter

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @available_attrs [
    :transaction_UID,
    :importer_id,
    :exporter_id,
    :credit_term_days,
    :down_payment_USD,
    :factoring_fee_USD,
    :financed_sum,
    :hellosign_signature_request_id,
    :hs_signing_status,
    :second_installment_USD,
    :transaction_state,
    :invoice_date,
    :dwolla_repayment_transfer_url
  ]

  @required_attrs [
    :transaction_UID,
    :importer_id,
    :exporter_id,
    :credit_term_days,
    :down_payment_USD,
    :factoring_fee_USD,
    :financed_sum,
    :hs_signing_status,
    :transaction_state
  ]

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, @available_attrs)
    |> validate_required(@required_attrs)
  end
end
