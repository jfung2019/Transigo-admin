defmodule TransigoAdmin.ServiceManager.EulerHermes.EhApi do
  @behaviour TransigoAdmin.ServiceManager.EulerHermes.EhApiBehavior

  def eh_auth() do
    auth_url = "#{Application.get_env(:transigo_admin, :eh_auth_url)}/oauth2/authorize"
    body_json = %{apiKey: Application.get_env(:transigo_admin, :eh_api_key)} |> Jason.encode!()

    case HTTPoison.post(auth_url, body_json, [{"Content-Type", "application/json"}]) do
      {:ok, %{body: body}} ->
        %{"access_token" => access_token} = Jason.decode!(body)
        {:ok, access_token}

      {:error, _} = error_tuple ->
        error_tuple
    end
  end

  def eh_get(url, access_token) do
    HTTPoison.get(url, [{"Authorization", "Bearer #{access_token}"}])
  end
end
