defmodule TransigoAdmin.Account.Importer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "importer" do
    field :importer_transigoUID, :string
    field :business_name, :string
    field :business_EIN, :string
    field :incorporation_date, :date
    field :importer_origin, :string, default: "DH"
    field :number_DUNS, :string
    field :business_address_street_address, :string
    field :business_address_city, :string
    field :business_address_state, :string
    field :business_address_zip, :string
    field :business_address_country, :string

    field :business_type, Ecto.Enum,
      values: [:soleProprietorship, :corporation, :llc, :partnership]

    field :business_classification_id, :string

    belongs_to :contact, TransigoAdmin.Account.Contact

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @available_attrs [
    :importer_transigoUID,
    :business_name,
    :business_EIN,
    :incorporation_date,
    :importer_origin,
    :number_DUNS,
    :business_address_street_address,
    :business_address_city,
    :business_address_state,
    :business_address_zip,
    :business_address_country,
    :business_type,
    :business_classification_id,
    :contact_id
  ]

  @required_attrs [
    :importer_transigoUID,
    :business_name,
    :business_EIN,
    :incorporation_date,
    :importer_origin,
    :number_DUNS,
    :business_address_street_address,
    :business_address_city,
    :business_address_state,
    :business_address_zip,
    :business_address_country,
    :business_type,
    :business_classification_id
  ]

  @doc false
  def changeset(importer, attrs) do
    importer
    |> cast(attrs, @available_attrs)
    |> validate_required(@required_attrs)
  end
end
