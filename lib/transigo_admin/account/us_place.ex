defmodule TransigoAdmin.Account.UsPlace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "US_place" do
    field :street_address, :string
    field :city, :string
    field :state, :string
    field :zip_code, :string
    field :country, :string
    field :full_address, :string
    field :google_place_id, :string
    field :latitude, :float
    field :longitude, :float
    field :google_json, :string

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @available_attrs [
    :street_address,
    :city,
    :state,
    :zip_code,
    :country,
    :full_address,
    :google_place_id,
    :latitude,
    :longitude,
    :google_json
  ]

  @required_attrs [
    :street_address,
    :city,
    :state,
    :zip_code,
    :country,
    :full_address,
    :google_place_id,
    :latitude,
    :longitude,
    :google_json
  ]

  @doc false
  def changeset(us_place, attrs) do
    us_place
    |> cast(attrs, @available_attrs)
    |> validate_required(@required_attrs)
  end
end
