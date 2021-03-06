defmodule TransigoAdmin.Credit.Offer do
  use Ecto.Schema
  import Ecto.Changeset

  alias TransigoAdmin.Credit.Transaction

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "offer" do
    belongs_to :transaction, Transaction
    field :transaction_usd, :float, source: :transaction_USD
    field :advance_percentage, :float
    field :advance_usd, :float, source: :advance_USD
    field :importer_fee, :float
    field :offer_accepted_declined, :string
    field :offer_accept_decline_datetime, :utc_datetime

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @doc false
  def changeset(offer, attrs) do
    offer
    |> cast(attrs, [
      :transaction_id,
      :transaction_usd,
      :advance_percentage,
      :advance_usd,
      :importer_fee,
      :offer_accepted_declined,
      :offer_accept_decline_datetime
    ])
    |> validate_required([
      :transaction_id,
      :transaction_usd,
      :advance_percentage,
      :advance_usd,
      :importer_fee
    ])
  end

  def create_with_transaction_changeset(offer, attrs) do
    offer
    |> cast(attrs, [
      :transaction_usd,
      :advance_percentage,
      :advance_usd,
      :importer_fee,
      :offer_accepted_declined,
      :offer_accept_decline_datetime
    ])
    |> validate_required([
      :transaction_usd,
      :advance_percentage,
      :advance_usd,
      :importer_fee
    ])
    |> cast_assoc(:transaction, with: &Transaction.changeset/2, required: true)
  end
end
