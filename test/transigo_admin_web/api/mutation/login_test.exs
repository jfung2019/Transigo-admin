defmodule TransigoAdminWeb.Api.Mutation.LoginTest do
  use TransigoAdminWeb.ConnCase, async: true

  alias TransigoAdmin.Account

  @login """
  mutation($email: String!, $password: String!) {
    login(email: $email, password: $password) {
      admin {
        id
        email
      }
      token
    }
  }
  """

  setup %{conn: conn} do
    {:ok, admin} =
      Account.create_admin(%{
        firstname: "test",
        lastname: "admin",
        email: "test@email.com",
        username: "tester",
        mobile: "12345678",
        role: "test",
        company: "test",
        password: "123456"
      })

    {:ok, admin: admin, conn: conn}
  end

  test "can login", %{admin: %{id: admin_id, email: email}, conn: conn} do
    response =
      post(conn, "/api", %{query: @login, variables: %{email: email, password: "123456"}})

    assert %{
             "data" => %{
               "login" => %{"admin" => %{"id" => ^admin_id, "email" => ^email}, "token" => _token}
             }
           } = json_response(response, 200)
  end
end
