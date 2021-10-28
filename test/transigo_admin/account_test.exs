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
               |> Map.put("address", "not an address")
               |> create_exporter()
    end

    test "show error with invalid email params" do
      assert {:error, _schema, _changeset, _} =
               @valid_exporter_params
               |> Map.put("signatoryEmail", "not an email")
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

  describe "user token" do
    test "can get token with user from token's access_token" do
      %{id: marketplace_id} =
        Repo.insert!(%TransigoAdmin.Credit.Marketplace{
          origin: "DH",
          marketplace: "DHGate"
        })

      # create user with a link to the marketplace
      %{id: user_id} =
        Repo.insert!(%TransigoAdmin.Account.User{
          user_uid: "Tusr-1816-603e-00e0-0bef-f4ec-7567",
          webhook: "http://sandbox.camelfin.com/buyerfinanceweb/quota/quotaTgReturn",
          company: "camel-sandbox",
          client_id: "1965ea39abd27b085503555b5ebd1cc2b3679f7458f8bf7613a00cde8cc957db",
          client_secret:
            "5ed185b8b9f8465c6a2213f40e3df536b4bde42ce4eab7c1e4e43d60b0749410a08ca623994653413f6bc4a6a2cfd136",
          marketplace_id: marketplace_id
        })

      # create token with a link to the user
      %{id: token_id, access_token: access_token} =
        Repo.insert!(%TransigoAdmin.Account.Token{
          access_token:
            "f62691f4b010d029f32d82ddc6088013ccf23f9d778a09af4944548b9caac51dfb95c9b5b376c0a2c94f291be2c1f81ebfddedfc315067ec1139a2d07516",
          user_id: user_id
        })

      assert %TransigoAdmin.Account.Token{
               id: ^token_id,
               user: %{id: ^user_id, marketplace: %{id: ^marketplace_id}}
             } = Account.get_user_and_marketplace_by_token(access_token)
    end
  end
end
