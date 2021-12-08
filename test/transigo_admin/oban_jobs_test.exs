defmodule TransigoAdmin.ObanJobsTest do
  use TransigoAdmin.DataCase, async: false

  alias TransigoAdmin.{Account, Credit, Job, Job.Helper, Credit.Transaction}
  alias TransigoAdmin.Account.Exporter

  import Mox

  setup :verify_on_exit!

  setup do
    marketplace =
      Repo.insert!(%TransigoAdmin.Credit.Marketplace{
        origin: "DH",
        marketplace: "DHGate"
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

    {:ok, %{id: contact_id}} =
      Account.create_contact(%{
        contact_transigo_uid: "importer_contact",
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
          transaction_uid: "t1",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "assigned",
          financed_sum: 8000,
          invoice_date: due_date,
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      # transactions that due today
      due_date =
        Timex.now()
        |> Timex.shift(days: -60)

      {:ok, %{id: due_id}} =
        Credit.create_transaction(%{
          transaction_uid: "t3",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "assigned",
          financed_sum: 8000,
          invoice_date: due_date,
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      # transactions that was pulled
      {:ok, %{id: contact_id}} =
        Account.create_contact(%{
          contact_transigo_uid: "importer_contact2",
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
          importer_transigo_uid: "test_importer2",
          business_name: "test2",
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

      Credit.create_quota(%{
        quota_transigo_uid: "quota2",
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
        funding_source_url: "http://dwolla.com/funding-sources/id/repaid",
        importer_id: importer2.id
      })

      {:ok, %{id: repaid_id}} =
        Credit.create_transaction(%{
          transaction_uid: "t3",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "assigned",
          financed_sum: 8000,
          invoice_date: due_date,
          second_installment_usd: 3000,
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
        transaction_uid: "not_count1",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "created",
        financed_sum: 3000,
        invoice_date: Timex.now(),
        second_installment_usd: 3000,
        importer_id: importer.id,
        exporter_id: exporter.id
      })

      # transaction with down payment confirmed
      {:ok, %{id: t1_id}} =
        Credit.create_transaction(%{
          transaction_uid: "t1",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "down_payment_done",
          hs_signing_status: "all_signed",
          financed_sum: 8000,
          invoice_date: Timex.now(),
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      {:ok, %{id: _o1_id}} =
        Credit.create_offer(%{
          transaction_id: t1_id,
          transaction_usd: 10000,
          advance_percentage: 30,
          advance_usd: 3000,
          importer_fee: 550,
          offer_accepted_declined: "A"
        })

      # transaction with down payment confirmed
      {:ok, %{id: t2_id}} =
        Credit.create_transaction(%{
          transaction_uid: "t2",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "down_payment_done",
          hs_signing_status: "all_signed",
          financed_sum: 8000,
          invoice_date: Timex.now(),
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      {:ok, %{id: _o2_id}} =
        Credit.create_offer(%{
          transaction_id: t2_id,
          transaction_usd: 10000,
          advance_percentage: 30,
          advance_usd: 3000,
          importer_fee: 550,
          offer_accepted_declined: "D"
        })

      # transaction with down payment confirmed
      {:ok, %{id: t3_id}} =
        Credit.create_transaction(%{
          transaction_uid: "t3",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "down_payment_done",
          hs_signing_status: "missing transigo",
          financed_sum: 8000,
          invoice_date: Timex.now(),
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      {:ok, %{id: _o3_id}} =
        Credit.create_offer(%{
          transaction_id: t3_id,
          transaction_usd: 10000,
          advance_percentage: 30,
          advance_usd: 3000,
          importer_fee: 550,
          offer_accepted_declined: "A"
        })

      expect(TransigoAdmin.Job.HelperMock, :move_transaction_to_state, fn %Transaction{} =
                                                                            transaction,
                                                                          state ->
        case Credit.update_transaction(transaction, %{transaction_state: state}) do
          {:ok, transaction} ->
            %{
              transctionUID: transaction.transaction_uid,
              sum: Float.round(transaction.financed_sum, 2)
            }
            |> Helper.put_datetime(transaction)

          {:error, _} ->
            nil
        end
      end)

      expect(TransigoAdmin.Job.HelperMock, :notify_api_users, fn result, _event ->
        result.dailyTransactions
        |> Enum.map(fn x -> x.transctionUID end)
      end)

      expect(TransigoAdmin.Job.HelperMock, :cal_total_sum, fn transactions ->
        Enum.reduce(transactions, %{sum: 0}, fn %{sum: sum}, acc ->
          %{sum: acc.sum + sum}
        end)
      end)

      result = Job.DailyBalance.do_daily_balance() |> List.flatten()

      assert [%{id: ^t1_id}] = Credit.list_transactions_by_state("moved_to_payment")

      assert t2_id not in result
      assert t3_id not in result
    end
  end

  describe "Monthly RevShare" do
    test "can perform rev share correctly", %{exporter: exporter, importer: importer} do
      # transaction that should not be counted
      Credit.create_transaction(%{
        transaction_uid: "not_count1",
        credit_term_days: 60,
        down_payment_usd: 3000,
        factoring_fee_usd: 3000,
        transaction_state: "created",
        financed_sum: 3000,
        invoice_date: Timex.now(),
        second_installment_usd: 3000,
        importer_id: importer.id,
        exporter_id: exporter.id
      })

      # transaction with down payment confirmed
      {:ok, %{id: t1_id}} =
        Credit.create_transaction(%{
          transaction_uid: "t1",
          credit_term_days: 60,
          down_payment_usd: 3000,
          factoring_fee_usd: 3000,
          transaction_state: "repaid",
          financed_sum: 8000,
          invoice_date: Timex.now(),
          second_installment_usd: 3000,
          importer_id: importer.id,
          exporter_id: exporter.id
        })

      assert :ok = Job.MonthlyRevShare.perform(%Oban.Job{})

      assert [%{id: ^t1_id}] = Credit.list_transactions_by_state("rev_share_to_be_paid")
    end
  end
end
