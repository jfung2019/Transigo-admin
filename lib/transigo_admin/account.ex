defmodule TransigoAdmin.Account do
  import Ecto.Query, warn: false

  alias TransigoAdmin.Repo

  alias TransigoAdmin.Account.{
    Admin,
    Exporter,
    Importer,
    Contact,
    User,
    WebhookEvent,
    WebhookUserEvent
  }

  @dwolla_api Application.compile_env(:transigo_admin, :dwolla_api)

  def create_admin(attrs \\ %{}) do
    %Admin{}
    |> Admin.changeset(attrs)
    |> Repo.insert()
  end

  def get_admin!(id), do: Repo.get!(Admin, id)

  def find_admin(email) do
    from(a in Admin, where: a.email == ^email)
    |> Repo.one()
  end

  def list_awaiting_signature_exporter() do
    from(e in Exporter, where: e.hs_signing_status != "all signed")
    |> Repo.all()
  end

  def get_exporter!(id), do: Repo.get!(Exporter, id)

  def create_exporter(attrs \\ %{}) do
    %Exporter{}
    |> Exporter.changeset(attrs)
    |> Repo.insert()
  end

  def delete_exporter(%Exporter{} = exporter), do: Repo.delete(exporter)

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

          _ ->
            {:error, "Fail to get signature id"}
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

  def get_contact_by_importer(importer_id) do
    from(
      c in Contact,
      left_join: i in Importer,
      on: i.contact_id == c.id,
      where: i.id == ^importer_id
    )
    |> Repo.one()
  end

  def get_contact!(id), do: Repo.get!(Contact, id)

  def create_contact(attrs \\ %{}) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert()
  end

  def delete_contact(%Contact{} = contact), do: Repo.delete(contact)

  def address_states do
    ["AK", "AL", "AR", "AS", "AZ", "CA", "CO", "CT", "DC", "DE", "FL",
      "GA", "GU", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA",
      "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH",
      "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "PR", "RI", "SC",
      "SD", "TN", "TX", "UT", "VA", "VI", "VT", "WA", "WI", "WV", "WY"]
  end

  def create_importer(attrs \\ %{}) do
    %Importer{}
    |> Importer.changeset(attrs)
    |> Repo.insert()
  end

  def update_importer(importer, attrs \\ %{}) do
    importer
    |> Importer.changeset(attrs)
    |> Repo.update()
  end

  def delete_importer(%Importer{} = importer), do: Repo.delete(importer)

  def get_importer!(id), do: Repo.get!(Importer, id)

  def list_importer_with_pending_eh_job() do
    from(i in Importer, where: not is_nil(i.eh_grade_job_url) and is_nil(i.eh_grade))
    |> Repo.all()
  end

  def importer_business_types do
    [
      {"Sole Proprietorship", "soleProprietorship"},
      {"Corporation", "corporation"},
      {"Limited Liability Company", "llc"},
      {"Partnership", "partnership"}
    ]
  end

  def importer_business_classifications do
    {:ok, access_token} = @dwolla_api.dwolla_auth()
    []
  end

  def list_users, do: Repo.all(User)

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(user, attrs \\ %{}) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def get_user!(id), do: Repo.get!(User, id)

  def list_oban_jobs() do
    from(oj in Oban.Job, order_by: [desc: oj.inserted_at])
    |> Repo.all()
  end

  def create_webhook_event(attrs \\ %{}) do
    %WebhookEvent{}
    |> WebhookEvent.changeset(attrs)
    |> Repo.insert()
  end

  def list_webhook_user_event_by_state(state, preloads \\ [:webhook_event, :user]) do
    from(wue in WebhookUserEvent, where: wue.state == ^state, preload: ^preloads)
    |> Repo.all()
  end

  def create_webhook_user_event(attrs \\ %{}) do
    %WebhookUserEvent{}
    |> WebhookUserEvent.changeset(attrs)
    |> Repo.insert()
  end

  def update_webhook_user_event(webhook_user_event, attrs \\ %{}) do
    webhook_user_event
    |> WebhookUserEvent.changeset(attrs)
    |> Repo.update()
  end
end
