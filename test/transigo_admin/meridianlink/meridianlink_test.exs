defmodule TransigoAdmin.MeridianlinkTest do
  use TransigoAdmin.DataCase, async: true

  alias TransigoAdmin.Meridianlink
  alias TransigoAdmin.Account.Contact
  alias TransigoAdmin.Repo

  describe "meridianlink integration test" do
    setup do
      Repo.insert!(%TransigoAdmin.Credit.Marketplace{
        origin: "DH",
        marketplace: "DHGate"
      })

      us_place =
        Repo.insert!(%TransigoAdmin.Account.UsPlace{
          street_address: "8842 48th Ave",
          city: "Anthill",
          state: "MO",
          zip_code: "65488",
          country: "US",
          full_address: "8842 48th Ave Anthill MO 65488 USA",
          google_place_id: "some id",
          latitude: 123.45,
          longitude: 523.65,
          google_json: "some json"
        })

      contact =
        Repo.insert!(%TransigoAdmin.Account.Contact{
          contact_transigo_uid: TransigoAdmin.DataLayer.generate_uid("con"),
          first_name: "Bill",
          last_name: "TestCase",
          mobile: "7072934628",
          work_phone: "70793452837",
          email: "bill@testcase.com",
          role: "President",
          country: "US",
          address: "8842 48th Ave Anthill MO 65488",
          ssn: "000000015",
          us_place_id: us_place.id
        })

      importer =
        Repo.insert!(%TransigoAdmin.Account.Importer{
          importer_transigo_uid: TransigoAdmin.DataLayer.generate_uid("imp"),
          business_name: "test",
          business_ein: "ein",
          incorporation_date: Timex.today(),
          number_duns: "duns",
          business_address_street_address: "100 street",
          business_address_city: "city",
          business_address_state: "state",
          business_address_zip: "00000",
          business_address_country: "country",
          business_type: :soleProprietorship,
          business_classification_id: "9ed46ba1-7d6f-11e3-9d1b-5404a6144203",
          contact_id: contact.id
        })

      %{importer: importer, contact: contact}
    end

    test "can update a contact", %{importer: _importer, contact: contact} do
      # credit fields are nil
      assert contact.consumer_credit_score == nil
      assert contact.consumer_credit_score_percentile == nil
      assert contact.consumer_credit_report_meridianlink == nil

      assert :ok = Meridianlink.update_contact_consumer_credit_report(contact.id)

      # after update credit fields are filled in
      contact = Repo.get!(Contact, contact.id)
      assert contact.consumer_credit_score != nil
      assert contact.consumer_credit_score_percentile != nil
      assert contact.consumer_credit_report_meridianlink != nil
    end
  end
end