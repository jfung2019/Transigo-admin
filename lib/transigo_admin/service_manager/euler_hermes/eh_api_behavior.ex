defmodule TransigoAdmin.ServiceManager.EulerHermes.EhApiBehavior do
  @callback eh_auth() :: {:ok, String.t()} | {:error, HTTPoison.Error.t()}
  @callback eh_get(String.t(), String.t()) ::
              {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
              | {:error, HTTPoison.Error.t()}
end
