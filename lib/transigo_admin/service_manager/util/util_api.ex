defmodule TransigoAdmin.ServiceManager.Util.UtilApi do
  @behaviour TransigoAdmin.ServiceManager.Util.UtilBehavior

  def get_message_uid do
    case HTTPoison.get(Application.get_env(:transigo_admin, :uid_util_url)) do
      {:ok, %{body: message_uid}} -> message_uid
      {:error, _error} = error_tuple -> error_tuple
    end
  end

  def create_importer(importer_param) do
    payload = Jason.encode!(importer_param)

    HTTPoison.post("http://localhost:5000/v2/importers", payload, [
      {"Content-Type", "application/json"}
    ])
  end
end
