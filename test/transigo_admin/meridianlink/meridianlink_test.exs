defmodule TransigoAdmin.MeridianlinkTest do
  use TransigoAdmin.DataCase, async: true

  alias TransigoAdmin.Meridianlink
  alias TransigoAdmin.Account.Contact
  alias TransigoAdmin.Repo

  test "can update a contact" do
    contact =
      Repo.all(Contact)
      |> List.first()

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
