defmodule TransigoAdmin.Credit.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "transaction" do
    field :transaction_uid, :string, source: :transaction_UID
    field :credit_term_days, :integer
    field :financier, :string, default: "Churchill"
    field :down_payment_usd, :float, source: :down_payment_USD
    field :downpayment_confirm, :string
    field :down_payment_confirmed_datetime, :utc_datetime
    field :factoring_fee_usd, :float, source: :factoring_fee_USD

    field :transaction_state, Ecto.Enum,
      values: [
        :created,
        :down_payment_done,
        :moved_to_payment,
        :originated,
        :assigned,
        :email_sent,
        :pull_initiated,
        :repaid,
        :rev_share_to_be_paid,
        :rev_share_paid,
        :disputed,
        :assignment_awaiting,
        :assignment_signed
      ],
      default: :created

    field :financed_sum, :float
    field :invoice_date, :date
    field :invoice_ref, :string
    field :po_date, :date
    field :po_ref, :string
    field :hellosign_signature_request_id, :string

    field :hs_signing_status, Ecto.Enum,
      values: [
        :awaiting_signature,
        :all_signed,
        :exporter_signed,
        :importer_signed,
        :transigo_signed,
        :missing_exporter,
        :missing_importer,
        :missing_transigo
      ],
      default: :awaiting_signature

    field :second_installment_usd, :float, source: :second_installment_USD
    field :repaid_datetime, :utc_datetime
    field :dwolla_repayment_transfer_url, :string
    field :hellosign_assignment_signature_request_id, :string

    belongs_to :importer, TransigoAdmin.Account.Importer
    belongs_to :exporter, TransigoAdmin.Account.Exporter

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @available_attrs [
    :transaction_uid,
    :credit_term_days,
    :down_payment_usd,
    :downpayment_confirm,
    :down_payment_confirmed_datetime,
    :factoring_fee_usd,
    :transaction_state,
    :financed_sum,
    :invoice_date,
    :invoice_ref,
    :po_date,
    :po_ref,
    :hellosign_signature_request_id,
    :hs_signing_status,
    :second_installment_usd,
    :repaid_datetime,
    :dwolla_repayment_transfer_url,
    :importer_id,
    :exporter_id,
    :hellosign_assignment_signature_request_id
  ]

  @required_attrs [
    :transaction_uid,
    :credit_term_days,
    :down_payment_usd,
    :factoring_fee_usd,
    :transaction_state,
    :financed_sum,
    :hs_signing_status,
    :second_installment_usd,
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
