defmodule TransigoAdmin.Account.Importer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  schema "importer" do
    field :importer_transigoUID, :string
    field :business_name, :string
    field :business_address_street_address, :string
    field :business_address_city, :string
    field :business_address_state, :string
    field :business_address_zip, :string
    field :business_address_country, :string
  end

  @doc false
  def changeset(importer, attrs) do
    importer
    |> cast(attrs, [
      :importer_transigoUID,
      :business_name,
      :business_address_street_address,
      :business_address_city,
      :business_address_state,
      :business_address_zip,
      :business_address_country
    ])
    |> validate_required([
      :importer_transigoUID,
      :business_name,
      :business_address_street_address,
      :business_address_city,
      :business_address_state,
      :business_address_zip,
      :business_address_country
    ])
  end
end
