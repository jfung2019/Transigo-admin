defmodule TransigoAdmin.Meridianlink.APITest do
  use TransigoAdmin.DataCase, async: true

  alias TransigoAdmin.Meridianlink.API
  alias TransigoAdmin.Account.Contact
  alias TransigoAdmin.Repo

  test "can update a contact" do
    contact =
      Repo.all(Contact)
      |> List.first()

    assert :ok = API.update_contact_consumer_credit_report(contact.id)
  end
end
