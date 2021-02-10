defmodule TransigoAdmin.Credit.Marketplace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "marketplaces" do
    field :origin, :string
    field :marketplace, :string

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @doc false
  def changeset(marketplace, attrs) do
    marketplace
    |> cast(attrs, [:origin, :marketplace])
    |> validate_required([:origin, :marketplace])
  end
end
