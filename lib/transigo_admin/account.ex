defmodule TransigoAdmin.Account do

  import Ecto.Query, warn: false

  alias TransigoAdmin.Repo
  alias TransigoAdmin.Account.{User, Exporter}

  def list_awaiting_signature_exporter() do
    from(e in Exporter, where: e.hs_signing_status != "all signed")
    |> Repo.all()
  end

  def get_exporter!(id), do: Repo.get!(Exporter, id)

  def get_exporter_signing_url(id) do
    exporter = Repo.get!(Exporter, id)
    case get_signature_request(exporter.hellosign_signature_request_id) do
      {:ok, signature_request} ->
        %{"signature_request" => %{"signatures" => signatures}} = signature_request
        [_, %{"signer_email_address" => "nir.tal@transigo.io", "signature_id" => transigo_signature_id}] = signatures
        case get_sign_url(transigo_signature_id) do
          {:ok, embedded} ->
            %{"embedded" => %{"sign_url" => sign_url}} = embedded
            sign_url

          {:error, error} ->
            error
        end

      {:error, error} ->
        error
    end
  end

  defp get_signature_request(signature_request_id) do
    {:ok, response} = HTTPoison.get(
      "https://api.hellosign.com/v3/signature_request/#{signature_request_id}",
      [],
      [hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]]
    )
    %{body: body} = response
    case Jason.decode!(body) do
      %{"error" => error} ->
        {:error, error}

      signature_request ->
        {:ok, signature_request}
    end
  end

  defp get_sign_url(signature_id) do
    {:ok, response} = HTTPoison.get(
      "https://api.hellosign.com/v3/embedded/sign_url/#{signature_id}",
      [],
      [hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]]
    )
    %{body: body} = response
    case Jason.decode!(body) do
      %{"error" => error} ->
        {:error, error}

      signature_request ->
        {:ok, signature_request}
    end
  end
end