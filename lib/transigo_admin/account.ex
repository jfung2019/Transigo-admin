defmodule TransigoAdmin.Account do
  import Ecto.Query, warn: false
  import Argon2, only: [verify_pass: 2, no_user_verify: 0]

  alias TransigoAdmin.Repo
  alias Absinthe.Relay
  alias TransigoAdminWeb.Router.Helpers, as: Routes
  alias TransigoAdminWeb.Endpoint
  alias Ecto.Multi
  alias TransigoAdmin.DataLayer
  alias TransigoAdmin.Credit.Marketplace
  alias TransigoAdmin.Credit.Quota

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
  @spec get_totp_uri(Admin.t()) :: {:ok, String.t()}
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
    marketplace =
      from(m in Marketplace,
        where: m.origin == ^attrs["marketplaceOrigin"]
      )
      |> Repo.one()

    if not is_nil(marketplace) do
      contact =
        attrs
        |> get_exporter_contact_from_params()
        |> Map.put(:contact_transigo_uid, DataLayer.generate_uid("con"))

      exporter =
        attrs
        |> get_exporter_from_params()
        |> Map.put(:exporter_transigo_uid, DataLayer.generate_uid("exp"))
        |> Map.put(:marketplace_id, marketplace.id)

      Multi.new()
      |> Multi.insert(Contact, Contact.changeset(%Contact{}, contact))
      |> Multi.insert(
        Exporter,
        fn %{
             Contact => %Contact{
               id: contact_id
             }
           } ->
          Exporter.changeset(
            %Exporter{},
            exporter
            |> Map.put(:contact_id, contact_id)
          )
        end
      )
      |> Repo.transaction()
    else
      {:error, "Could not insert exporter"}
    end
  end

  defp get_exporter_params(params) do
    %{
      business_name: Map.get(params, "businessName"),
      address: Map.get(params, "address"),
      business_address_country: Map.get(params, "businessAddressCountry"),
      registration_number: Map.get(params, "registrationNumber"),
      signatory_first_name: Map.get(params, "signatoryFirstName"),
      signatory_last_name: Map.get(params, "signatoryLastName"),
      signatory_mobile: Map.get(params, "signatoryMobile"),
      signatory_email: Map.get(params, "signatoryEmail"),
      signatory_title: Map.get(params, "signatoryTitle")
    }
  end

  defp get_exporter_from_params(%{
         "businessName" => business_name,
         "address" => address,
         "businessAddressCountry" => business_address_country,
         "registrationNumber" => registration_number,
         "signatoryFirstName" => signatory_first_name,
         "signatoryLastName" => signatory_last_name,
         "signatoryMobile" => signatory_mobile,
         "signatoryEmail" => signatory_email,
         "signatoryTitle" => signatory_title
       }) do
    %{
      business_name: business_name,
      address: address,
      business_address_country: business_address_country,
      registration_number: registration_number,
      signatory_first_name: signatory_first_name,
      signatory_last_name: signatory_last_name,
      signatory_mobile: signatory_mobile,
      signatory_email: signatory_email,
      signatory_title: signatory_title
    }
  end

  defp get_contact_params(params) do
    %{
      first_name: Map.get(params, "contactFirstName"),
      last_name: Map.get(params, "contactLastName"),
      mobile: Map.get(params, "contacMobile"),
      work_phone: Map.get(params, "workPhone"),
      email: Map.get(params, "contactEmail"),
      role: Map.get(params, "contactTitle"),
      address: Map.get(params, "contactAddress")
    }
  end

  defp get_exporter_contact_from_params(%{
         "contactFirstName" => first_name,
         "contactLastName" => last_name,
         "contactMobile" => mobile,
         "workPhone" => work_phone,
         "contactEmail" => email,
         "contactTitle" => role,
         "contactAddress" => address
       }) do
    %{
      first_name: first_name,
      last_name: last_name,
      mobile: mobile,
      work_phone: work_phone,
      email: email,
      role: role,
      address: address
    }
  end

  @doc """
  Update exporter
  """
  def update_exporter(%{"exporter_transigo_uid" => uid} = attrs) do
    with {:ok, exporter} <- get_exporter_by_exporter_uid(uid, [:contact]) do
      contact_attrs =
        attrs
        |> get_contact_params()

      exporter_attrs =
        attrs
        |> get_exporter_params()

      Multi.new()
      |> Multi.update(Exporter, Exporter.update_changeset(exporter, exporter_attrs))
      |> Multi.update(Contact, Contact.update_changeset(exporter.contact, contact_attrs))
      |> Repo.transaction()
    else
      _ -> {:error, "Could not update exporter"}
    end
  end

  @doc """
  Get exporter by exporter_transigo_uid
  """
  @spec get_exporter_by_exporter_uid(String.t(), list) :: Exporter.t() | nil
  def get_exporter_by_exporter_uid(exporter_uid, preloads \\ []) do
    if DataLayer.check_uid(exporter_uid, "exp") do
      {:ok,
       from(e in Exporter, where: e.exporter_transigo_uid == ^exporter_uid, preload: ^preloads)
       |> Repo.one()}
    else
      {:error, "Invalid UID"}
    end
  end

  @doc """
  generate msa or get sign url of generated msa
  """
  @spec sign_msa(String.t(), bool) :: {:ok, String.t()} | {:error, any}
  def sign_msa(exporter_uid, cn_msa) do
    preloads = [:contact, :marketplace]

    case get_exporter_by_exporter_uid(exporter_uid, preloads) do
      {:ok, %Exporter{hellosign_signature_request_id: nil} = exporter} ->
        generate_sign_msa(exporter, cn_msa)

      {:ok, %Exporter{hellosign_signature_request_id: hs_sign_req_id} = exporter} ->
        get_sign_msa_url_with_req_id(hs_sign_req_id, exporter)

      _ ->
        {:error, "Incorrect exporter_uid"}
    end
  end

  defp get_s3_bucket do
    Application.get_env(:transigo_admin, :s3_bucket_name)
  end

  def get_msa(%{"exporter_uid" => exporter_uid}) do
    # TODO test this function
    key = "exporter/%{exporter_uid}/#{exporter_uid}_all_signed_msa.pdf"

    if check_obj_exists?(key) do
      {:ok,
       ExAws.Config.new(:s3)
       |> ExAws.S3.presigned_url(:get, get_s3_bucket(), key)}
    else
      {:error, "Object does not exists"}
    end
  end

  def check_obj_exists?(key) do
    # TODO implement this check
    ExAws.S3.get_object(get_s3_bucket(), key)
    true
  end

  @doc """
  get a link to the HelloSign document
  """
  @spec check_document(map) :: tuple
  def check_document(%{hellosign_signature_request_id: nil}),
    do: {:error, message: "document not found"}

  def check_document(%{hellosign_signature_request_id: signature_request_id}) do
    with {:ok, %{"signature_request" => %{"signatures" => signatures}}} <-
           @hs_api.get_signature_request(signature_request_id),
         transigo_signature <- get_transigo_signature(signatures) do
      get_document(transigo_signature, signature_request_id)
    else
      _ -> {:error, message: "failed to fetch signature request"}
    end
  end

  @spec get_document(map, String.t()) :: tuple
  defp get_document(%{"status_code" => "signed"}, signature_request_id) do
    case @hs_api.get_signature_file_url(signature_request_id) do
      {:ok, sign_url} ->
        {:ok, %{url: sign_url}}

      _ ->
        {:error, message: "failed to get file"}
    end
  end

  defp get_document(%{"signature_id" => sign_id}, _sign_request_id),
    do: {:ok, %{url: Routes.hellosign_url(Endpoint, :index, hellosign_signature_id: sign_id)}}

  defp generate_sign_msa(exporter, cn_msa) do
    with {:ok, msa_payload} <- get_msa_payload(exporter, cn_msa),
         {:ok, msa_path} <- @util_api.generate_exporter_msa(msa_payload),
         {:ok, msa_hs_payload} <- get_msa_hs_payload(msa_path, exporter),
         {:ok, %{"signature_request" => %{"signature_request_id" => req_id}} = sign_req} <-
           @hs_api.create_signature_request(msa_hs_payload),
         {:ok, _exporter} <-
           update_exporter_msa(exporter, %{cn_msa: cn_msa, hellosign_signature_request_id: req_id}) do
      get_msa_sign_url(sign_req, exporter)
    else
      {:error, _message} = error_tuple ->
        error_tuple

      _ ->
        {:error, "Failed to get MSA"}
    end
  end

  def update_exporter_msa(exporter, attrs \\ %{}) do
    exporter
    |> Exporter.changeset(attrs)
    |> Repo.update()
  end

  def update_exporter_hs_request(exporter, attrs \\ %{}) do
    exporter
    |> Exporter.changeset(attrs)
    |> Repo.update()
  end

  @spec get_sign_msa_url_with_req_id(String.t(), Exporter.t()) :: tuple
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

  @spec get_cn_tag(any) :: String.t()
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
      {"signers[1][name]", "#{exporter.signatory_first_name} #{exporter.signatory_last_name}"},
      {"signers[1][email_address]", exporter.signatory_email},
      {"signers[2][name]", "Nir Tal"},
      {"signers[2][email_address]", "nir.tal@transigo.io"}
    ]

    {:ok, payload}
  end

  @spec get_msa_sign_url(map, Exporter.t()) :: {:ok, String.t()}
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
    with {:ok, %{"signature_request" => %{"signatures" => signatures}}} <-
           @hs_api.get_signature_request(signature_request_id),
         %{"signature_id" => transigo_signature_id} <- get_transigo_signature(signatures),
         {:ok, %{"embedded" => %{"sign_url" => sign_url}}} <-
           @hs_api.get_sign_url(transigo_signature_id) do
      {:ok, sign_url}
    else
      {:error, _error} = error_tuple ->
        error_tuple

      _ ->
        {:error, "Fail to get sign url"}
    end
  end

  @doc """
  get signing url from signature_id
  """
  @spec get_signing_url_by_sign_id(String.t()) :: tuple
  def get_signing_url_by_sign_id(signature_id) do
    case @hs_api.get_sign_url(signature_id) do
      {:ok, %{"embedded" => %{"sign_url" => sign_url}}} ->
        {:ok, sign_url}

      {:error, _error} = error_tuple ->
        error_tuple

      _ ->
        {:error, "Fail to get sign url"}
    end
  end

  @spec get_transigo_signature([]) :: map
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

  def get_contact_by_id(contact_id, preloads \\ []) do
    from(
      c in Contact,
      where: c.id == ^contact_id,
      preload: ^preloads
    )
    |> Repo.one()
  end

  def get_contact_by_quota_id(quota_id) do
    from(c in Contact,
      join: i in assoc(c, :importer),
      join: q in assoc(i, :quota),
      where: q.id == ^quota_id,
      preload: [:us_place]
    )
    |> Repo.one()
  end

  def insert_contact_consumer_credit_report(
        %Contact{} = contact,
        %{
          consumer_credit_score: _,
          consumer_credit_score_percentile: _,
          consumer_credit_report_meridianlink: _
        } = params
      ) do
    contact
    |> Contact.consumer_credit_changeset(params)
    |> Repo.update()
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

  @spec get_importer!(String.t(), []) :: Importer.t()
  def get_importer!(id, preloads \\ []) do
    from(i in Importer, where: i.id == ^id, preload: ^preloads)
    |> Repo.one!()
  end

  @doc """
  List all importers with pagination
  """
  @spec list_importers_paginated(map) :: {:ok, map}
  def list_importers_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"

    from(i in Importer, where: ilike(i.business_name, ^keyword))
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  @doc """
  business_types for importer
  value for dwolla
  """
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

  @doc """
  get importer by importer_transigoUID
  """
  @spec get_importer_by_importer_uid(String.t()) :: Importer.t() | nil
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

  @doc """
  list all oban jobs and order by inserted at in descending order
  """
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

  @doc """
  check if token exist in database
  """
  @spec get_token_id(String.t()) :: String.t()
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
