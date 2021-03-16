defmodule TransigoAdmin.ServiceManager.Util.UtilMock do
  @behaviour TransigoAdmin.ServiceManager.Util.UtilBehavior

  def get_message_uid, do: "Tmes-1234-abcd-1234-abcd"

  def create_importer(_param), do: {:ok, %HTTPoison.Response{body: ""}}
end
