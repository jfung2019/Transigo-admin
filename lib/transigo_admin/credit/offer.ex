defmodule TransigoAdmin.Credit.Offer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  schema "offer" do
  end

  @doc false
  def changeset(offer, attrs) do
    offer
    |> cast(attrs, [])
    |> validate_required([])
  end
end
