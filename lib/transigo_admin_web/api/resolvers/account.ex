defmodule TransigoAdminWeb.Api.Resolvers.Account do
  alias TransigoAdmin.{Account, Account.Guardian}

  def login(_root, %{email: email, password: password}, _context) do
    with user <- Account.find_admin(email),
         true <- Account.check_password(user, password) do
      {:ok, token, _} = Guardian.encode_and_sign(user)
      {:ok, %{user: user, token: token}}
    else
      _ -> {:error, :unauthorized}
    end
  end

  def list_exporters(_root, args, _context), do: Account.list_exporters_paginated(args)

  def list_importers(_root, args, _context), do: Account.list_importers_paginated(args)
end
