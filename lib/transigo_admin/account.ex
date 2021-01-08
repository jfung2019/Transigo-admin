defmodule TransigoAdmin.Account do
  import Ecto.Query, warn: false

  alias TransigoAdmin.Repo
  alias TransigoAdmin.Account.{User, Exporter}

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user!(id), do: Repo.get!(User, id)

  def find_user(email) do
    from(u in User, where: u.email == ^email)
    |> Repo.one()
  end

  def list_awaiting_signature_exporter() do
    from(e in Exporter, where: e.hs_signing_status != "all signed")
    |> Repo.all()
  end

  def get_exporter!(id), do: Repo.get!(Exporter, id)

  def get_signing_url(signature_request_id) do
    case get_signature_request(signature_request_id) do
      {:ok, signature_request} ->
        %{"signature_request" => %{"signatures" => signatures}} = signature_request

        case get_transigo_signature(signatures) do
          %{"signature_id" => transigo_signature_id} ->
            case get_sign_url(transigo_signature_id) do
              {:ok, embedded} ->
                %{"embedded" => %{"sign_url" => sign_url}} = embedded
                {:ok, sign_url}

              {:error, _error} = error_tuple ->
                error_tuple
            end
          _ -> {:error, "Fail to get signature id"}
        end

      {:error, _error} = error_tuple ->
        error_tuple
    end
  end

  defp get_signature_request(signature_request_id) do
    {:ok, response} =
      HTTPoison.get(
        "https://api.hellosign.com/v3/signature_request/#{signature_request_id}",
        [],
        hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]
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
    {:ok, response} =
      HTTPoison.get(
        "https://api.hellosign.com/v3/embedded/sign_url/#{signature_id}",
        [],
        hackney: [basic_auth: {Application.get_env(:transigo_admin, :hs_api_key), ""}]
      )

    %{body: body} = response

    case Jason.decode!(body) do
      %{"error" => error} ->
        {:error, error}

      signature_request ->
        {:ok, signature_request}
    end
  end

  defp get_transigo_signature(signatures) do
    Enum.flat_map(signatures, fn %{"signer_email_address" => email} = signature ->
      case email do
        "nir.tal@transigo.io" -> signature
        _ -> []
      end
    end)
    |> Enum.into(%{})
  end
end
