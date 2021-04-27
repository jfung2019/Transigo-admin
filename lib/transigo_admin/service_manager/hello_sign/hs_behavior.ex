defmodule TransigoAdmin.ServiceManager.HelloSign.HsBehavior do
  alias TransigoAdmin.Account.Exporter

  @callback get_signature_request(String.t()) :: {:ok, map()} | {:error, any()}

  @callback get_sign_url(String.t()) :: {:ok, map()} | {:error, any()}

  @callback create_signature_request(String.t(), Exporter.t()) :: {:ok, map()} | {:error, any()}
end
