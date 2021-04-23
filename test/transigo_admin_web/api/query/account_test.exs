defmodule TransigoAdminWeb.Api.Query.AccountTest do
  use TransigoAdminWeb.ConnCase, async: true

  alias TransigoAdmin.Account

  @list_exporters """
  query($first: Integer!) {
    listExporters(first: $first) {
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

  setup %{conn: conn} do
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

    {:ok, %{id: marketplace_id}} =
      TransigoAdmin.Credit.create_marketplace(%{origin: "test", marketplace: "test"})

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

    {:ok, exporter} =
      Account.create_exporter(%{
        exporter_transigo_uid: "demo_exporter",
        business_name: "test",
        address: "100 address",
        business_address_country: "country",
        registration_number: "123",
        marketplace_id: marketplace_id,
        signatory_first_name: "first",
        signatory_last_name: "last",
        signatory_mobile: "12345678",
        signatory_email: "test@email.com",
        signatory_title: "owner",
        MSA_contact_id: contact_id
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

    {:ok,
     conn: put_req_header(conn, "authorization", "Bearer #{token}"),
     exporter: exporter,
     importer: importer}
  end

  test "can list exporters", %{conn: conn, exporter: %{id: exporter_id}} do
    response = post(conn, "/api", %{query: @list_exporters, variables: %{"first" => 3}})

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
               "listImporters" => %{"edges" => [%{"node" => %{"id" => ^importer_id}}]}
             }
           } = json_response(response, 200)
  end
end
