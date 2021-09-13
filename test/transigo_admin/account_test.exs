defmodule TransigoAdmin.AccountTest do
  use TransigoAdmin.DataCase, async: true

  alias TransigoAdmin.Account
  alias TransigoAdmin.Account.Contact
  alias TransigoAdmin.Account.Exporter
  alias TransigoAdmin.Credit

  @valid_exporter_params %{
         "businessName" => "Best Business",
         "address" => "Folsom St.",
         "buisinessAddressCountry" => "USA",
         "registrationNumber" => "123456",
         "signatoryFirstName" => "David",
         "signatoryLastName" => "Silva",
         "signatoryMobile" => "7077321415",
         "signatoryEmail" => "david@bbiz.com",
         "signatoryTitle" => "Founder",
         "contactFirstName" => "Elliot",
         "contactLastName" => "Winden",
         "contactMobile" => "7071749274",
         "workPhone" => "7075023748",
         "contactEmail" => "elliot@bbiz.com",
         "contactTitle" => "President",
         "contactAddress" => "Stockton St."
  }

  @valid_marketplace_params %{
    origin: "DH",
    marketplace: "Alibaba"
  }

  describe "create exporter" do
    test "creates exporter with valid params" do
      Credit.create_marketplace(@valid_marketplace_params)
      assert {:ok, %{Contact => _contact, Exporter => _exporter}} = Account.create_exporter(@valid_exporter_params)
    end
  end
end
