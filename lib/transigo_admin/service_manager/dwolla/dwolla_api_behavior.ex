defmodule TransigoAdmin.ServiceManager.Dwolla.DwollaApiBehavior do
  @callback dwolla_auth() :: {:ok, String.t()} | {:error, HTTPoison.Error.t()}
  @callback dwolla_post(String.t(), String.t(), map()) ::
              {:ok,
               HTTPoison.Response.t() | HTTPoison.AsyncResponse.t() | HTTPoison.MaybeRedirect.t()}
              | {:error, HTTPoison.Error.t()}
  @callback dwolla_get(String.t(), String.t()) ::
              {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
              | {:error, HTTPoison.Error.t()}
end
