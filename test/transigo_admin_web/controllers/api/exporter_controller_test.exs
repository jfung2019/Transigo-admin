defmodule TransigoAdminWeb.Api.ExporterControllerTest do
  use TransigoAdminWeb.ConnCase, async: true

  alias TransigoAdmin.Repo
  alias TransigoAdmin.Account.{Exporter, Contact, Token}

  describe "create exporter" do
    setup do
      marketplace =
        Repo.insert!(%TransigoAdmin.Credit.Marketplace{
          origin: "DH",
          marketplace: "DHGate"
        })

      exporter_params = %{
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

      %{marketplace: marketplace, exporter_params: exporter_params}
    end

    test "successfully creates exporter with valid params", %{
      conn: conn,
      marketplace: _,
      exporter_params: exporter_params
    } do
      token = Repo.insert!(%Token{access_token: "token"})

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> post(Routes.exporter_path(conn, :create_exporter), exporter_params)
        |> json_response(:ok)

      assert %{"result" => %{"exporter_transigoUID" => _}} = res
    end

    test "invalid email on create gives error", %{
      conn: conn,
      marketplace: _,
      exporter_params: exporter_params
    } do
      token = Repo.insert!(%Token{access_token: "token"})

      exporter_params =
        exporter_params
        |> Map.put("contactEmail", "not an email")
        |> Map.put("signatoryEmail", "not an email")

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> post(Routes.exporter_path(conn, :create_exporter), exporter_params)
        |> json_response(:bad_request)

      assert %{"errors" => ["Could not create exporter"]} = res
    end
  end

  describe "show exporter" do
    setup do
      marketplace =
        Repo.insert!(%TransigoAdmin.Credit.Marketplace{
          origin: "DH",
          marketplace: "DHGate"
        })

      {:ok, %{Exporter => exporter, Contact => _contact}} =
        TransigoAdmin.Account.create_exporter(%{
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
        })

      %{marketplace: marketplace, exporter: exporter}
    end

    test "can show exporter with valid params", %{conn: conn, marketplace: _, exporter: exporter} do
      token = Repo.insert!(%Token{access_token: "token"})

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> get(Routes.exporter_path(conn, :show_exporter, exporter.exporter_transigo_uid))
        |> json_response(:ok)

      assert %{"result" => %{"exporter" => exporter_fields}} = res
      assert exporter_fields["exporter_transigo_uid"] == exporter.exporter_transigo_uid
    end

    test "cannot show exporter with that does not exist", %{
      conn: conn,
      marketplace: _,
      exporter: _exporter
    } do
      rand_uid = TransigoAdmin.DataLayer.generate_uid("exp")
      token = Repo.insert!(%Token{access_token: "token"})

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> get(Routes.exporter_path(conn, :show_exporter, rand_uid))
        |> json_response(:bad_request)

      assert %{"errors" => ["Could not find exporter"]} = res
    end

    test "cannot show exporter with invalid uid", %{
      conn: conn,
      marketplace: _,
      exporter: _exporter
    } do
      token = Repo.insert!(%Token{access_token: "token"})

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> get(Routes.exporter_path(conn, :show_exporter, "123"))
        |> json_response(:bad_request)

      assert %{"errors" => ["Invalid UID"]} = res
    end
  end

  describe "update exporter" do
    setup do
      marketplace =
        Repo.insert!(%TransigoAdmin.Credit.Marketplace{
          origin: "DH",
          marketplace: "DHGate"
        })

      {:ok, %{Exporter => exporter, Contact => _contact}} =
        TransigoAdmin.Account.create_exporter(%{
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
        })

      %{marketplace: marketplace, exporter: exporter}
    end

    test "can update exporter with valid params", %{
      conn: conn,
      marketplace: _,
      exporter: exporter
    } do
      token = Repo.insert!(%Token{access_token: "token"})

      update_params = %{"signatoryFirstName" => "Joe"}

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> put(
          Routes.exporter_path(conn, :update_exporter, exporter.exporter_transigo_uid),
          update_params
        )
        |> json_response(:ok)

      assert %{"result" => %{"exporter" => exporter_fields}} = res
      assert exporter_fields["signatory_first_name"] == update_params["signatoryFirstName"]
      assert exporter_fields["signatory_last_name"] == exporter.signatory_last_name
    end

    test "cannot update exporter with invalid params", %{
      conn: conn,
      marketplace: _,
      exporter: exporter
    } do
      token = Repo.insert!(%Token{access_token: "token"})

      update_params = %{"signatoryEmail" => "not an email"}

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> put(
          Routes.exporter_path(conn, :update_exporter, exporter.exporter_transigo_uid),
          update_params
        )
        |> json_response(:bad_request)

      assert %{"errors" => [%{"signatory_email" => ["is not a valid email"]}]} = res
    end

    test "cannot update exporter with non updatable params", %{
      conn: conn,
      marketplace: _,
      exporter: exporter
    } do
      token = Repo.insert!(%Token{access_token: "token"})

      update_params = %{"address" => "not an updatable param"}

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> put(
          Routes.exporter_path(conn, :update_exporter, exporter.exporter_transigo_uid),
          update_params
        )
        |> json_response(:ok)

      assert %{"result" => %{"exporter" => exporter_fields}} = res
      assert exporter_fields["address"] == exporter.address
    end
  end

  describe "msa" do
    setup do
      marketplace =
        Repo.insert!(%TransigoAdmin.Credit.Marketplace{
          origin: "DH",
          marketplace: "DHGate"
        })

      {:ok, %{Exporter => exporter, Contact => _contact}} =
        TransigoAdmin.Account.create_exporter(%{
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
        })

      %{marketplace: marketplace, exporter: exporter}
    end

    test "can redirect to msa url", %{conn: conn, marketplace: _, exporter: exporter} do
      token = Repo.insert!(%Token{access_token: "token"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> get(Routes.exporter_path(conn, :get_msa, exporter.exporter_transigo_uid))

      assert redirected_to(conn) =~ "url"
    end

    test "can sign an msa", %{conn: conn, marketplace: _, exporter: exporter} do
      token = Repo.insert!(%Token{access_token: "token"})

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> get(Routes.exporter_path(conn, :sign_msa, exporter.exporter_transigo_uid))
        |> json_response(:ok)

      assert res == %{"result" => %{"sign_url" => ""}}
    end
  end

  describe "transaction" do
    setup do
      marketplace =
        Repo.insert!(%TransigoAdmin.Credit.Marketplace{
          origin: "DH",
          marketplace: "DHGate"
        })

      {:ok, %{Exporter => exporter, Contact => _contact}} =
        TransigoAdmin.Account.create_exporter(%{
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
        })

      {:ok, importer} =
        TransigoAdmin.Account.create_importer(%{
          importer_transigo_uid: "test_importer",
          business_name: "test",
          business_ein: "ein",
          incorporation_date: Timex.today(),
          number_duns: "duns",
          business_address_street_address: "100 street",
          business_address_city: "city",
          business_address_state: "state",
          business_address_zip: "00000",
          business_address_country: "country",
          business_type: "soleProprietorship",
          business_classification_id: "9ed46ba1-7d6f-11e3-9d1b-5404a6144203"
        })

      {:ok, transaction} =
        TransigoAdmin.Credit.create_transaction(%{
          transaction_uid: TransigoAdmin.DataLayer.generate_uid("tra"),
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "assigned",
          financed_sum: 3000,
          invoice_date: Timex.now(),
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      %{marketplace: marketplace, exporter: exporter, transaction: transaction}
    end

    test "can sign a transaction", %{
      conn: conn,
      marketplace: _,
      exporter: exporter,
      transaction: transaction
    } do
      token = Repo.insert!(%Token{access_token: "token"})

      res =
        conn
        |> put_req_header("authorization", "Bearer " <> token.access_token)
        |> get(
          Routes.exporter_path(
            conn,
            :sign_transaction,
            exporter.exporter_transigo_uid,
            transaction.transaction_uid
          )
        )
        |> html_response(:ok)

      assert res =~ "const client = new HelloSign({"
    end
  end
end
