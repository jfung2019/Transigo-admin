defmodule TransigoAdmin.Credit.Offer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  schema "offer" do
    belongs_to :transaction, TransigoAdmin.Credit.Transaction
    field :transaction_USD, :decimal
    field :advance_percentage, :decimal
    field :advance_USD, :decimal
    field :importer_fee, :decimal
    field :offer_accepted_declined, :string
  end

  @doc false
  def changeset(offer, attrs) do
    offer
    |> cast(attrs, [
      :transaction_id,
      :transaction_USD,
      :advance_percentage,
      :advance_USD,
      :importer_fee,
      :offer_accepted_declined
    ])
    |> validate_required([
      :transaction_id,
      :transaction_USD,
      :advance_percentage,
      :advance_USD,
      :importer_fee,
      :offer_accepted_declined
    ])
  end
end
