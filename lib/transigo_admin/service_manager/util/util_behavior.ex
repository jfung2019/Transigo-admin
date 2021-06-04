defmodule TransigoAdmin.ServiceManager.Util.UtilBehavior do
  @callback get_uid(String.t()) :: String.t() | {:error, HTTPoison.Error.t()}

  @callback create_importer(map()) ::
              {:ok,
               HTTPoison.Response.t() | HTTPoison.AsyncResponse.t() | HTTPoison.MaybeRedirect.t()}
              | {:error, HTTPoison.Error.t()}

  @callback generate_assignment_notice([tuple()]) ::
              {:ok, String.t()} | {:errror, any()}

  @callback generate_exporter_msa([tuple()]) ::
              {:ok, String.t()} | {:errror, any()}

  @callback generate_transaction_doc([tuple()]) ::
              {:ok, String.t()} | {:error, any()}
end
