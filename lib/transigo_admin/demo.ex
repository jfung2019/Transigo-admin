defmodule TransigoAdmin.Demo do
  alias TransigoAdmin.{Account, Credit}

  def setup do
    {:ok, exporter} =
      Account.create_exporter(%{
        exporter_transigo_uid: "demo_exporter",
        business_name: "test",
        address: "100 address",
        business_address_country: "country",
        registration_number: "123",
        marketplace_id: "d8fb0588-b60f-4e24-aadf-dfd32ee251b2",
        signatory_first_name: "first",
        signatory_last_name: "last",
        signatory_mobile: "12345678",
        signatory_email: "test@email.com",
        signatory_title: "owner"
      })

    {:ok, %{id: contact_id}} =
      Account.create_contact(%{
        contact_transigo_uid: "importer_contact",
        first_name: "first",
        last_name: "last",
        mobile: "12345678",
        work_phone: "12345678",
        email: "57fa7c57-36b4-4d02-b80d-aff9d52ab594@email.webhook.site",
        role: "owner",
        country: "us"
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

    {:ok, %{id: quota_id}} =
      Credit.create_quota(%{
        quota_transigo_uid: "quota1",
        quota_usd: 30000,
        credit_days_quota: 60,
        credit_request_date: Timex.today(),
        token: "token",
        marketplace_transactions: 1,
        marketplace_total_transaction_sum_usd: 10_000_000,
        marketplace_transactions_last_12_months: 2,
        marketplace_total_transaction_sum_usd_last_12_months: 1_000_000,
        marketplace_number_disputes: 10,
        marketplace_number_adverse_disputes: 2,
        credit_status: "granted",
        funding_source_url:
          "https://api-sandbox.dwolla.com/funding-sources/239e3423-c7fa-4d24-b90c-ed50bb4ecd94",
        importer_id: importer.id
      })

    Account.get_user!("596c3db1-1936-4a9f-8411-0bcd836fac97")
    |> Account.update_user(%{webhook: "https://webhook.site/57fa7c57-36b4-4d02-b80d-aff9d52ab594"})

    %{
      exporter_id: exporter.id,
      importer_id: importer.id,
      contact_id: contact_id,
      quota_id: quota_id
    }
  end

  def prepare_daily_repayment(%{exporter_id: exporter_id, importer_id: importer_id} = map) do
    {:ok, %{id: repay1_id}} =
      Credit.create_transaction(%{
        transaction_uid: "demo_repay_1",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "assigned",
        financed_sum: 8000,
        invoice_date: Timex.now() |> Timex.shift(days: -57),
        second_installment_usd: 3000,
        importer_id: importer_id,
        exporter_id: exporter_id
      })

    {:ok, %{id: repay2_id}} =
      Credit.create_transaction(%{
        transaction_uid: "demo_repay_2",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "assigned",
        financed_sum: 8000,
        invoice_date: Timex.now() |> Timex.shift(days: -60),
        second_installment_usd: 3000,
        importer_id: importer_id,
        exporter_id: exporter_id
      })

    {:ok, %{id: repay3_id}} =
      Credit.create_transaction(%{
        transaction_uid: "demo_repay_3",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "pull_initiated",
        financed_sum: 8000,
        invoice_date: Timex.now() |> Timex.shift(days: -65),
        second_installment_usd: 3000,
        importer_id: importer_id,
        exporter_id: exporter_id,
        dwolla_repayment_transfer_url:
          "https://api-sandbox.dwolla.com/transfers/095d3096-f87b-eb11-812d-f0aab87d8d13"
      })

    Map.put(map, :repay_ids, [repay1_id, repay2_id, repay3_id])
  end

  def prepare_daily_balance(%{exporter_id: exporter_id, importer_id: importer_id} = map) do
    {:ok, %{id: balance1_id}} =
      Credit.create_transaction(%{
        transaction_uid: "demo_balance_1",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "down_payment_done",
        financed_sum: 3000,
        invoice_date: Timex.now(),
        second_installment_usd: 3000,
        importer_id: importer_id,
        exporter_id: exporter_id,
        down_payment_confirmed_datetime: Timex.now() |> Timex.shift(days: -2)
      })

    {:ok, %{id: balance2_id}} =
      Credit.create_transaction(%{
        transaction_uid: "demo_balance_2",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "down_payment_done",
        financed_sum: 8000,
        invoice_date: Timex.now(),
        second_installment_usd: 3000,
        importer_id: importer_id,
        exporter_id: exporter_id,
        down_payment_confirmed_datetime: Timex.now() |> Timex.shift(days: -1)
      })

    Map.put(map, :balance_ids, [balance1_id, balance2_id])
  end

  def prepare_monthly_rev_share(%{exporter_id: exporter_id, importer_id: importer_id} = map) do
    {:ok, %{id: share1_id}} =
      Credit.create_transaction(%{
        transaction_uid: "demo_share_1",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "repaid",
        financed_sum: 14000,
        invoice_date: Timex.now(),
        second_installment_usd: 3000,
        importer_id: importer_id,
        exporter_id: exporter_id,
        repaid_datetime: Timex.now() |> Timex.shift(days: -2)
      })

    {:ok, %{id: share2_id}} =
      Credit.create_transaction(%{
        transaction_uid: "demo_share_2",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "repaid",
        financed_sum: 9000,
        invoice_date: Timex.now(),
        second_installment_usd: 3000,
        importer_id: importer_id,
        exporter_id: exporter_id,
        repaid_datetime: Timex.now() |> Timex.shift(days: -1)
      })

    Map.put(map, :share_ids, [share1_id, share2_id])
  end

  # don't call setup()
  def prepare_daily_assignment() do
    {:ok, exporter} =
      Account.create_exporter(%{
        exporter_transigo_uid: "Texp-b401-41f0-fecd-5016-60ad-c97e",
        business_name: "test",
        address: "100 address",
        business_address_country: "country",
        registration_number: "123",
        marketplace_id: "d8fb0588-b60f-4e24-aadf-dfd32ee251b2",
        signatory_first_name: "first",
        signatory_last_name: "last",
        signatory_mobile: "12345678",
        signatory_email: "test@email.com",
        signatory_title: "owner"
      })

    {:ok, %{id: contact_id}} =
      Account.create_contact(%{
        contact_transigo_uid: "importer_contact",
        first_name: "first",
        last_name: "last",
        mobile: "12345678",
        work_phone: "12345678",
        email: "7ead15bc-b49c-434e-8b6f-1cd3e3e8146c@email.webhook.site",
        role: "owner",
        country: "us"
      })

    {:ok, importer} =
      Account.create_importer(%{
        importer_transigo_uid: "Timp-7cbd-d35a-3e5c-ec6d-9e05-a5b8",
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
      Credit.create_transaction(%{
        transaction_uid: "Ttra-4c6f-52e2-2f14-2cb2-ee94-14d0",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "originated",
        financed_sum: 9000,
        invoice_date: Timex.now(),
        invoice_ref: "demo_assign",
        second_installment_usd: 3000,
        importer_id: importer.id,
        exporter_id: exporter.id,
        repaid_datetime: Timex.now() |> Timex.shift(days: -1),
        hellosign_signature_request_id: "a098008b89db03d24794e889804ede84c2c28c2e"
      })

    %{
      importer_id: importer.id,
      contact_id: contact_id,
      exporter_id: exporter.id,
      assign_id: transaction.id
    }
  end
end
