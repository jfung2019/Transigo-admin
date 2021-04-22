defmodule TransigoAdmin.ServiceManager.Util.UtilBehavior do
  @callback get_message_uid :: String.t() | {:error, HTTPoison.Error.t()}

  @callback create_importer(map()) ::
              {:ok,
               HTTPoison.Response.t() | HTTPoison.AsyncResponse.t() | HTTPoison.MaybeRedirect.t()}
              | {:error, HTTPoison.Error.t()}

  @callback generate_assignment_notice(map(), String.t()) :: {:ok, String.t()} | {:errror, any()}
end
