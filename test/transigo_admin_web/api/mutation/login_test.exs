defmodule TransigoAdminWeb.Api.Mutation.LoginTest do
  use TransigoAdminWeb.ConnCase, async: true

  alias TransigoAdmin.Account

  @login """
  mutation($email: String!, $password: String!, $totp: String!) {
    login(email: $email, password: $password, totp: $totp) {
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
    {:ok, _uri} = Account.generate_totp_secret(admin)

    {:ok, admin: admin, conn: conn}
  end

  test "can login", %{admin: %{id: admin_id, email: email}, conn: conn} do
    %{totp_secret: secret} = Account.get_admin!(admin_id)
    totp = NimbleTOTP.verification_code(secret)
    response =
      post(conn, "/api", %{query: @login, variables: %{email: email, password: "123456", totp: totp}})

    assert %{
             "data" => %{
               "login" => %{"admin" => %{"id" => ^admin_id, "email" => ^email}, "token" => _token}
             }
           } = json_response(response, 200)
  end
end
