defmodule TransigoAdmin.ServiceManager.HelloSign.HsApi do
  @behaviour TransigoAdmin.ServiceManager.HelloSign.HsBehavior

  def get_signature_request(signature_request_id) do
    {:ok, %{body: body}} =
      HTTPoison.get(
        "https://api.hellosign.com/v3/signature_request/#{signature_request_id}",
        [],
        hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]
      )

    case Jason.decode(body) do
      {:ok, %{"error" => error}} ->
        {:error, error}

      {:ok, signature_request} ->
        {:ok, signature_request}

      _ ->
        {:error, "Fail to get signature request"}
    end
  end

  def get_sign_url(signature_id) do
    {:ok, %{body: body}} =
      HTTPoison.get(
        "https://api.hellosign.com/v3/embedded/sign_url/#{signature_id}",
        [],
        hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]
      )

    case Jason.decode(body) do
      {:ok, %{"error" => error}} ->
        {:error, error}

      {:ok, sign_url} ->
        {:ok, sign_url}

      _ ->
        {:error, "Fail to get sign url"}
    end
  end
end
