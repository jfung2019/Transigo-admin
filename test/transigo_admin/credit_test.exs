defmodule TransigoAdmin.CreditTest do
  use TransigoAdmin.DataCase, async: false

  alias TransigoAdmin.{Account, Credit}

  describe "transaction" do
    setup do
      exporter =
        Account.create_exporter(%{
          exporter_transigoUID: "test_exporter",
          business_name: "test",
          address: "100 address",
          business_address_country: "country",
          registration_number: "123",
          signatory_first_name: "first",
          signatory_last_name: "last",
          signatory_mobile: "12345678",
          signatory_email: "test@email.com",
          signatory_title: "owner"
        })

      importer =
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
          business_classification_id: "9ed46ba1-7d6f-11e3-9d1b-5404a6144203"
        })

      %{exporter: exporter, importer: importer}
    end

    test "can get transaction due in 3 days", %{exporter: exporter, importer: importer} do
      # transaction far in the future

      # transaction due in 3 days
#      transaction_due = Credit.create_transaction(%{})

      # transaction in the past

      assert [] == Credit.list_transactions_due_in_3_days()
    end
  end
end
