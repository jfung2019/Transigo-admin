defmodule TransigoAdmin.CreditTest do
  use TransigoAdmin.DataCase, async: false

  alias TransigoAdmin.{Account, Credit}

  describe "transaction" do
    setup do
      {:ok, %{id: marketplace_id}} =
        Credit.create_marketplace(%{origin: "DH", marketplace: "DHgate"})

      {:ok, exporter} =
        Account.create_exporter(%{
          exporter_transigo_uid: "test_exporter",
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
          business_classification_id: "9ed46ba1-7d6f-11e3-9d1b-5404a6144203"
        })

      %{exporter: exporter, importer: importer}
    end

    test "can get transaction due in 3 days", %{exporter: exporter, importer: importer} do
      # transaction far in the future
      Credit.create_transaction(%{
        transaction_uid: "future",
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

      # transaction due in 3 days
      due_date =
        Timex.now()
        |> Timex.shift(days: -57)

      {:ok, transaction_due} =
        Credit.create_transaction(%{
          transaction_uid: "due",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "assigned",
          financed_sum: 3000,
          invoice_date: due_date,
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      # transaction in the past
      due_past =
        Timex.now()
        |> Timex.shift(days: -120)

      Credit.create_transaction(%{
        transaction_uid: "past",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "assigned",
        financed_sum: 3000,
        invoice_date: due_past,
        second_installment_usd: 3000,
        importer_id: importer.id,
        exporter_id: exporter.id
      })

      assert [^transaction_due] = Credit.list_transactions_due_in_3_days()
    end

    test "can transaction due today", %{exporter: exporter, importer: importer} do
      # transaction far in the future
      Credit.create_transaction(%{
        transaction_uid: "future",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "originated",
        financed_sum: 3000,
        invoice_date: Timex.now(),
        second_installment_usd: 3000,
        importer_id: importer.id,
        exporter_id: exporter.id
      })

      # transaction due in 3 days
      due_date =
        Timex.now()
        |> Timex.shift(days: -60)

      {:ok, transaction_due} =
        Credit.create_transaction(%{
          transaction_uid: "due",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "email_sent",
          financed_sum: 3000,
          invoice_date: due_date,
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      assert [^transaction_due] = Credit.list_transactions_due_today()
    end

    test "can get transaction with different state", %{exporter: exporter, importer: importer} do
      {:ok, down_payment_done_transaction} =
        Credit.create_transaction(%{
          transaction_uid: "down_payment_done",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "down_payment_done",
          financed_sum: 3000,
          invoice_date: Timex.now(),
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      {:ok, pull_initiated_transaction} =
        Credit.create_transaction(%{
          transaction_uid: "pull_initiated",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "pull_initiated",
          financed_sum: 3000,
          invoice_date: Timex.now(),
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      {:ok, repaid_transaction} =
        Credit.create_transaction(%{
          transaction_uid: "repaid",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "repaid",
          financed_sum: 3000,
          invoice_date: Timex.now(),
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      assert [^down_payment_done_transaction] =
               Credit.list_transactions_by_state("down_payment_done")

      assert [^pull_initiated_transaction] = Credit.list_transactions_by_state("pull_initiated")
      assert [^repaid_transaction] = Credit.list_transactions_by_state("repaid")
    end
  end
end
