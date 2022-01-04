defmodule TransigoAdmin.CreditTest do
  use TransigoAdmin.DataCase, async: false

  alias TransigoAdmin.{Account, Credit, DataLayer}
  alias TransigoAdmin.Account.Exporter

  describe "transaction" do
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

    test "can confirm downpayment", %{exporter: exporter, importer: importer} do
      {:ok, %{transaction_uid: uid, id: transaction_id}} =
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

      {:ok, %{id: _o1_id}} =
        Credit.create_offer(%{
          transaction_id: transaction_id,
          transaction_usd: 10000,
          advance_percentage: 30,
          advance_usd: 3000,
          importer_fee: 550,
          offer_accepted_declined: "A"
        })

      assert {:ok, %{transaction_uid: ^uid}} =
               Credit.confirm_downpayment(uid, %{
                 "downpaymentConfirm" => "confirmed",
                 "sumPaidusd" => "3000"
               })
    end

    test "can offer accept decline more than once", %{exporter: exporter, importer: importer} do
      {:ok, %{transaction_uid: uid, id: transaction_id}} =
        Credit.create_transaction(%{
          transaction_uid: "accept_case",
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

      {:ok, %{id: _o1_id}} =
        Credit.create_offer(%{
          transaction_id: transaction_id,
          transaction_usd: 10000,
          advance_percentage: 30,
          advance_usd: 3000,
          importer_fee: 550,
          offer_accepted_declined: "A"
        })

      {:ok, %{transaction_uid: uid2, id: transaction_id2}} =
        Credit.create_transaction(%{
          transaction_uid: "decline_case",
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

      {:ok, %{id: _o2_id}} =
        Credit.create_offer(%{
          transaction_id: transaction_id2,
          transaction_usd: 10000,
          advance_percentage: 30,
          advance_usd: 3000,
          importer_fee: 550,
          offer_accepted_declined: "D"
        })

      assert {:error, "offer already accepted or declined"} =
               Credit.accept_decline_offer(uid, true)

      assert {:error, "offer already accepted or declined"} =
               Credit.accept_decline_offer(uid, false)

      assert {:error, "offer already accepted or declined"} =
               Credit.accept_decline_offer(uid2, true)

      assert {:error, "offer already accepted or declined"} =
               Credit.accept_decline_offer(uid2, false)
    end

    test "can get_total_open_factoring_price return correct price", %{
      exporter: exporter,
      importer: importer
    } do

      transaction_uid_list =
        1..10
        |> Enum.map(fn _ ->
          {:ok, %{transaction_uid: tra_uid, id: tx_id}} =
            Credit.create_transaction(%{
              transaction_uid: DataLayer.generate_uid("tra"),
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

          {:ok, %{id: _of_id}} =
            Credit.create_offer(%{
              transaction_id: tx_id,
              transaction_usd: 10000,
              advance_percentage: 30,
              advance_usd: 3000,
              importer_fee: 550,
              offer_accepted_declined: nil
            })

          tra_uid
        end)

      # case with offer_accepted_declined be the first-eighth="A", ninth="D", lastone= nil

      accept_transactoin_id_list = Enum.drop(transaction_uid_list, -2)

      declined_transaction_id_list = [Enum.at(transaction_uid_list, 8)]

      Enum.map(accept_transactoin_id_list, fn tra_uid ->
        Credit.accept_decline_offer(tra_uid, true)
      end)

      Enum.map(declined_transaction_id_list, fn tra_uid ->
        Credit.accept_decline_offer(tra_uid, false)
      end)

      # case with transaction_state = "created","xxx","repaid","rev_share_paid","disputed","moved_to_payment","originated"

      transaction_state_list = [
        "repaid",
        "rev_share_paid",
        "rev_share_to_be_paid",
        "disputed",
        "moved_to_payment",
        "originated",
        "down_payment_done",
        "assigned",
        "xxx",
        "created"
      ]

      # map each uid in list_transaction_id into one state of transaction_state_list

      uid_state_pair_list = Enum.zip(transaction_uid_list, transaction_state_list)

      Enum.map(uid_state_pair_list, fn x ->
        Credit.update_transaction(Credit.get_transaction_by_transaction_uid(elem(x, 0)), %{
          transaction_state: elem(x, 1)
        })
      end)

      assert Credit.get_total_open_factoring_price(importer.id) == 18000
    end
  end
end
