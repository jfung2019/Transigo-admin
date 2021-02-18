defmodule TransigoAdmin.ServiceManager.Util.UtilBehavior do
  @callback get_message_uid :: String.t() | {:error, HTTPoison.Error.t()}
end
