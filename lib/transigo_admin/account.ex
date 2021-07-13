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
  @util_api Application.compile_env(:transigo_admin, :util_api)

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
  @spec check_password(Admin.t(), String.t()) :: boolean
  def check_password(nil, _password), do: no_user_verify()

  def check_password(admin, password), do: verify_pass(password, admin.password_hash)

  @doc """
  verify totp for admin
  """
  @spec validate_totp(Admin.t(), String.t()) :: atom
  def validate_totp(%{totp_secret: secret}, totp) do
    case NimbleTOTP.valid?(secret, totp) do
      true -> :valid
      _ -> :invalid
    end
  end

  @doc """
  generate totp secret and save to admin
  return uri if successful
  """
  @spec generate_totp_secret(Admin.t()) :: {:ok, String.t()} | {:error, any}
  def generate_totp_secret(%Admin{} = admin) do
    admin
    |> Admin.totp_secret_changeset()
    |> Repo.update()
    |> then(fn result ->
      case result do
        {:ok, admin} -> get_totp_uri(admin)
        result -> result
      end
    end)
  end

  @doc """
  get totp uri
  """
  @spec generate_totp_secret(Admin.t()) :: {:ok, String.t()}
  def get_totp_uri(%{totp_secret: secret, username: username}),
    do: {:ok, NimbleTOTP.otpauth_uri("Transigo:#{username}", secret, issuer: "Transigo")}

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
  @spec get_exporter_by_exporter_uid(String.t(), list) :: Exporter.t() | nil
  def get_exporter_by_exporter_uid(exporter_uid, preloads \\ []) do
    from(e in Exporter, where: e.exporter_transigo_uid == ^exporter_uid, preload: ^preloads)
    |> Repo.one()
  end

  @doc """
  generate msa or get sign url of generated msa
  """
  @spec sign_msa(String.t(), bool) :: {:ok, String.t()} | {:error, any}
  def sign_msa(exporter_uid, cn_msa) do
    preloads = [:contact, :marketplace]

    case get_exporter_by_exporter_uid(exporter_uid, preloads) do
      %Exporter{hellosign_signature_request_id: nil} = exporter ->
        generate_sign_msa(exporter, cn_msa)

      %Exporter{hellosign_signature_request_id: hs_sign_req_id} = exporter ->
        get_sign_msa_url_with_req_id(hs_sign_req_id, exporter)

      _ ->
        {:error, "Incorrect exporter_uid"}
    end
  end

  defp generate_sign_msa(exporter, cn_msa) do
    with {:ok, msa_payload} <- get_msa_payload(exporter, cn_msa),
         {:ok, msa_path} <- @util_api.generate_exporter_msa(msa_payload),
         {:ok, msa_hs_payload} <- get_msa_hs_payload(msa_path, exporter),
         {:ok, %{"signature_request" => %{"signature_request_id" => req_id}} = sign_req} <-
           @hs_api.create_signature_request(msa_hs_payload),
         {:ok, _exporter} <-
           update_exporter(exporter, %{cn_msa: cn_msa, hellosign_signature_request_id: req_id}) do
      get_msa_sign_url(sign_req, exporter)
    else
      {:error, _message} = error_tuple ->
        error_tuple

      _ ->
        {:error, "Failed to get MSA"}
    end
  end

  defp get_sign_msa_url_with_req_id(hs_sign_req_id, exporter) do
    case @hs_api.get_signature_request(hs_sign_req_id) do
      {:ok, sign_req} ->
        get_msa_sign_url(sign_req, exporter)

      {:error, _message} = error_tuple ->
        error_tuple

      _ ->
        {:error, "Failed to get msa"}
    end
  end

  @spec get_msa_payload(Exporter.t(), boolean) :: {:ok, list}
  def get_msa_payload(%{contact: contact, marketplace: marketplace} = exporter, cn_msa) do
    now = Timex.now() |> Timex.format!("{ISOdate}")

    payload = [
      {"marketplace", marketplace.marketplace},
      {"document_signature_date", now},
      {"fname", "#{exporter.exporter_transigo_uid}_msa"},
      {"tags", "true"},
      {"exporter",
       Jason.encode!(%{
         MSA_date: now,
         address: exporter.address,
         company_name: exporter.business_name,
         contact: "#{contact.first_name} #{contact.last_name}",
         email: contact.email,
         phone: contact.mobile,
         title: contact.role,
         signatory_email: exporter.signatory_email,
         signatory_name: "#{exporter.signatory_first_name} #{exporter.signatory_last_name}",
         signatory_title: exporter.signatory_title
       })},
      {"transigo", TransigoAdmin.Job.Helper.get_transigo_doc_info()},
      {"cn", get_cn_tag(cn_msa)}
    ]

    {:ok, payload}
  end

  defp get_cn_tag("true"), do: "true"

  defp get_cn_tag(true), do: "true"

  defp get_cn_tag(_), do: "false"

  @spec get_msa_hs_payload(String.t(), Exporter.t()) :: {:ok, list}
  defp get_msa_hs_payload(msa_path, exporter) do
    msa_basename = Path.basename(msa_path)

    payload = [
      {"client_id", Application.get_env(:transigo_admin, :hs_client_id)},
      {"test_mode", "1"},
      {"use_text_tags", "1"},
      {"hide_text_tags", "1"},
      {:file, msa_path, {"form-data", [name: "file[0]", filename: msa_basename]}, []},
      {"signers[0][name]", "Nir Tal"},
      {"signers[0][email_address]", "nir.tal@transigo.io"},
      {"signers[1][name]", "#{exporter.signatory_first_name} #{exporter.signatory_last_name}"},
      {"signers[1][email_address]", exporter.signatory_email}
    ]

    {:ok, payload}
  end

  @spec get_msa_sign_url(map, Exporter.t()) :: String.t()
  defp get_msa_sign_url(%{"signature_request" => %{"signatures" => signatures}}, %{
         signatory_email: exporter_email
       }) do
    sign_url =
      Enum.flat_map(signatures, fn %{"signer_email_address" => email, "signature_id" => sign_id} ->
        case email do
          ^exporter_email -> %{msa_url: @hs_api.fetch_sign_url(sign_id)}
          _ -> []
        end
      end)
      |> Enum.into(%{})

    {:ok, sign_url}
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
