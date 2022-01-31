defmodule TransigoAdminWeb.Api.Query.CreditTest do
  use TransigoAdminWeb.ConnCase, async: true

  alias TransigoAdmin.{Account, Credit}
  alias TransigoAdmin.Account.Exporter
  alias TransigoAdmin.Repo

  @list_quotas """
  query($first: Integer!) {
    listQuotas(first: $first) {
      edges {
        node {
          id
        }
      }
    }
  }
  """

  @list_transactions """
  query($first: Integer!) {
    listTransactions(first: $first) {
      edges {
        node {
          id
        }
      }
    }
  }
  """

  @list_offers """
  query($first: Integer!) {
    listOffers(first: $first) {
      edges {
        node {
          id
        }
      }
    }
  }
  """

  @list_transactions_paginated_with_transaction_uid """
  query($first: Integer!,$keyword: String!) {
    ListTransactions(first: $first,keyword: $keyword) {
      edges {
        node {
          transactionUid
        }
      }
    }
  }
  """

  @list_transactions_paginated_with_importer_uid """
  query($first: Integer!,$keyword: String!) {
    ListTransactions(first: $first,keyword: $keyword) {
      edges {
        node {
          importer{
            importerTransigoUid
          }
        }
      }
    }
  }
  """

  @list_transactions_paginated_with_exporter_uid """
  query($first: Integer!,$keyword: String!) {
    ListTransactions(first: $first,keyword: $keyword) {
      edges {
        node {
          exporter{
            exporterTransigoUid
          }
        }
      }
    }
  }
  """

  @list_quota_paginated_with_quota_uid """
  query($first: Integer!,$keyword: String!) {
    listQuotas(first: $first,keyword: $keyword) {
      edges {
        node {
            quotaTransigoUid
        }
      }
    }
  }
  """

  @list_quota_paginated_with_importer_uid """
  query($first: Integer!,$keyword: String!) {
    listQuotas(first: $first,keyword: $keyword) {
      edges {
        node {
          importer{
            importerTransigoUid
          }
        }  
      }
    }
  }
  """
  @list_offer_with_transaction_uid """
  query($first: Integer!,$keyword: String!) {
    listOffers(first: $first,keyword: $keyword) {
      edges {
        node {
          transaction{
            transactionUid
          }
        }
      }
    }
  }
  """

  setup %{conn: conn} do
    marketplace =
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
      Account.create_exporter(
        %{
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
        },
        marketplace
      )

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

    {:ok, quota} =
      Credit.create_quota(%{
        quota_transigo_uid: "quota1",
        quota_usd: 30000,
        credit_days_quota: 60,
        credit_request_date: Timex.today(),
        token: "token",
        marketplace_transactions: 1,
        marketplace_total_transaction_sum_usd: 10_000_000,
        marketplace_transactions_last_year: 2,
        marketplace_total_transaction_sum_usd_last_year: 1_000_000,
        marketplace_number_disputes: 10,
        marketplace_number_adverse_disputes: 2,
        credit_status: "granted",
        funding_source_url:
          "https://api-sandbox.dwolla.com/funding-sources/239e3423-c7fa-4d24-b90c-ed50bb4ecd94",
        importer_id: importer.id
      })

    {:ok, transaction} =
      Credit.create_transaction(%{
        transaction_uid: "tran",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: :down_payment_done,
        financed_sum: 3000,
        invoice_date: Timex.now(),
        second_installment_usd: 3000,
        importer_id: importer.id,
        exporter_id: exporter.id,
        down_payment_confirmed_datetime: Timex.now() |> Timex.shift(days: -2)
      })

    {:ok, offer} =
      Credit.create_offer(%{
        transaction_id: transaction.id,
        transaction_usd: 3000,
        advance_percentage: 30,
        advance_usd: 300,
        importer_fee: 3000,
        offer_accepted_declined: "D"
      })

    {:ok,
     conn: put_req_header(conn, "authorization", "Bearer #{token}"),
     quota: quota,
     transaction: transaction,
     offer: offer}
  end

  test "can list quotas", %{conn: conn, quota: %{id: quota_id}} do
    response = post(conn, "/api", %{query: @list_quotas, variables: %{"first" => 3}})

    assert %{
             "data" => %{
               "listQuotas" => %{"edges" => [%{"node" => %{"id" => ^quota_id}}]}
             }
           } = json_response(response, 200)
  end

  test "can list transactions", %{conn: conn, transaction: %{id: transaction_id}} do
    response = post(conn, "/api", %{query: @list_transactions, variables: %{"first" => 3}})

    assert %{
             "data" => %{
               "listTransactions" => %{"edges" => [%{"node" => %{"id" => ^transaction_id}}]}
             }
           } = json_response(response, 200)
  end

  test "can list offers", %{conn: conn, offer: %{id: offer_id}} do
    response = post(conn, "/api", %{query: @list_offers, variables: %{"first" => 3}})

    assert %{
             "data" => %{
               "listOffers" => %{"edges" => [%{"node" => %{"id" => ^offer_id}}]}
             }
           } = json_response(response, 200)
  end

  test "can list transaction paginated with transaction_uid", %{
    conn: conn,
    transaction: %{transaction_uid: transaction_uid}
  } do
    response =
      post(conn, "/api", %{
        query: @list_transactions_paginated_with_transaction_uid,
        variables: %{"first" => 1, "keyword" => transaction_uid}
      })

    assert %{
             "data" => %{
               "ListTransactions" => %{
                 "edges" => [%{"node" => %{"transactionUid" => ^transaction_uid}}]
               }
             }
           } = json_response(response, 200)
  end

  test "can list transaction paginated with importer_uid or exporter_uid", %{
    conn: conn,
    transaction: %{id: transaction_id}
  } do
    transaction_t1 =
      Credit.get_transaction!(transaction_id) |> Repo.preload([:importer, :exporter])

    importeruid = transaction_t1.importer.importer_transigo_uid
    exporteruid = transaction_t1.exporter.exporter_transigo_uid

    # importer response
    importer_response =
      post(conn, "/api", %{
        query: @list_transactions_paginated_with_importer_uid,
        variables: %{"first" => 1, "keyword" => importeruid}
      })

    assert %{
             "data" => %{
               "ListTransactions" => %{
                 "edges" => [
                   %{"node" => %{"importer" => %{"importerTransigoUid" => ^importeruid}}}
                 ]
               }
             }
           } = json_response(importer_response, 200)

    # exporter response
    exporter_response =
      post(conn, "/api", %{
        query: @list_transactions_paginated_with_exporter_uid,
        variables: %{"first" => 1, "keyword" => exporteruid}
      })

    assert %{
             "data" => %{
               "ListTransactions" => %{
                 "edges" => [
                   %{"node" => %{"exporter" => %{"exporterTransigoUid" => ^exporteruid}}}
                 ]
               }
             }
           } = json_response(exporter_response, 200)
  end

  test "can quota paginated with quota_uid or importer_uid", %{
    conn: conn,
    quota: %{id: quota_id, quota_transigo_uid: quota_transigo_uid}
  } do
    quota = Credit.get_quota!(quota_id) |> Repo.preload([:importer])

    quota_importer_uid = quota.importer.importer_transigo_uid

    # quota response
    quota_response =
      post(conn, "/api", %{
        query: @list_quota_paginated_with_quota_uid,
        variables: %{"first" => 1, "keyword" => quota_transigo_uid}
      })

    assert %{
             "data" => %{
               "listQuotas" => %{
                 "edges" => [%{"node" => %{"quotaTransigoUid" => ^quota_transigo_uid}}]
               }
             }
           } = json_response(quota_response, 200)

    # importer response
    quota_importer_response =
      post(conn, "/api", %{
        query: @list_quota_paginated_with_importer_uid,
        variables: %{"first" => 1, "keyword" => quota_importer_uid}
      })

    assert %{
             "data" => %{
               "listQuotas" => %{
                 "edges" => [
                   %{"node" => %{"importer" => %{"importerTransigoUid" => ^quota_importer_uid}}}
                 ]
               }
             }
           } = json_response(quota_importer_response, 200)
  end

  test "can list offer paginated with transaction_uid", %{
    conn: conn,
    offer: %{id: offer_id}
  } do
    preloaded_offer = Credit.get_offer(offer_id, [:transaction])

    offer_transaction_uid = preloaded_offer.transaction.transaction_uid

    response =
      post(conn, "/api", %{
        query: @list_offer_with_transaction_uid,
        variables: %{"first" => 1, "keyword" => offer_transaction_uid}
      })

    assert %{
             "data" => %{
               "listOffers" => %{
                 "edges" => [
                   %{"node" => %{"transaction" => %{"transactionUid" => ^offer_transaction_uid}}}
                 ]
               }
             }
           } = json_response(response, 200)
  end
end
