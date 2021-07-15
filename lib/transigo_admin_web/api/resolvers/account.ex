defmodule TransigoAdminWeb.Api.Resolvers.Account do
  alias TransigoAdmin.{Account, Account.Guardian}

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
    # transigo not signed -> send sign url
    # transigo signed but not exporter / all signed -> download file from hellosign
  end

  def check_document(_root, %{transaction_uid: transaction_uid}, _context) do
    # transigo not signed -> send sign url
    # transigo signed but not exporter / all signed -> download file from hellosign
  end
end
