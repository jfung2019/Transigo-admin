defmodule TransigoAdmin.Test.Support.Mock.EhApiMock do
  @behaviour TransigoAdmin.ServiceManager.EulerHermes.EhApiBehavior

  def eh_auth(), do: {:ok, "eh_access_token"}

  def eh_get(_url, _access_token), do: {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
end
