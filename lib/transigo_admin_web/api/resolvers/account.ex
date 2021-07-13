defmodule TransigoAdminWeb.Api.Resolvers.Account do
  alias TransigoAdmin.{Account, Account.Guardian}

  def login(_root, %{email: email, password: password}, _context) do
    with admin <- Account.find_admin(email),
         true <- Account.check_password(admin, password) do
      {:ok, admin}
    else
      _ -> {:error, :unauthorized}
    end
  end

  def verify_totp(_root, %{admin_id: admin_id, totp: totp}, _context) do
    with %{} = admin <- Account.get_admin!(admin_id),
         :valid <- Account.validate_totp(admin, totp),
         {:ok, token, _} <- Guardian.encode_and_sign(admin) do
      {:ok, %{admin: admin, token: token}}
    else
      :invalid -> {:error, :totp_invalid}
      _ -> {:error, :unauthorized}
    end
  end

  def list_exporters(_root, args, _context), do: Account.list_exporters_paginated(args)

  def list_importers(_root, args, _context), do: Account.list_importers_paginated(args)
end
