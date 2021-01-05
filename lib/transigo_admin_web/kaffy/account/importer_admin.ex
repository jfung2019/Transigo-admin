defmodule TransigoAdmin.Account.ImporterAdmin do
  def index(_) do
    [
      importer_transigoUID: nil,
      business_name: nil,
      business_address_street_address: nil,
      business_address_city: nil,
      business_address_state: nil,
      business_address_zip: nil,
      business_address_country: nil
    ]
  end

  def form_fields(_) do
    [
      importer_transigoUID: nil,
      business_name: nil,
      business_address_street_address: nil,
      business_address_city: nil,
      business_address_state: nil,
      business_address_zip: nil,
      business_address_country: nil
    ]
  end
end
