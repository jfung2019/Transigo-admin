defmodule TransigoAdmin.AccountTest do
  use TransigoAdmin.DataCase

  alias TransigoAdmin.Account
  alias TransigoAdmin.Account.Contact
  alias TransigoAdmin.Account.Exporter

  @valid_exporter_params %{
    "businessName" => "Best Business",
    "address" => "3503 Bennet Ave, Santa Clara CA, 95051",
    "businessAddressCountry" => "USA",
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
    "contactAddress" => "Stockton St.",
    "marketplaceOrigin" => "DH"
  }

  @valid_update_exporter_params %{
    "businessName" => "Best Business",
    "signatoryFirstName" => "Martha",
    "signatoryLastName" => "Devon",
    "signatoryMobile" => "7077323615",
    "signatoryEmail" => "martha@bbiz.com",
    "signatoryTitle" => "Founder",
    "contactFirstName" => "Damien",
    "contactLastName" => "Washington",
    "contactMobile" => "7071749424",
    "workPhone" => "7074026748",
    "contactEmail" => "damien@bbiz.com",
    "contactTitle" => "CEO",
    "marketplaceOrigin" => "DH"
  }

  def create_exporter(params \\ @valid_exporter_params) do
    Account.create_exporter(params)
  end

  describe "create exporter" do
    setup do
      marketplace =
        Repo.insert!(%TransigoAdmin.Credit.Marketplace{
          origin: "DH",
          marketplace: "DHGate"
        })

      %{marketplace: marketplace}
    end

    test "creates exporter with valid params" do
      assert {:ok, %{Contact => contact, Exporter => exporter}} = create_exporter()
      assert contact.first_name == @valid_exporter_params["contactFirstName"]
      assert exporter.business_name == @valid_exporter_params["businessName"]
    end

    test "show error with invalid address params" do
      assert {:error, _schema, _changeset, _} =
               @valid_exporter_params
               |> Map.put("address", "as;dlfkj;lkjlkjfd")
               |> create_exporter()
    end

    test "show error with invalid email params" do
      assert {:error, _schema, _changeset, _} =
               @valid_exporter_params
               |> Map.put("signatoryEmail", "asl;dfkjlkjl")
               |> create_exporter()
    end
  end

  describe "get exporter" do
    setup do
      marketplace =
        Repo.insert!(%TransigoAdmin.Credit.Marketplace{
          origin: "DH",
          marketplace: "DHGate"
        })

      %{marketplace: marketplace}
    end
    test "can retrive an exporter with valid params" do
      {:ok, %{Contact => _contact, Exporter => exporter}} = create_exporter()

      assert {:ok, get_exporter} =
               Account.get_exporter_by_exporter_uid(exporter.exporter_transigo_uid)

      assert exporter.id == get_exporter.id
    end

    test "shows error with invalid id" do
      assert {:error, _message} = Account.get_exporter_by_exporter_uid("12323")
    end
  end

  describe "update exporter" do
    setup do
      marketplace =
        Repo.insert!(%TransigoAdmin.Credit.Marketplace{
          origin: "DH",
          marketplace: "DHGate"
        })

      %{marketplace: marketplace}
    end
    test "can update exporter with valid params" do
      {:ok, %{Contact => contact, Exporter => exporter}} = create_exporter()

      assert {:ok, %{Contact => updated_contact, Exporter => updated_exporter}} =
               Account.update_exporter(
                 @valid_update_exporter_params
                 |> Map.put("exporter_uid", exporter.exporter_transigo_uid)
               )

      assert contact.id == updated_contact.id
      assert exporter.id == updated_exporter.id
      assert contact.first_name == @valid_exporter_params["contactFirstName"]
      assert updated_contact.first_name == @valid_update_exporter_params["contactFirstName"]
      assert exporter.signatory_first_name == @valid_exporter_params["signatoryFirstName"]

      assert updated_exporter.signatory_first_name ==
               @valid_update_exporter_params["signatoryFirstName"]
    end

    test "shows error when invalid update params given" do
      {:ok, %{Contact => _contact, Exporter => exporter}} = create_exporter()

      assert {:error, _} =
               Account.update_exporter(
                 @valid_update_exporter_params
                 |> Map.put("signatoryEmail", "not an email")
                 |> Map.put("exporter_uid", exporter.exporter_transigo_uid)
               )
    end
  end

  describe "Google maps" do
    test "valid address returns ok" do
      assert {:ok, _res} = GoogleMaps.geocode("3503 Bennet Ave, Santa Clara CA, 95051")
    end

    test "invalid address returns error" do
      assert {:error, _res} = GoogleMaps.geocode("asldkjflj;lkj")
    end
  end
end
