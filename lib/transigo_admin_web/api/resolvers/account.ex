defmodule TransigoAdminWeb.Api.Resolvers.Account do
  alias TransigoAdmin.{Account, Account.Guardian, Credit}

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

  def check_document(_root, %{exporter_uid: exporter_uid}, _context) do
    Account.get_exporter_by_exporter_uid(exporter_uid)
    |> Account.check_document()
  end

  def check_document(_root, %{transaction_uid: transaction_uid}, _context) do
    Credit.get_transaction_by_transaction_uid(transaction_uid)
    |> Account.check_document()
  end
end
