defmodule TransigoAdmin.Account.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "contact" do
    field :contact_transigo_uid, :string, source: :contact_transigoUID
    field :first_name, :string
    field :last_name, :string
    field :mobile, :string
    field :work_phone, :string
    field :email, :string
    field :role, :string
    field :country, :string, default: "US"
    field :ssn, :string
    field :address, :string
    field :date_of_birth, :date

    belongs_to :us_place, TransigoAdmin.Account.UsPlace, source: :personal_US_address_id

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @available_attrs [
    :contact_transigo_uid,
    :first_name,
    :last_name,
    :mobile,
    :work_phone,
    :email,
    :role,
    :country,
    :ssn,
    :address,
    :date_of_birth,
    :us_place_id
  ]

  @required_attrs [
    :contact_transigo_uid,
    :first_name,
    :last_name,
    :mobile,
    :work_phone,
    :email,
    :role,
    :country
  ]

  @doc false
  def changeset(attrs, contact \\ %__MODULE__{}) do
    contact
    |> cast(attrs, @available_attrs)
    |> validate_required(@required_attrs)
  end

  def update_changeset(attrs, contact \\ %__MODULE__{}) do
    contact
    |> cast(attrs, @available_attrs)
  end
end
