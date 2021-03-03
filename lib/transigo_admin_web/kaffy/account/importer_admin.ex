defmodule TransigoAdmin.Account.ImporterAdmin do
  def index(_) do
    [
      importer_transigoUID: nil,
      business_name: nil,
      business_EIN: nil,
      incorporation_date: nil,
      importer_origin: nil,
      number_DUNS: nil,
      business_address_street_address: nil,
      business_address_city: nil,
      business_address_state: nil,
      business_address_zip: nil,
      business_address_country: nil,
      business_type: nil,
      business_classification_id: nil,
      inserted_at: %{name: "created datetime"},
      updated_at: %{name: "last modified datetime"}
    ]
  end

  def form_fields(_) do
    [
      importer_transigoUID: nil,
      business_name: nil,
      business_EIN: nil,
      incorporation_date: nil,
      importer_origin: nil,
      number_DUNS: nil,
      business_address_street_address: nil,
      business_address_city: nil,
      business_address_state: nil,
      business_address_zip: nil,
      business_address_country: nil,
      business_type: nil,
      business_classification_id: nil,
      inserted_at: %{name: "created datetime"},
      updated_at: %{name: "last modified datetime"}
    ]
  end
end
