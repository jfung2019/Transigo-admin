defmodule TransigoAdminWeb.Api.Resolvers.Account do
  alias TransigoAdmin.{Account, Account.Guardian, Credit}
  alias TransigoAdminWeb.Router.Helpers, as: Routes

  @spec login(any, %{:email => binary, :password => any, :totp => any, optional(any) => any}, any) ::
          {:error, :totp_invalid | :unauthorized}
          | {:ok,
             %{
               admin: %{
                 :password_hash => <<_::64, _::_*8>>,
                 :totp_secret => any,
                 optional(any) => any
               },
               token: binary
             }}
  def login(_root, %{email: email, password: password, totp: totp}, _context) do
    with %{} = admin <- Account.find_admin(email),
         true <- Account.check_password(admin, password),
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

  def check_document(_root, %{exporter_uid: exporter_uid}, _context) do
    Account.get_exporter_by_exporter_uid(exporter_uid)
    |> Account.check_document()
  end

  def check_document(_root, %{transaction_uid: transaction_uid}, _context) do
    Credit.get_transaction_by_transaction_uid(transaction_uid)
    |> Account.check_document()
  end

  def sign_msa_url(_root, %{exporter_uid: exporter_uid}, _context) do
    {:ok, %{hellosign_signature_request_id: signature_request_id}} =
      Account.get_exporter_by_exporter_uid(exporter_uid)

    {:ok,
     %{
       url:
         Routes.hellosign_url(TransigoAdminWeb.Endpoint, :index,
           token: TransigoAdminWeb.Tokenizer.encrypt(signature_request_id)
         )
     }}
  end

  def sign_docs_url(_root, %{transaction_uid: transaction_uid}, _context) do
    {:ok, %{hellosign_signature_request_id: signature_request_id}} =
      Credit.get_transaction_by_transaction_uid(transaction_uid)

    {:ok,
     %{
       url:
         Routes.hellosign_url(TransigoAdminWeb.Endpoint, :index,
           token: TransigoAdminWeb.Tokenizer.encrypt(signature_request_id)
         )
     }}
  end
end
