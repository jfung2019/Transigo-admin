defmodule TransigoAdmin.ObanJobsTest do
  use TransigoAdmin.DataCase, async: false

  alias TransigoAdmin.{Account, Credit, Job}

  setup do
    {:ok, %{id: marketplace_id}} =
      Credit.create_marketplace(%{origin: "DH", marketplace: "DHgate"})

    {:ok, exporter} =
      Account.create_exporter(%{
        exporter_transigoUID: "test_exporter",
        business_name: "test",
        address: "100 address",
        business_address_country: "country",
        registration_number: "123",
        marketplace_id: marketplace_id,
        signatory_first_name: "first",
        signatory_last_name: "last",
        signatory_mobile: "12345678",
        signatory_email: "test@email.com",
        signatory_title: "owner"
      })

    {:ok, %{id: contact_id}} =
      Account.create_contact(%{
        contact_transigoUID: "importer_contact",
        first_name: "first",
        last_name: "last",
        mobile: "12345678",
        work_phone: "12345678",
        email: "test@email.com",
        role: "owner",
        country: "us"
      })

    {:ok, importer} =
      Account.create_importer(%{
        importer_transigoUID: "test_importer",
        business_name: "test",
        business_EIN: "ein",
        incorporation_date: Timex.today(),
        number_DUNS: "duns",
        business_address_street_address: "100 street",
        business_address_city: "city",
        business_address_state: "state",
        business_address_zip: "00000",
        business_address_country: "country",
        business_type: "soleProprietorship",
        business_classification_id: "9ed46ba1-7d6f-11e3-9d1b-5404a6144203",
        contact_id: contact_id
      })

    Credit.create_quota(%{
      quota_transigoUID: "quota1",
      quota_USD: 30000,
      credit_days_quota: 60,
      credit_request_date: Timex.today(),
      token: "token",
      marketplace_transactions: 1,
      marketplace_total_transaction_sum_USD: 10_000_000,
      marketplace_transactions_last_12_months: 2,
      marketplace_total_transaction_sum_USD_last_12_months: 1_000_000,
      marketplace_number_disputes: 10,
      marketplace_number_adverse_disputes: 2,
      creditStatus: "granted",
      funding_source_url: "http://dwolla.com/funding-sources/id",
      importer_id: importer.id
    })

    %{exporter: exporter, importer: importer}
  end

  describe "Daily Repayment" do
    test "can perform repayment correctly", %{exporter: exporter, importer: importer} do
      # transactions that due in 3 days
      due_date =
        Timex.now()
        |> Timex.shift(days: -57)

      {:ok, %{id: email_id}} =
        Credit.create_transaction(%{
          transaction_UID: "t1",
          credit_term_days: 60,
          down_payment_USD: 3000,
          factoring_fee_USD: 3000,
          transaction_state: "originated",
          financed_sum: 8000,
          invoice_date: due_date,
          second_installment_USD: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      # transactions that due today
      due_date =
        Timex.now()
        |> Timex.shift(days: -60)

      {:ok, %{id: due_id}} =
        Credit.create_transaction(%{
          transaction_UID: "t3",
          credit_term_days: 60,
          down_payment_USD: 3000,
          factoring_fee_USD: 3000,
          transaction_state: "originated",
          financed_sum: 8000,
          invoice_date: due_date,
          second_installment_USD: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      # transactions that was pulled
      {:ok, %{id: contact_id}} =
        Account.create_contact(%{
          contact_transigoUID: "importer_contact2",
          first_name: "first",
          last_name: "last",
          mobile: "123456787",
          work_phone: "12345687",
          email: "test2@email.com",
          role: "owner",
          country: "us"
        })

      {:ok, importer2} =
        Account.create_importer(%{
          importer_transigoUID: "test_importer2",
          business_name: "test2",
          business_EIN: "ein",
          incorporation_date: Timex.today(),
          number_DUNS: "duns",
          business_address_street_address: "100 street",
          business_address_city: "city",
          business_address_state: "state",
          business_address_zip: "00000",
          business_address_country: "country",
          business_type: "soleProprietorship",
          business_classification_id: "9ed46ba1-7d6f-11e3-9d1b-5404a6144203",
          contact_id: contact_id
        })

      Credit.create_quota(%{
        quota_transigoUID: "quota2",
        quota_USD: 30000,
        credit_days_quota: 60,
        credit_request_date: Timex.today(),
        token: "token",
        marketplace_transactions: 1,
        marketplace_total_transaction_sum_USD: 10_000_000,
        marketplace_transactions_last_12_months: 2,
        marketplace_total_transaction_sum_USD_last_12_months: 1_000_000,
        marketplace_number_disputes: 10,
        marketplace_number_adverse_disputes: 2,
        creditStatus: "granted",
        funding_source_url: "http://dwolla.com/funding-sources/id/repaid",
        importer_id: importer2.id
      })

      {:ok, %{id: repaid_id}} =
        Credit.create_transaction(%{
          transaction_UID: "t3",
          credit_term_days: 60,
          down_payment_USD: 3000,
          factoring_fee_USD: 3000,
          transaction_state: "originated",
          financed_sum: 8000,
          invoice_date: due_date,
          second_installment_USD: 3000,
          importer_id: importer2.id,
          exporter_id: exporter.id
        })

      # perform oban job
      assert :ok = Job.DailyRepayment.perform(%Oban.Job{})

      # check emails are sent for transactions that dues in 3 days
      assert [%{id: ^email_id}] = Credit.list_transactions_by_state("email_sent")

      # check transfers are created for transactions that dues today
      assert [%{id: ^due_id}] = Credit.list_transactions_by_state("pull_initiated")

      # check transfers are processed from dwolla
      assert [%{id: ^repaid_id}] = Credit.list_transactions_by_state("repaid")
    end
  end

  describe "Daily Balance" do
    test "can perform balance correctly", %{exporter: exporter, importer: importer} do
      # transaction that should not be counted
      Credit.create_transaction(%{
        transaction_UID: "not_count1",
        credit_term_days: 60,
        down_payment_USD: 3000,
        factoring_fee_USD: 3000,
        transaction_state: "created",
        financed_sum: 3000,
        invoice_date: Timex.now(),
        second_installment_USD: 3000,
        importer_id: importer.id,
        exporter_id: exporter.id
      })

      # transaction with down payment confirmed
      {:ok, %{id: t1_id}} =
        Credit.create_transaction(%{
          transaction_UID: "t1",
          credit_term_days: 60,
          down_payment_USD: 3000,
          factoring_fee_USD: 3000,
          transaction_state: "down_payment_done",
          financed_sum: 8000,
          invoice_date: Timex.now(),
          second_installment_USD: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      assert :ok = Job.DailyBalance.perform(%Oban.Job{})

      assert [%{id: ^t1_id}] = Credit.list_transactions_by_state("moved_to_payment")
    end
  end

  describe "Monthly RevShare" do
    test "can perform rev share correctly", %{exporter: exporter, importer: importer} do
      # transaction that should not be counted
      Credit.create_transaction(%{
        transaction_UID: "not_count1",
        credit_term_days: 60,
        down_payment_USD: 3000,
        factoring_fee_USD: 3000,
        transaction_state: "created",
        financed_sum: 3000,
        invoice_date: Timex.now(),
        second_installment_USD: 3000,
        importer_id: importer.id,
        exporter_id: exporter.id
      })

      # transaction with down payment confirmed
      {:ok, %{id: t1_id}} =
        Credit.create_transaction(%{
          transaction_UID: "t1",
          credit_term_days: 60,
          down_payment_USD: 3000,
          factoring_fee_USD: 3000,
          transaction_state: "repaid",
          financed_sum: 8000,
          invoice_date: Timex.now(),
          second_installment_USD: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      assert :ok = Job.MonthlyRevShare.perform(%Oban.Job{})

      assert [%{id: ^t1_id}] = Credit.list_transactions_by_state("rev_share_to_be_paid")
    end
  end
end
