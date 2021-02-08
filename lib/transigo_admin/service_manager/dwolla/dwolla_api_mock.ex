defmodule TransigoAdmin.ServiceManager.Dwolla.DwollaApiMock do
  @behaviour TransigoAdmin.ServiceManager.Dwolla.DwollaApiBehavior

  @mock_access_token "valid_token"

  def dwolla_auth(), do: {:ok, @mock_access_token}

  def dwolla_post(_path, _token, _payload), do: {:ok, %HTTPoison.Response{body: ""}}

  def dwolla_get(_url, _token), do: {:ok, %HTTPoison.Response{body: ""}}
end
