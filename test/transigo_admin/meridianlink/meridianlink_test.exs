defmodule TransigoAdmin.MeridianlinkTest do
  use TransigoAdmin.DataCase, async: true

  alias TransigoAdmin.Meridianlink
  alias TransigoAdmin.Account.Contact
  alias TransigoAdmin.Repo

  test "can update a contact" do
    contact =
      Repo.all(Contact)
      |> List.first()

    assert :ok = Meridianlink.update_contact_consumer_credit_report(contact.id)
  end
end
