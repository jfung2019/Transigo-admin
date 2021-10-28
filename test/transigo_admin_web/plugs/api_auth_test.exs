defmodule TransigoAdminWeb.ApiAuthTest do
  use TransigoAdminWeb.ConnCase, async: true
  alias TransigoAdmin.Repo

  test "can assign marketplace and user to conn", %{conn: conn} do
    access_token =
      "f62691f4b010d029f32d82ddc6088013ccf23f9d778a09af4944548b9caac51dfb95c9b5b376c0a2c94f291be2c1f81ebfddedfc315067ec1139a2d07516"

    %{id: marketplace_id} =
      Repo.insert!(%TransigoAdmin.Credit.Marketplace{
        origin: "DH",
        marketplace: "DHGate"
      })

    %{id: user_id} =
      Repo.insert!(%TransigoAdmin.Account.User{
        user_uid: "Tusr-1816-603e-00e0-0bef-f4ec-7567",
        webhook: "http://sandbox.camelfin.com/buyerfinanceweb/quota/quotaTgReturn",
        company: "camel-sandbox",
        client_id: "1965ea39abd27b085503555b5ebd1cc2b3679f7458f8bf7613a00cde8cc957db",
        client_secret:
          "5ed185b8b9f8465c6a2213f40e3df536b4bde42ce4eab7c1e4e43d60b0749410a08ca623994653413f6bc4a6a2cfd136",
        marketplace_id: marketplace_id
      })

    %{id: _token_id} =
      Repo.insert!(%TransigoAdmin.Account.Token{
        access_token: access_token,
        user_id: user_id
      })

    conn =
      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> access_token)
      |> bypass_through(OmegaBravera.Router, :api)

    assert %{assigns: %{marketplace: %{id: ^marketplace_id}, user: %{id: ^user_id}}} =
             TransigoAdminWeb.ApiAuth.call(conn, nil)
  end
end
