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

  def fetch_sign_url(sign_id) do
    {:ok, %{"embedded" => %{"sign_url" => sign_url}}} = get_sign_url(sign_id)
    "#{sign_url}&client_id=#{Application.get_env(:transigo_admin, :hs_client_id)}"
  end

  def get_signature_file_url(signature_request_id) do
    HTTPoison.get(
      "https://api.hellosign.com/v3/signature_request/files/#{signature_request_id}?file_type=pdf&get_url=true",
      [],
      hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]
    )
    |> then(fn response ->
      with {:ok, %{body: body}} <- response, {:ok, %{"file_url" => file_url}} <- Jason.decode(body) do
        {:ok, file_url}
      else
        _ ->
          {:error, "failed to get file url"}
      end
    end)
  end
end
