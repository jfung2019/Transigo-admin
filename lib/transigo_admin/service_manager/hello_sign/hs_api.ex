defmodule TransigoAdmin.ServiceManager.HelloSign.HsApi do
  @behaviour TransigoAdmin.ServiceManager.HelloSign.HsBehavior

  def get_signature_request(signature_request_id) do
    response =
      HTTPoison.get(
        "https://api.hellosign.com/v3/signature_request/#{signature_request_id}",
        [],
        hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]
      )

    case response do
      {:ok, %{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"error" => error}} ->
            {:error, error}

          {:ok, signature_request} ->
            {:ok, signature_request}

          _ ->
            {:error, "Fail to get signature request"}
        end

      _ ->
        {:error, "Fail to get signature request"}
    end
  end

  def get_sign_url(signature_id) do
    response =
      HTTPoison.get(
        "https://api.hellosign.com/v3/embedded/sign_url/#{signature_id}",
        [],
        hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]
      )

    case response do
      {:ok, %{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"error" => error}} ->
            {:error, error}

          {:ok, sign_url} ->
            {:ok, sign_url}

          _ ->
            {:error, "Fail to get sign url"}
        end

      _ ->
        {:error, "Fail to get sign url"}
    end
  end

  def create_signature_request(payload) do
    response =
      HTTPoison.post(
        "https://api.hellosign.com/v3/signature_request/create_embedded",
        {:multipart, payload},
        [],
        hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]
      )

    case response do
      {:ok, %{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"error" => error}} ->
            {:error, error}

          {:ok, signature_request} ->
            {:ok, signature_request}

          _error ->
            {:error, "Fail to create signature request"}
        end

      _error ->
        {:error, "Fail to create signature request"}
    end
  end
end
