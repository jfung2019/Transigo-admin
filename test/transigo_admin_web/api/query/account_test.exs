defmodule TransigoAdminWeb.Api.Query.AccountTest do
  use TransigoAdminWeb.ConnCase, async: true

  alias TransigoAdmin.Account
  alias TransigoAdmin.Account.Exporter
  alias TransigoAdmin.Repo

  @list_exporters """
  query($first: Integer!, $keyword: String) {
    listExporters(first: $first, keyword: $keyword) {
      edges {
        node {
          id
        }
      }
    }
  }
  """

  @list_importers """
  query($first: Integer!) {
    listImporters(first: $first) {
      edges {
        node {
          id
        }
      }
    }
  }
  """

  @get_hellosign_url """
  query($exporterId: ID!) {
    signMsaUrl(exporterUid: $exporterId) {
      url
    }
  }
  """

  @get_transaction_sign_url """
  query($transaction_uid: ID!) {
    signDocsUrl(transactionUid: $transaction_uid) {
      url
    }
  }
  """

  setup %{conn: conn} do
    Repo.insert!(%TransigoAdmin.Credit.Marketplace{
      origin: "DH",
      marketplace: "DHGate"
    })

    {:ok, admin} =
      Account.create_admin(%{
        firstname: "test",
        lastname: "admin",
        email: "test@email.com",
        username: "tester",
        mobile: "12345678",
        role: "test",
        company: "test",
        password: "123456"
      })

    {:ok, token, _} = Account.Guardian.encode_and_sign(admin)

    {:ok, %{id: contact_id}} =
      Account.create_contact(%{
        contact_transigo_uid: "importer_contact",
        first_name: "first",
        last_name: "last",
        mobile: "12345678",
        work_phone: "12345678",
        email: "importer@email.com",
        role: "owner",
        country: "us"
      })

    {:ok, %{Exporter => exporter}} =
      Account.create_exporter(%{
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
      Account.create_importer(%{
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
        business_classification_id: "9ed46ba1-7d6f-11e3-9d1b-5404a6144203",
        contact_id: contact_id
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

    {:ok,
     conn: put_req_header(conn, "authorization", "Bearer #{token}"),
     exporter: exporter,
     importer: importer,
     transaction: transaction}
  end

  test "can list exporters", %{conn: conn, exporter: %{id: exporter_id}} do
    response = post(conn, "/api", %{query: @list_exporters, variables: %{"first" => 3}})

    assert %{
             "data" => %{
               "listExporters" => %{"edges" => [%{"node" => %{"id" => ^exporter_id}}]}
             }
           } = json_response(response, 200)
  end

  test "can search exporters", %{conn: conn, exporter: %{id: exporter_id, exporter_transigo_uid: uid}} do
    response = post(conn, "/api", %{query: @list_exporters, variables: %{"first" => 1, "keyword" => uid}})

    assert %{
             "data" => %{
               "listExporters" => %{"edges" => [%{"node" => %{"id" => ^exporter_id}}]}
             }
           } = json_response(response, 200)
  end

  test "can list importers", %{conn: conn, importer: %{id: importer_id}} do
    response = post(conn, "/api", %{query: @list_importers, variables: %{"first" => 3}})

    assert %{
             "data" => %{
               "listImporters" => %{
                 "edges" => [%{"node" => %{"id" => ^importer_id}}]
               }
             }
           } = json_response(response, 200)
  end

  test "can search importers", %{conn: conn, importer: %{id: importer_id, importer_transigo_uid: uid}} do
    response = post(conn, "/api", %{query: @list_importers, variables: %{"first" => 1, "keyword" => uid}})

    assert %{
             "data" => %{
               "listImporters" => %{
                 "edges" => [%{"node" => %{"id" => ^importer_id}}]
               }
             }
           } = json_response(response, 200)
  end

  test "can get hellosign URL", %{conn: conn, exporter: %{exporter_transigo_uid: exporter_id}} do
    response =
      post(conn, "/api", %{query: @get_hellosign_url, variables: %{"exporterId" => exporter_id}})

    assert %{
             "data" => %{
               "signMsaUrl" => %{
                 "url" => url
               }
             }
           } = json_response(response, 200)

    [_base, token] = String.split(url, "token=")
    assert {:ok, nil} = TransigoAdminWeb.Tokenizer.decrypt(token)

    assert is_binary(url)
  end

  test "cannot get hellosign URL for nonexistent exporter", %{conn: conn} do
    response =
      post(conn, "/api", %{
        query: @get_hellosign_url,
        variables: %{"exporterId" => TransigoAdmin.DataLayer.generate_uid("exp")}
      })

    assert %{
             "data" => %{
               "signMsaUrl" => %{
                 "url" => "could not get url"
               }
             }
           } = json_response(response, 200)
  end

  test "can get hellosign URL for transaction", %{conn: conn, transaction: transaction} do
    response =
      post(conn, "/api", %{
        query: @get_transaction_sign_url,
        variables: %{"transaction_uid" => transaction.transaction_uid}
      })

    assert %{
             "data" => %{
               "signDocsUrl" => %{
                 "url" => url
               }
             }
           } = json_response(response, 200)

    [_base, token] = String.split(url, "token=")
    assert {:ok, nil} = TransigoAdminWeb.Tokenizer.decrypt(token)

    assert is_binary(url)
  end

  test "cannot get hellosign URL for nonexistent transaction", %{conn: conn} do
    response =
      post(conn, "/api", %{
        query: @get_transaction_sign_url,
        variables: %{"transaction_uid" => TransigoAdmin.DataLayer.generate_uid("tra")}
      })

    assert %{
             "data" => %{
               "signDocsUrl" => %{
                 "url" => "could not get url"
               }
             }
           } = json_response(response, 200)
  end
end
