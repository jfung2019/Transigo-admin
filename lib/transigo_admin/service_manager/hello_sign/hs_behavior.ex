defmodule TransigoAdmin.ServiceManager.HelloSign.HsBehavior do
  @callback get_signature_request(String.t()) :: {:ok, map()} | {:error, any()}

  @callback get_sign_url(String.t()) :: {:ok, map()} | {:error, any()}
end
