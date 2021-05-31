defmodule TransigoAdminWeb.Api.Resolvers.Account do
  f.{Account, Account.Guardian}

  def login(_root, %{email: email, password: password}, _context) do
    with admin <- Account.find_admin(email),
         true <- Account.check_password(admin, password) do
      {:ok, token, _} = Guardian.encode_and_sign(admin)
      {:ok, %{admin: admin, token: token}}
    else
      _ -> {:error, :unauthorized}
    end
  end

  def list_exporters(_root, args, _context), do: Account.list_exporters_paginated(args)

  def list_importers(_root, args, _context), do: Account.list_importers_paginated(args)
end
