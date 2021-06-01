defmodule TransigoAdmin.Account.Exporter do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "exporter" do
    field :exporter_transigo_uid, :string, source: :exporter_transigoUID
    field :business_name, :string
    field :address, :string
    field :business_address_country, :string
    field :registration_number, :string
    field :signatory_first_name, :string
    field :signatory_last_name, :string
    field :signatory_mobile, :string
    field :signatory_email, :string
    field :signatory_title, :string
    field :hellosign_signature_request_id, :string
    field :hs_signing_status, :string, default: "awaiting_signature"
    field :sign_msa_datetime, :date, source: :sign_MSA_datetime

    belongs_to :contact, TransigoAdmin.Account.Contact, source: :MSA_contact_id
    belongs_to :marketplace, TransigoAdmin.Credit.Marketplace

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @available_attrs [
    :exporter_transigo_uid,
    :business_name,
    :address,
    :business_address_country,
    :registration_number,
    :signatory_first_name,
    :signatory_last_name,
    :signatory_mobile,
    :signatory_email,
    :signatory_title,
    :hellosign_signature_request_id,
    :hs_signing_status,
    :marketplace_id,
    :contact_id
  ]

  @required_attrs [
    :exporter_transigo_uid,
    :business_name,
    :address,
    :business_address_country,
    :registration_number,
    :signatory_first_name,
    :signatory_last_name,
    :signatory_mobile,
    :signatory_email,
    :signatory_title,
    :hs_signing_status,
    :marketplace_id
  ]

  @doc false
  def changeset(exporter, attrs) do
    exporter
    |> cast(attrs, @available_attrs)
    |> validate_required(@required_attrs)
  end
end
