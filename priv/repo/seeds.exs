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

TransigoAdmin.Repo.insert!(%TransigoAdmin.Credit.Marketplace{
    origin: "DH",
    marketplace: "DHGate"
})
