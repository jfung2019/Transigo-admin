defmodule TransigoAdmin.Credit.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  schema "transaction" do
    field :transaction_UID, :string
    field :credit_term_days, :integer
    field :financier, :string, default: "Churchill"
    field :down_payment_USD, :float
    field :down_payment_confirmed_datetime, :utc_datetime
    field :factoring_fee_USD, :float
    field :transaction_state, :string, default: "xxx"
    field :financed_sum, :float
    field :invoice_date, :date
    field :invoice_ref, :string
    field :po_date, :date
    field :po_ref, :string
    field :hellosign_signature_request_id, :string
    field :hs_signing_status, :string, default: "awaiting_signature"
    field :second_installment_USD, :float
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
    :credit_term_days,
    :down_payment_USD,
    :down_payment_confirmed_datetime,
    :factoring_fee_USD,
    :transaction_state,
    :financed_sum,
    :invoice_date,
    :invoice_ref,
    :po_date,
    :po_ref,
    :hellosign_signature_request_id,
    :hs_signing_status,
    :second_installment_USD,
    :repaid_datetime,
    :dwolla_repayment_transfer_url,
    :importer_id,
    :exporter_id
  ]

  @required_attrs [
    :transaction_UID,
    :credit_term_days,
    :down_payment_USD,
    :factoring_fee_USD,
    :transaction_state,
    :financed_sum,
    :hs_signing_status,
    :second_installment_USD,
    :importer_id,
    :exporter_id
  ]

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, @available_attrs)
    |> validate_required(@required_attrs)
  end
end
