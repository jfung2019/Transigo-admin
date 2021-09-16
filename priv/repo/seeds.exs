# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TransigoAdmin.Repo.insert!(%TransigoAdmin.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias TransigoAdmin.Repo

Repo.insert!(%TransigoAdmin.Credit.Marketplace{
  origin: "DH",
  marketplace: "DHGate"
})

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
  ssn: "000000015"
})
