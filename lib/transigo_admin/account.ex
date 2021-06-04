defmodule TransigoAdmin.Account do
  import Ecto.Query, warn: false
  import Argon2, only: [verify_pass: 2, no_user_verify: 0]

  alias TransigoAdmin.Repo
  alias Absinthe.Relay

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
  @hs_api Application.compile_env(:transigo_admin, :hs_api)

  @states_list Code.eval_string("""
                 [
                   "AK", "AL", "AR", "AS", "AZ", "CA", "CO", "CT", "DC", "DE", "FL",
                   "GA", "GU", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA",
                   "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH",
                   "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "PR", "RI", "SC",
                   "SD", "TN", "TX", "UT", "VA", "VI", "VT", "WA", "WI", "WV", "WY"
                 ]
               """)
               |> elem(0)
  @doc """
  create admin for accessing kaffy and admin app
  """
  @spec create_admin(map) :: {:ok, Admin.t()} | {:error, %Ecto.Changeset{}}
  def create_admin(attrs \\ %{}) do
    %Admin{}
    |> Admin.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  get admin by id
  """
  @spec get_admin!(String.t()) :: Admin.t()
  def get_admin!(id), do: Repo.get!(Admin, id)

  @doc """
  find admin by email
  """
  @spec find_admin(String.t()) :: Admin.t() | nil
  def find_admin(email) do
    from(a in Admin, where: a.email == ^email)
    |> Repo.one()
  end

  @doc """
  check if the given password and the saved password are the same
  """
  @spec check_password(Admin.t(), Stirng.t()) :: boolean
  def check_password(nil, _password), do: no_user_verify()

  def check_password(admin, password), do: verify_pass(password, admin.password_hash)

  @doc """
  Get all exporters with MSA not signed by both parties
  """
  @spec list_awaiting_signature_exporter :: [Exporter.t()]
  def list_awaiting_signature_exporter() do
    from(e in Exporter, where: e.hs_signing_status != "all_signed")
    |> Repo.all()
  end

  @doc """
  Get all exporters with MSA unsigned but has generated HelloSign signature request
  """
  @spec list_unsigned_exporters :: [Exporter.t()]
  def list_unsigned_exporters() do
    from(e in Exporter,
      where: e.hs_signing_status != "all_signed" and not is_nil(e.hellosign_signature_request_id),
      preload: [:marketplace, :contact]
    )
    |> Repo.all()
  end

  @doc """
  Get exporter by id
  """
  @spec get_exporter!(String.t()) :: Exporter.t()
  def get_exporter!(id), do: Repo.get!(Exporter, id)

  @doc """
  list exporters with pagination
  """
  @spec list_exporters_paginated(map) :: {:ok, map}
  def list_exporters_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"
    hs_status = "%#{Map.get(pagination_args, :hs_signing_status)}%"

    from(e in Exporter,
      where: ilike(e.business_name, ^keyword) and ilike(e.hs_signing_status, ^hs_status)
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  @doc """
  Create exporter
  """
  @spec create_exporter(map) :: {:ok, Exporter.t()} | {:error, %Ecto.Changeset{}}
  def create_exporter(attrs \\ %{}) do
    %Exporter{}
    |> Exporter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update exporter
  """
  @spec update_exporter(Exporter.t(), map) :: {:ok, Exporter.t()} | {:error, %Ecto.Changeset{}}
  def update_exporter(exporter, attrs \\ %{}) do
    exporter
    |> Exporter.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Get exporter by exporter_transigo_uid
  """
  @spec get_exporter_by_exporter_uid(String.t()) :: Exporter.t() | nil
  def get_exporter_by_exporter_uid(exporter_uid) do
    from(e in Exporter, where: e.exporter_transigo_uid == ^exporter_uid)
    |> Repo.one()
  end

  @doc """
  get signing url for Transigo
  """
  @spec get_signing_url(String.t()) :: {:ok, String.t()} | {:error, any}
  def get_signing_url(signature_request_id) do
    case @hs_api.get_signature_request(signature_request_id) do
      {:ok, %{"signature_request" => %{"signatures" => signatures}}} ->
        case get_transigo_signature(signatures) do
          %{"signature_id" => transigo_signature_id} ->
            case @hs_api.get_sign_url(transigo_signature_id) do
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

  @spec get_transigo_signature(map) :: map
  defp get_transigo_signature(signatures) do
    Enum.flat_map(signatures, fn %{"signer_email_address" => email} = signature ->
      case email do
        "nir.tal@transigo.io" -> signature
        _ -> []
      end
    end)
    |> Enum.into(%{})
  end

  @doc """
  Get contact by importer_id
  """
  @spec get_contact_by_importer(String.t()) :: Contact.t() | nil
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

  def address_states, do: @states_list

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

  @doc """
  List all importers with pagination
  """
  @spec list_importers_paginated(map) :: {:ok, map}
  def list_importers_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"

    from(i in Importer, where: ilike(i.business_name, ^keyword))
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  def importer_business_types do
    [
      {"Sole Proprietorship", "soleProprietorship"},
      {"Corporation", "corporation"},
      {"Limited Liability Company", "llc"},
      {"Partnership", "partnership"}
    ]
  end

  @doc """
  Get business_classification from dwolla
  """
  @spec importer_business_classifications :: [map]
  def importer_business_classifications do
    {:ok, access_token} = @dwolla_api.dwolla_auth()
    url = "#{Application.get_env(:transigo_admin, :dwolla_root_url)}/business-classifications"
    {:ok, %{body: body}} = @dwolla_api.dwolla_get(url, access_token)
    %{"_embedded" => %{"business-classifications" => classifications}} = Jason.decode!(body)

    classifications
    |> Enum.map(fn %{"_embedded" => %{"industry-classifications" => items}} ->
      items
      |> Enum.map(fn %{"id" => id, "name" => name} ->
        {name, id}
      end)
    end)
    |> Enum.reduce(fn x, acc -> acc ++ x end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  def list_users, do: Repo.all(User)

  def get_importer_by_importer_uid(importer_uid) do
    from(i in Importer, where: i.importer_transigo_uid == ^importer_uid)
    |> Repo.one()
  end

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

  @doc """
  list webhook_user_event by state
  """
  @spec list_webhook_user_event_by_state(String.t(), [atom]) :: [WebhookUserEvent.t()]
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

  def get_token_id(token) do
    from(t in "tokens",
      where: t.access_token == ^token,
      select: t.id
    )
    |> Repo.one()
  end

  def datasource, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(queryable, _), do: queryable
end
