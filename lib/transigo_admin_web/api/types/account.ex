defmodule TransigoAdminWeb.Api.Types.Account do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias TransigoAdmin.Account

  object :admin_session do
    field :admin, non_null(:admin)
    field :token, non_null(:string)
  end

  object :admin do
    field :id, non_null(:id)
    field :firstname, non_null(:string)
    field :lastname, non_null(:string)
    field :email, non_null(:string)
    field :username, non_null(:string)
    field :title, non_null(:string)
  end

  object :exporter do
    field :id, non_null(:id)
    field :exporter_transigo_uid, non_null(:string)
    field :business_name, non_null(:string)
    field :address, non_null(:string)
    field :business_address_country, non_null(:string)
    field :registration_number, :string
    field :signatory_first_name, non_null(:string)
    field :signatory_last_name, non_null(:string)
    field :signatory_mobile, non_null(:string)
    field :signatory_email, non_null(:string)
    field :signatory_title, non_null(:string)
    field :hellosign_signature_request_id, :string
    field :hs_signing_status, non_null(:hs_signing_status)
    field :contact, non_null(:contact), resolve: dataloader(Account)
  end

  connection(node_type: :exporter)

  enum :business_type do
    value :soleProprietorship
    value :corporation
    value :llc
    value :partnership
  end

  object :importer do
    field :id, non_null(:id)
    field :importer_transigo_uid, non_null(:string)
    field :business_name, non_null(:string)
    field :business_ein, non_null(:string)
    field :incorporation_date, non_null(:date)
    field :importer_origin, non_null(:string)
    field :number_duns, non_null(:string)
    field :business_address_street_address, non_null(:string)
    field :business_address_city, non_null(:string)
    field :business_address_state, non_null(:string)
    field :business_address_zip, non_null(:string)
    field :business_address_country, non_null(:string)
    field :business_type, non_null(:business_type)
    field :business_classification_id, non_null(:string)
    field :contact, non_null(:contact), resolve: dataloader(Account)
  end

  connection(node_type: :importer)

  object :contact do
    field :id, non_null(:id)
    field :contact_transigo_uid, non_null(:string)
    field :first_name, non_null(:string)
    field :last_name, non_null(:string)
    field :mobile, non_null(:string)
    field :work_phone, non_null(:string)
    field :email, non_null(:string)
    field :role, non_null(:string)
    field :country, non_null(:string)
    field :ssn, :string
    field :address, :string
    field :date_of_birth, :date
  end

  object :document_result do
    field :url, non_null(:id)
  end
end
