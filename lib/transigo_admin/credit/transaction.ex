defmodule TransigoAdmin.Credit.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  schema "transaction" do
    field :transaction_UID, :string
    belongs_to :importer, TransigoAdmin.Account.Importer
    belongs_to :exporter, TransigoAdmin.Account.Exporter
    field :credit_term_days, :integer
    field :down_payment_USD, :decimal
    field :factoring_fee_USD, :decimal
    field :financed_sum, :decimal
    field :hellosign_signature_request_id, :string
    field :hs_signing_status, :string
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :transaction_UID,
      :importer_id,
      :exporter_id,
      :credit_term_days,
      :down_payment_USD,
      :factoring_fee_USD,
      :financed_sum,
      :hellosign_signature_request_id,
      :hs_signing_status
    ])
    |> validate_required([
      :transaction_UID,
      :importer_id,
      :exporter_id,
      :credit_term_days,
      :down_payment_USD,
      :factoring_fee_USD,
      :financed_sum,
      :hellosign_signature_request_id,
      :hs_signing_status
    ])
  end
end
