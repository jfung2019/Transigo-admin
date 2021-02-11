defmodule TransigoAdmin.ServiceManager.Dwolla.DwollaApiMock do
  @behaviour TransigoAdmin.ServiceManager.Dwolla.DwollaApiBehavior

  @mock_access_token "valid_token"
  @mock_source "http://dwolla.com/funding-sources/id"
  @mock_transfer "http://dwolla.com/transfers/id"
  @mock_source_repaid "http://dwolla.com/funding-sources/id/repaid"
  @mock_transfer_repaid "http://dwolla.com/transfers/id/repaid"

  def dwolla_auth(), do: {:ok, @mock_access_token}

  def dwolla_post("transfers", _token, %{_links: %{source: %{href: @mock_source}}}),
    do: {:ok, %HTTPoison.Response{headers: [{"Location", @mock_transfer}], body: ""}}

  def dwolla_post("transfers", _token, %{_links: %{source: %{href: @mock_source_repaid}}}),
      do: {:ok, %HTTPoison.Response{headers: [{"Location", @mock_transfer_repaid}], body: ""}}

  def dwolla_post(_path, _token, _payload), do: {:ok, %HTTPoison.Response{body: ""}}

  def dwolla_get(@mock_transfer_repaid, _token), do:
    {:ok, %HTTPoison.Response{body: Jason.encode!(%{"status" => "processed"})}}

  def dwolla_get(_url, _token), do: {:ok, %HTTPoison.Response{body: ""}}
end
