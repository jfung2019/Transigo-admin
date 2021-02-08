defmodule TransigoAdmin.Account.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "contact" do
    field :contact_transigoUID, :string
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

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @available_attrs [
    :contact_transigoUID,
    :first_name,
    :last_name,
    :mobile,
    :work_phone,
    :email,
    :role,
    :country,
    :ssn,
    :address,
    :date_of_birth
  ]

  @required_attrs [
    :contact_transigoUID,
    :first_name,
    :last_name,
    :mobile,
    :work_phone,
    :email,
    :role,
    :country
  ]

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, @available_attrs)
    |> validate_required(@required_attrs)
  end
end
