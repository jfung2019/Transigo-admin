defmodule TransigoAdmin.Credit do
  import Ecto.Query, warn: false

  alias TransigoAdmin.DataLayer
  alias TransigoAdmin.{Repo, Account}
  alias Absinthe.Relay
  alias TransigoAdmin.Credit.{Transaction, Quota, Marketplace, Offer}

  @hs_api Application.compile_env(:transigo_admin, :hs_api)
  @util_api Application.compile_env(:transigo_admin, :util_api)
  @s3_api Application.compile_env(:transigo_admin, :s3_api)

  @doc """
  List transactions due in 3 days with transaction_state as assigned
  """
  @spec list_transactions_due_in_3_days :: [Transaction.t()]
  def list_transactions_due_in_3_days() do
    from(
      t in Transaction,
      where:
        fragment(
          "(? + make_interval(days => ?))::date = (NOW() + make_interval(days => 3))::date",
          t.invoice_date,
          t.credit_term_days
        ) and t.transaction_state == "assigned"
    )
    |> Repo.all()
  end

  @doc """
  List transactions due today with transaction_state as ["assigned", "email_sent"]
  """
  @spec list_transactions_due_today :: [Transaction.t()]
  def list_transactions_due_today() do
    from(t in Transaction,
      where:
        fragment(
          "(? + make_interval(days => ?))::date <= NOW()::date",
          t.invoice_date,
          t.credit_term_days
        ) and t.transaction_state in ["email_sent", "assigned"]
    )
    |> Repo.all()
  end

  @doc """
  list transaction by state
  """
  @spec list_transactions_by_state(String.t(), [atom]) :: [Transaction.t()]
  def list_transactions_by_state(state, preloads \\ []) do
    from(t in Transaction, where: t.transaction_state == ^state, preload: ^preloads)
    |> Repo.all()
  end

  @doc """
  List transaction with paginated
  """
  @spec list_transactions_paginated(map) :: {:ok, map}
  def list_transactions_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"
    hs_status = "%#{Map.get(pagination_args, :hs_signing_status)}%"
    transaction_status = "%#{Map.get(pagination_args, :transaction_status)}%"

    from(t in Transaction,
      left_join: e in assoc(t, :exporter),
      left_join: i in assoc(t, :importer),
      where:
        (ilike(i.business_name, ^keyword) or ilike(e.business_name, ^keyword)) and
          ilike(t.hs_signing_status, ^hs_status) and
          ilike(t.transaction_state, ^transaction_status)
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  def get_transaction!(id), do: Repo.get!(Transaction, id)

  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def update_transaction(transaction, attrs \\ %{}) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  get transaction by transaction_uid
  """
  @spec get_transaction_by_transaction_uid(String.t(), [atom]) :: Transaction.t()
  def get_transaction_by_transaction_uid(transaction_uid, preloads \\ []) do
    from(t in Transaction, where: t.transaction_uid == ^transaction_uid, preload: ^preloads)
    |> Repo.one()
  end

  @doc """
  Gets marketplace using exported_id.
  """
  @spec get_marketplace_by_exported_id!(String.t()) :: Marketplace.t()
  def get_marketplace_by_exported_id!(exporter_id) do
    from(m in Marketplace, left_join: e in assoc(m, :exporters), where: e.id == ^exporter_id)
    |> Repo.one!()
  end

  @doc """
  rest api
  /trans/:transaction_uid/confirm_downpayment
  confirm downpayement
  """
  @spec confirm_downpayment(String.t(), map) :: {:ok, Transaction.t()} | {:error, any}
  def confirm_downpayment(transaction_uid, params) do
    transaction = get_transaction_by_transaction_uid(transaction_uid)
    downpayment_confirm = Map.get(params, "downpaymentConfirm")
    sum_paid_usd = Map.get(params, "sumPaidusd")

    cond do
      is_nil(downpayment_confirm) ->
        {:error, "downpaymentConfirm missing"}

      is_nil(sum_paid_usd) ->
        {:error, "sumPaidusd missing"}

      is_nil(transaction) ->
        {:error, "Offer not found"}

      transaction.down_payment_usd != sum_paid_usd ->
        {:error, "Downpayment does not match"}

      true ->
        transaction
        |> update_transaction(%{
          transaction_state: "down_payment_done",
          downpayment_confirm: downpayment_confirm,
          down_payment_confirmed_datetime: Timex.now()
        })
    end
  end

  @doc """
  rest api
  /trans/:transaction_uid/sign_tran_docs
  generate transaction document and HelloSign request
  """
  @spec sign_docs(String.t()) :: {:ok, map} | {:error, any}
  def sign_docs(transaction_uid) do
    preloads = [transaction: [exporter: [:contact], importer: [contact: [:us_place]]]]

    case get_offer_by_transaction_uid(transaction_uid, preloads) do
      %Offer{transaction: %{hellosign_signature_request_id: nil}} = offer ->
        generate_sign_doc(offer)

      %Offer{transaction: %{hellosign_signature_request_id: hs_sign_req_id} = transaction} ->
        get_sign_docs_urls_with_req_id(hs_sign_req_id, transaction)

      _ ->
        {:error, "Incorrect transaction_uid"}
    end
  end

  @spec sign_doc_validation(Transaction.t()) :: true | {:error, String.t()}
  defp sign_doc_validation(%{invoice_ref: nil}), do: {:error, "Invoice not found"}

  defp sign_doc_validation(%{po_ref: nil}), do: {:error, "PO not found"}

  defp sign_doc_validation(%{exporter: %{hs_signing_status: status}}) do
    case status do
      "all_signed" ->
        true

      _ ->
        {:error, "Exporter MSA not completed"}
    end
  end

  # get total number of transaction made by importer
  @spec get_transaction_count_of_importer(String.t()) :: Integer
  defp get_transaction_count_of_importer(importer_id) do
    from(
      t in Transaction,
      where: t.importer_id == ^importer_id,
      select: coalesce(count(t.id), 0)
    )
    |> Repo.one!()
  end

  # get pg_cap
  # if this is the first transaction, pg_cap = quota_usd * 2
  @spec calculate_pg_cap(Transaction.t()) :: {:ok, Integer}
  defp calculate_pg_cap(%{importer_id: importer_id}) do
    case get_transaction_count_of_importer(importer_id) do
      1 ->
        %Quota{quota_usd: quota_usd} = find_granted_quota(importer_id)
        {:ok, quota_usd * 2}

      _ ->
        {:ok, 0}
    end
  end

  @spec get_trans_doc_payload(Transaction.t(), Integer, String.t(), String.t()) :: {:ok, [tuple]}
  defp get_trans_doc_payload(
         %{transaction: %{exporter: exporter, importer: importer} = transaction} = offer,
         pg_cap,
         invoice_file,
         po_file
       ) do
    today = Timex.now() |> Date.to_iso8601()
    invoice_file_basename = Path.basename(invoice_file)
    po_file_basename = Path.basename(po_file)
    acc_file_basename = "#{transaction.transaction_uid}_acc.pdf"

    importer_address =
      "#{importer.business_address_street_address}, #{importer.business_address_city}, #{importer.business_address_state}, #{importer.business_address_zip}, #{importer.business_address_country}"

    second_installment_date =
      transaction.invoice_date
      |> Timex.shift(days: transaction.credit_term_days)
      |> Date.to_iso8601()

    est_second_installment_date =
      transaction.po_date
      |> Timex.shift(days: transaction.credit_term_days)
      |> Date.to_iso8601()

    payload = [
      {"financier", "Transigo"},
      {"fname", "#{transaction.transaction_uid}_trans_docs"},
      {"tags", "true"},
      {"pg_cap", pg_cap |> Jason.encode!()},
      {"today_date", today},
      {:file, invoice_file,
       {"form-data", [name: "invoice_file", filename: invoice_file_basename]}, []},
      {:file, po_file, {"form-data", [name: "po_pi_file", filename: po_file_basename]}, []},
      {:file, po_file, {"form-data", [name: "acc_file", filename: acc_file_basename]}, []},
      {"dates",
       Jason.encode!(%{
         assignment_date: today,
         closing_date_AppendixC_date: today,
         exporter_schedA_date: transaction.po_date |> Date.to_iso8601(),
         importer_acceptance_date: today,
         invoice_signing_date: today,
         pi_signing_date: today
       })},
      {"deal",
       Jason.encode!(%{
         credit_invoice_term: transaction.credit_term_days,
         currency: "usd",
         downpayment: transaction.down_payment_usd |> Jason.encode!(),
         est_invoice_date: transaction.invoice_date |> Date.to_iso8601(),
         factoring_fee: offer.importer_fee |> Jason.encode!(),
         locale: "en_US",
         purchase_price:
           (offer.transaction_usd - transaction.down_payment_usd) |> Jason.encode!(),
         reserve: 0.0,
         second_installment:
           (offer.transaction_usd - transaction.down_payment_usd + offer.importer_fee)
           |> Jason.encode!()
       })},
      {"exporter",
       Jason.encode!(%{
         MSA_date: exporter.sign_msa_datetime |> Date.to_iso8601(),
         address: exporter.address,
         company_name: exporter.business_name,
         contact: "#{exporter.contact.first_name} #{exporter.contact.last_name}",
         email: exporter.contact.email,
         phone: to_string(exporter.contact.work_phone),
         signatory_email: exporter.signatory_email,
         signatory_name: "#{exporter.signatory_first_name} #{exporter.signatory_last_name}",
         signatory_title: exporter.signatory_title,
         title: exporter.contact.role
       })},
      {"importer",
       Jason.encode!(%{
         address: importer_address,
         contact: "#{importer.contact.first_name} #{importer.contact.last_name}",
         email: importer.contact.email,
         name: importer.business_name,
         mobile: importer.contact.mobile,
         personal_address: importer.contact.us_place.full_address,
         bank_account: importer.bank_account,
         bank_name: importer.bank_name
       })},
      {"invoice",
       Jason.encode!(%{
         invoice_date: transaction.invoice_date |> Date.to_iso8601(),
         invoice_fname: "Invoice.pdf",
         invoice_num: transaction.invoice_ref,
         second_installment_date: second_installment_date
       })},
      {"po_pi",
       Jason.encode!(%{
         est_second_installment_date: est_second_installment_date,
         proforma_fname: "PO.pdf",
         proforma_invoice_date: transaction.po_date |> Date.to_iso8601(),
         proforma_invoice_num: transaction.po_ref
       })},
      {"transigo", TransigoAdmin.Job.Helper.get_transigo_doc_info()}
    ]

    {:ok, payload}
  end

  # get HelloSign payload to create signature request
  @spec get_trans_hs_payload(String.t(), Transaction.t()) :: {:ok, [tuple]}
  defp get_trans_hs_payload(trans_doc_path, %{
         exporter: exporter,
         importer: %{contact: importer_contact}
       }) do
    trans_doc_basename = Path.basename(trans_doc_path)

    payload = [
      {"client_id", Application.get_env(:transigo_admin, :hs_client_id)},
      {"test_mode", "1"},
      {"use_text_tags", "1"},
      {"hide_text_tags", "1"},
      {:file, trans_doc_path, {"form-data", [name: "file[0]", filename: trans_doc_basename]}, []},
      {"signers[0][name]", "Nir Tal"},
      {"signers[0][email_address]", "nir.tal@transigo.io"},
      {"signers[1][name]", "#{importer_contact.first_name} #{importer_contact.last_name}"},
      {"signers[1][email_address]", importer_contact.email},
      {"signers[2][name]", "#{exporter.signatory_first_name} #{exporter.signatory_last_name}"},
      {"signers[2][email_address]", exporter.signatory_email}
    ]

    {:ok, payload}
  end

  # call when transaction need to generate a new signature request
  @spec generate_sign_doc(Transaction.t()) :: {:ok, map} | {:error, any}
  defp generate_sign_doc(%{transaction: transaction} = offer) do
    with true <- sign_doc_validation(offer.transaction),
         {:ok, pg_cap} <- calculate_pg_cap(offer.transaction),
         {:ok, invoice_path} <- @s3_api.download_file(transaction, :invoice),
         {:ok, po_path} <- @s3_api.download_file(transaction, :po),
         {:ok, trans_doc_payload} <- get_trans_doc_payload(offer, pg_cap, invoice_path, po_path),
         {:ok, trans_doc_path} <-
           @util_api.generate_transaction_doc(trans_doc_payload),
         {:ok, trans_hs_payload} <- get_trans_hs_payload(trans_doc_path, offer.transaction),
         {:ok, %{"signature_request" => %{"signature_request_id" => req_id}} = sign_req} <-
           @hs_api.create_signature_request(trans_hs_payload),
         {:ok, _transaction} <-
           update_transaction(offer.transaction, %{hellosign_signature_request_id: req_id}) do
      get_importer_exporter_sign_url(sign_req, offer.transaction)
    else
      {:error, _message} = error_tuple ->
        error_tuple

      _ ->
        {:error, "Failed to get transaction document"}
    end
  end

  # call when the transaction already has a signature request
  @spec get_sign_docs_urls_with_req_id(String.t(), Transaction.t()) :: {:ok, map} | {:error, any}
  defp get_sign_docs_urls_with_req_id(hs_sign_req_id, transaction) do
    case @hs_api.get_signature_request(hs_sign_req_id) do
      {:ok, sign_req} ->
        get_importer_exporter_sign_url(sign_req, transaction)

      {:error, _message} = error_tuple ->
        error_tuple

      _ ->
        {:error, "Failed to get transaction document"}
    end
  end

  # loop through signature_request to get url for exporter and importer
  @spec get_importer_exporter_sign_url(map, Transaction.t()) :: {:ok, map}
  defp get_importer_exporter_sign_url(%{"signature_request" => %{"signatures" => signatures}}, %{
         exporter: %{signatory_email: exporter_email},
         importer: %{contact: %{email: importer_email}}
       }) do
    sign_urls =
      Enum.flat_map(signatures, fn %{"signer_email_address" => email, "signature_id" => sign_id} ->
        case email do
          ^importer_email -> %{importer_url: @hs_api.fetch_sign_url(sign_id)}
          ^exporter_email -> %{exporter_url: @hs_api.fetch_sign_url(sign_id)}
          _ -> []
        end
      end)
      |> Enum.into(%{})

    {:ok, sign_urls}
  end

  @doc """
  rest api
  /trans/:transaction_uid/get_tran_docs
  get the transaction document after it has been signed by all parties
  """
  @spec get_tran_doc(String.t()) :: {:ok, String.t()} | {:error, any}
  def get_tran_doc(transaction_uid) do
    case get_transaction_by_transaction_uid(transaction_uid, [:exporter, :importer]) do
      nil ->
        {:error, "Offer not found"}

      %{
        exporter: %{exporter_transigo_uid: exporter_uid},
        importer: %{importer_transigo_uid: importer_uid}
      } ->
        "exporter/#{exporter_uid}/#{importer_uid}/#{transaction_uid}/#{transaction_uid}_transaction.pdf"
        |> @s3_api.get_file_presigned_url()
    end
  end

  @doc """
  rest api
  /invoices/:transaction_uid/upload_invoice
  upload invoice and update transaction with invoice date and ref
  """
  @spec upload_invoice(String.t(), map) :: {:ok, Transaction.t()} | {:error, any}
  def upload_invoice(transaction_uid, params) do
    invoice_date = Map.get(params, "invoiceDate")
    invoice_ref = Map.get(params, "invoiceRef")
    invoice = Map.get(params, "invoice")

    cond do
      is_nil(invoice_date) ->
        {:error, "invoiceDate missing"}

      is_nil(invoice_ref) ->
        {:error, "invoiceRef missing"}

      true ->
        do_upload(invoice_date, invoice_ref, invoice, transaction_uid, :invoice)
    end
  end

  @doc """
  rest api
  /invoices/:transaction_uid/upload_po
  upload po and update transaction with po date and ref
  """
  @spec upload_po(String.t(), map) :: {:ok, Transaction.t()} | {:error, any}
  def upload_po(transaction_uid, params) do
    po_date = Map.get(params, "PODate")
    po_ref = Map.get(params, "PORef")
    po = Map.get(params, "po")

    cond do
      is_nil(po_date) ->
        {:error, "PODate missing"}

      is_nil(po_ref) ->
        {:error, "PORef missing"}

      true ->
        do_upload(po_date, po_ref, po, transaction_uid, :po)
    end
  end

  # handle upload invoice or po
  @spec do_upload(String.t(), String.t(), %Plug.Upload{}, String.t(), atom) ::
          {:ok, Transaction.t()} | {:error, any}
  defp do_upload(
         date,
         ref,
         %Plug.Upload{path: path, content_type: "application/pdf"},
         transaction_uid,
         type
       ) do
    with {:ok, temp} = Briefly.create(extname: ".pdf"),
         :ok = File.cp(path, temp),
         transaction <-
           get_transaction_by_transaction_uid(transaction_uid, [:exporter, :importer]),
         false <- is_nil(transaction),
         {:ok, formatted_date} <- Timex.parse(date, "{YYYY}-{0M}-{0D}"),
         {:ok, _upload} <- @s3_api.upload_file(transaction, temp, type) do
      update_transaction_for_invoice_po(transaction, ref, formatted_date, type)
    else
      true ->
        {:error, "Offer not found"}

      {:error, _message} = error_tuple ->
        error_tuple

      _ ->
        {:error, "Failed to upload"}
    end
  end

  defp do_upload(_date, _ref, _file, _uid, _type),
    do: {:error, "File not found or incorrect content type"}

  @spec update_transaction_for_invoice_po(Transaction.t(), String.t(), Date.t(), atom) ::
          {:ok, Transaction.t()} | {:error, any}
  defp update_transaction_for_invoice_po(transaction, invoice_ref, invoice_date, :invoice),
    do: update_transaction(transaction, %{invoice_ref: invoice_ref, invoice_date: invoice_date})

  defp update_transaction_for_invoice_po(transaction, po_ref, po_date, :po),
    do: update_transaction(transaction, %{po_ref: po_ref, po_date: po_date})

  def create_quota(attrs \\ %{}) do
    %Quota{}
    |> Quota.changeset(attrs)
    |> Repo.insert()
  end

  def get_quota!(id), do: Repo.get!(Importer, id)

  @doc """
  find granted quota of importer
  """
  @spec find_granted_quota(String.t()) :: Quota.t() | nil
  def find_granted_quota(importer_id) do
    from(q in Quota,
      where: q.importer_id == ^importer_id and q.credit_status in ["granted", "partial"]
    )
    |> Repo.one()
  end

  def create_marketplace(attrs \\ %{}) do
    %Marketplace{}
    |> Marketplace.changeset(attrs)
    |> Repo.insert()
  end

  def update_quota(quota, attrs \\ %{}) do
    quota
    |> Quota.changeset(attrs)
    |> Repo.update()
  end

  def delete_quota(%Quota{} = quota), do: Repo.delete(quota)

  @doc """
  list quota with pending eh_job to get eh_grade
  """
  @spec list_quota_with_pending_eh_job :: [Quota.t()]
  def list_quota_with_pending_eh_job() do
    from(q in Quota,
      where: not is_nil(q.eh_grade_job_url) and is_nil(q.eh_grade)
    )
    |> Repo.all()
  end

  @doc """
  list quota with eh_cover
  """
  @spec list_quota_with_eh_cover :: [Quota.t()]
  def list_quota_with_eh_cover() do
    from(q in Quota, where: not is_nil(q.eh_cover))
    |> Repo.all()
  end

  @doc """
  list quota with pagination
  """
  @spec list_quotas_paginated(map) :: {:ok, map}
  def list_quotas_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"
    credit_status = "%#{Map.get(pagination_args, :credit_status)}%"

    from(q in Quota,
      left_join: i in assoc(q, :importer),
      where: ilike(i.business_name, ^keyword) and ilike(q.credit_status, ^credit_status)
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  @doc """
  rest api
  /trans/generate_offer
  generate an offer with transaction
  """
  @spec generate_offer(map) :: {:ok, Offer.t()} | {:error, any}
  def generate_offer(param) do
    with {:ok, %{hs_signing_status: "all_signed"} = exporter} <-
           check_exporter(Map.get(param, "exporterUID")),
         {:ok, importer} <-
           check_importer(Map.get(param, "importerUID")),
         {:ok, transaction_sum_usd} <- check_transaction_sum(Map.get(param, "transactionSumUSD")),
         {:ok, credit_days} <- check_credit_days(Map.get(param, "requestedCreditDays")),
         {:ok, attrs} <-
           calculate_transaction_offer(exporter, importer, transaction_sum_usd, credit_days) do
      %Offer{}
      |> Offer.create_with_transaction_changeset(attrs)
      |> Repo.insert()
    else
      {:error, _message} = error_tuple ->
        error_tuple

      {:ok, %Account.Exporter{}} ->
        {:error, "MSA not completed"}
    end
  end

  # check if exporter exist
  @spec check_exporter(String.t()) :: {:ok, Account.Exporter.t()} | {:error, any}
  defp check_exporter(nil), do: {:error, "Exporter not found"}

  defp check_exporter(exporter_uid) do
    case Account.get_exporter_by_exporter_uid(exporter_uid) do
      nil -> {:error, "Exporter not found"}
      exporter -> {:ok, exporter}
    end
  end

  # check if importer exist
  @spec check_importer(String.t()) :: {:ok, Account.Importer.t()} | {:error, any}
  defp check_importer(nil), do: {:error, "Importer not found"}

  defp check_importer(importer_uid) do
    case Account.get_importer_by_importer_uid(importer_uid) do
      nil ->
        {:error, "Importer not found"}

      %{shufti_pro_verified_json: shufti_json} = importer ->
        cond do
          is_nil(shufti_json) ->
            {:error, "Importer is not verified through Shufti Pro"}

          true ->
            {:ok, importer}
        end
    end
  end

  # check if credit day is the correct format
  @spec check_credit_days(String.t()) :: {:ok, Account.Importer.t()} | {:error, any}
  defp check_credit_days(credit_days) do
    cond do
      is_nil(credit_days) ->
        {:error, "requestedCreditDays not found"}

      not is_integer(credit_days) ->
        {:error, "requestedCreditDays has to be integer"}

      credit_days != 60 ->
        {:error, "requestedCreditDays has to be 60"}

      true ->
        {:ok, credit_days}
    end
  end

  @doc """
  format the transaction sum
  """
  @spec check_transaction_sum(any) :: {:ok, number} | {:error, any}
  def check_transaction_sum(nil), do: {:error, "transactionSumUSD not found"}

  def check_transaction_sum(transaction_sum)
      when is_integer(transaction_sum) or is_float(transaction_sum),
      do: {:ok, transaction_sum}

  def check_transaction_sum(transaction_sum) do
    if String.match?(
         transaction_sum,
         ~r"^[$]?[0-9]{1,3}(?:[0-9]*(?:[.,][0-9]{1})?|(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|(?:\.[0-9]{3})*(?:,[0-9]{1,2})?)[kK]?$"
       ) do
      transaction_sum = String.downcase(transaction_sum)
      k_multiply = if String.last(transaction_sum) == "k", do: 1000, else: 1

      {sum, _} =
        transaction_sum
        |> String.replace(",", "")
        |> String.replace("$", "")
        |> String.replace("k", "")
        |> Float.parse()

      {:ok, sum * k_multiply}
    else
      {:error, "transactionSumUSD has incorrect format"}
    end
  end

  @spec check_quota_and_financed_sum(String.t(), number) :: :ok | {:error, any}
  defp check_quota_and_financed_sum(importer_id, financed_sum) do
    granted_quota = find_granted_quota(importer_id)

    total_financed_sum =
      from(t in Transaction,
        where: t.importer_id == ^importer_id,
        select: coalesce(sum(t.financed_sum), 0)
      )
      |> Repo.one!()

    cond do
      is_nil(granted_quota) ->
        {:error, "No quota available"}

      Timex.diff(granted_quota.credit_granted_date, Timex.now(), :years) >= 1 ->
        {:error,
         "Quota was generated more than 1 year ago. Please revoke and request the quota again."}

      total_financed_sum + financed_sum > granted_quota.quota_usd ->
        {:error, "Insufficient quota"}

      true ->
        :ok
    end
  end

  # calculate fields for transaction and offer
  @spec calculate_transaction_offer(Account.Exporter.t(), Account.Importer.t(), number, number) ::
          {:ok, map}
  defp calculate_transaction_offer(
         %{id: exporter_id},
         %{id: importer_id},
         transaction_sum_usd,
         credit_days
       ) do
    standard_percentage_per_month = 2.5
    standard_handling_fee = 200.0
    standard_down_payment_percentage = 30.0

    financed_sum =
      ((1.0 - standard_down_payment_percentage / 100.0) * transaction_sum_usd)
      |> Float.round(2)

    linear_fee =
      (financed_sum * standard_percentage_per_month * credit_days / 30.0 / 100.0 +
         standard_handling_fee)
      |> Float.round(2)

    downpayment_usd = Float.round(transaction_sum_usd - financed_sum, 2)
    second_installment_usd = financed_sum + linear_fee

    case check_quota_and_financed_sum(importer_id, financed_sum) do
      {:error, _error} = error_tuple ->
        error_tuple

      :ok ->
        {:ok,
         %{
           transaction_usd: transaction_sum_usd,
           advance_percentage: standard_down_payment_percentage,
           advance_usd: downpayment_usd,
           importer_fee: linear_fee,
           transaction: %{
             transaction_uid: @util_api.get_uid("tra"),
             importer_id: importer_id,
             exporter_id: exporter_id,
             credit_term_days: credit_days,
             financed_sum: financed_sum,
             down_payment_usd: downpayment_usd,
             factoring_fee_usd: linear_fee,
             second_installment_usd: second_installment_usd
           }
         }}
    end
  end

  @doc """
  get offer by transaction_uid
  """
  @spec get_offer_by_transaction_uid(String.t(), [atom]) :: Offer.t() | nil
  def get_offer_by_transaction_uid(transaction_uid, preloads \\ []) do
    from(
      o in Offer,
      left_join: t in assoc(o, :transaction),
      where: t.transaction_uid == ^transaction_uid,
      preload: ^preloads
    )
    |> Repo.one()
  end

  def create_offer(attrs \\ %{}) do
    %Offer{}
    |> Offer.changeset(attrs)
    |> Repo.insert()
  end

  def get_offer(id, preloads \\ []) do
    from(o in Offer, where: o.id == ^id, preload: ^preloads)
    |> Repo.one()
  end

  @doc """
  rest api
  /trans/:transaction_uid/accept
  accept or decline the offer
  """
  @spec accept_decline_offer(String.t(), boolean) :: {:ok, Offer.t()} | {:error, any}
  def accept_decline_offer(_transaction_uid, nil), do: {:error, "acceptDecline missing"}

  def accept_decline_offer(transaction_uid, true),
    do: do_accept_decline_offer(get_offer_by_transaction_uid(transaction_uid), "A")

  def accept_decline_offer(transaction_uid, false),
    do: do_accept_decline_offer(get_offer_by_transaction_uid(transaction_uid), "D")

  defp do_accept_decline_offer(nil, _a_or_d), do: {:error, "Offer not found"}

  defp do_accept_decline_offer(%Offer{id: offer_id} = offer, accept_or_decline) do
    offer
    |> Offer.changeset(%{offer_accepted_declined: accept_or_decline})
    |> Repo.update()

    {:ok, get_offer(offer_id, [:transaction])}
  end

  @doc """
  list offer with pagination
  """
  @spec list_offers_paginated(map) :: {:ok, map}
  def list_offers_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"

    query =
      from(o in Offer,
        left_join: t in assoc(o, :transaction),
        left_join: e in assoc(t, :exporter),
        left_join: i in assoc(t, :importer),
        where: ilike(i.business_name, ^keyword) or ilike(e.business_name, ^keyword)
      )

    case check_accept_decline(Map.get(pagination_args, :accepted)) do
      nil ->
        query

      accept_decline ->
        query
        |> where([o], ilike(o.offer_accepted_declined, ^accept_decline))
    end
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  @spec check_accept_decline(boolean) :: nil | String.t()
  defp check_accept_decline(nil), do: nil

  defp check_accept_decline(true), do: "A"

  defp check_accept_decline(false), do: "D"

  def datasource, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(queryable, _), do: queryable

  def sign_transaction(
        %{"exporter_uid" => exporter_uid, "transaction_uid" => transaction_uid} = params
      ) do
    with true <- DataLayer.check_uid(exporter_uid, "exp"),
         true <- DataLayer.check_uid(transaction_uid, "tra"),
         {:ok, transaction} <- get_exporter_and_transaction_by_id(params) do
      {:ok, request} =
        @hs_api.get_signature_request(transaction.hellosign_signature_request_id)
      signer =
        request["signature_requests"]["signatures"]
        |> Enum.find(fn x -> x.signer_email_address == transaction.exporter.signatory_email end)
      @hs_api.fetch_sign_url(signer.signature_id)
    end
  end

  def get_exporter_and_transaction_by_id(%{
        "exporter_uid" => exporter_uid,
        "transaction_uid" => transaction_uid
      }) do
    transaction =
      Transaction
      |> where(transaction_uid: ^transaction_uid)
      |> where([t], t.hs_signing_status != "all_signed")
      |> preload(:exporter)
      |> Repo.one()

    if not is_nil(transaction) and transaction.exporter.exporter_transigo_uid == exporter_uid do
      {:ok, transaction}
    else
      {:error, "could not find exporter or transaction"}
    end
  end
end
