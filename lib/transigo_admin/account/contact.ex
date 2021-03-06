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
    field :consumer_credit_score, :integer
    field :consumer_credit_score_percentile, :integer
    field :consumer_credit_report_meridianlink, :string

    has_one :importer, TransigoAdmin.Account.Importer

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
    :us_place_id,
    :consumer_credit_score,
    :consumer_credit_score_percentile,
    :consumer_credit_report_meridianlink
  ]

  @update_attrs [
    :first_name,
    :last_name,
    :mobile,
    :work_phone,
    :email,
    :role
  ]

  @consumer_credit_attrs [
    :consumer_credit_score,
    :consumer_credit_score_percentile,
    :consumer_credit_report_meridianlink
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
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, @available_attrs)
    |> validate_required(@required_attrs)
  end

  def consumer_credit_changeset(contact, attrs) do
    contact
    |> cast(attrs, @consumer_credit_attrs)
  end

  def update_changeset(contact, attrs) do
    contact
    |> cast(attrs, @update_attrs)
  end
end
