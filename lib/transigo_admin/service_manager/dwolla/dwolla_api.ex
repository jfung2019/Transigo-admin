defmodule TransigoAdmin.ServiceManager.Dwolla.DwollaApi do
  @behaviour TransigoAdmin.ServiceManager.Dwolla.DwollaApiBehavior

  def dwolla_auth() do
    url = "#{Application.get_env(:transigo_admin, :dwolla_root_url)}/token"

    client_id = Application.get_env(:transigo_admin, :dwolla_client_id)
    client_secret = Application.get_env(:transigo_admin, :dwolla_client_secret)

    base64_token =
      "#{client_id}:#{client_secret}"
      |> Base.encode64()

    basic_auth_token = "Basic #{base64_token}"

    payload = {:form, [{"grant_type", "client_credentials"}]}

    response =
      HTTPoison.post(url, payload, [
        {"Content-Type", "application/x-www-form-urlencoded"},
        {"Authorization", basic_auth_token}
      ])

    case response do
      {:ok, %{body: body}} ->
        %{"access_token" => access_token} = Jason.decode!(body)

        {:ok, access_token}

      {:error, _} = error_tuple ->
        error_tuple
    end
  end

  def dwolla_post(path, access_token, body) do
    url = "#{Application.get_env(:transigo_admin, :dwolla_root_url)}/#{path}"
    payload = Jason.encode!(body)

    HTTPoison.post(url, payload, [
      {"Accept", "application/vnd.dwolla.v1.hal+json"},
      {"Content-Type", "application/vnd.dwolla.v1.hal+json"},
      {"Authorization", "Bearer #{access_token}"}
    ])
  end

  def dwolla_get(url, access_token) do
    HTTPoison.get(url, [
      {"Accept", "application/vnd.dwolla.v1.hal+json"},
      {"Authorization", "Bearer #{access_token}"}
    ])
  end
end
