defmodule TransigoAdmin.Credit do
  import Ecto.Query, warn: false

  alias TransigoAdmin.Repo
  alias Absinthe.Relay
  alias TransigoAdmin.Credit.{Transaction, Quota, Marketplace, Offer}

  @hs_api Application.compile_env(:transigo_admin, :hs_api)
  @util_api Application.compile_env(:transigo_admin, :util_api)
  @s3_api Application.compile_env(:transigo_admin, :s3_api)

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

  def list_transactions_status_originated() do
    from(t in Transaction,
      where: t.transaction_state == "originated",
      preload: [:exporter, importer: [:contact]]
    )
    |> Repo.all()
  end

  def list_transactions_by_state(state) do
    from(t in Transaction, where: t.transaction_state == ^state)
    |> Repo.all()
  end

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

  def get_offer_by_transaction_uid(transaction_uid, preloads \\ []) do
    from(
      o in Offer,
      left_join: t in assoc(o, :transaction),
      where: t.transaction_uid == ^transaction_uid,
      preload: ^preloads
    )
    |> Repo.one()
  end

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

  defp get_transaction_count_of_importer(importer_id) do
    from(
      t in Transaction,
      where: t.importer_id == ^importer_id,
      select: coalesce(count(t.id), 0)
    )
    |> Repo.one!()
  end

  defp calculate_pg_cap(%{importer_id: importer_id}) do
    case get_transaction_count_of_importer(importer_id) do
      1 ->
        %Quota{quota_usd: quota_usd} = find_granted_quota(importer_id)
        {:ok, quota_usd * 2}

      _ ->
        {:ok, 0}
    end
  end

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
         currency: "USD",
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

  defp delete_trans_docs(transaction_uid) do
    ["invoice", "po", "transaction"]
    |> Enum.each(fn type ->
      file_path = "temp/#{transaction_uid}_#{type}.pdf"
      if File.exists?(file_path), do: File.rm(file_path)
    end)

    :ok
  end

  defp generate_sign_doc(
         %{transaction: %{transaction_uid: transaction_uid} = transaction} = offer
       ) do
    with true <- sign_doc_validation(offer.transaction),
         {:ok, pg_cap} <- calculate_pg_cap(offer.transaction),
         {:ok, invoice_path} <- @s3_api.download_invoice_po_file(transaction, :invoice),
         {:ok, po_path} <- @s3_api.download_invoice_po_file(transaction, :po),
         {:ok, trans_doc_payload} <- get_trans_doc_payload(offer, pg_cap, invoice_path, po_path),
         {:ok, trans_doc_path} <-
           @util_api.generate_transaction_doc(trans_doc_payload, transaction_uid),
         {:ok, trans_hs_payload} <- get_trans_hs_payload(trans_doc_path, offer.transaction),
         {:ok, %{"signature_request" => %{"signature_request_id" => req_id}} = sign_req} <-
           @hs_api.create_signature_request(trans_hs_payload),
         {:ok, _transaction} <-
           update_transaction(offer.transaction, %{hellosign_signature_request_id: req_id}),
         :ok <- delete_trans_docs(transaction_uid) do
      get_importer_exporter_sign_url(sign_req, offer.transaction)
    else
      {:error, _message} = error_tuple ->
        delete_trans_docs(transaction_uid)
        error_tuple

      _ ->
        delete_trans_docs(transaction_uid)
        {:error, "Failed to get transaction document"}
    end
  end

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

  defp get_importer_exporter_sign_url(%{"signature_request" => %{"signatures" => signatures}}, %{
         exporter: %{signatory_email: exporter_email},
         importer: %{contact: %{email: importer_email}}
       }) do
    sign_urls =
      Enum.flat_map(signatures, fn %{"signer_email_address" => email, "signature_id" => sign_id} ->
        case email do
          ^importer_email -> %{importer_url: fetch_sign_url(sign_id)}
          ^exporter_email -> %{exporter_url: fetch_sign_url(sign_id)}
          _ -> []
        end
      end)
      |> Enum.into(%{})

    {:ok, sign_urls}
  end

  defp fetch_sign_url(sign_id) do
    {:ok, %{"embedded" => %{"sign_url" => sign_url}}} = @hs_api.get_sign_url(sign_id)
    "#{sign_url}&client_id=#{Application.get_env(:transigo_admin, :hs_client_id)}"
  end

  def create_quota(attrs \\ %{}) do
    %Quota{}
    |> Quota.changeset(attrs)
    |> Repo.insert()
  end

  def get_quota!(id), do: Repo.get!(Importer, id)

  def find_granted_quota(importer_id) do
    from(q in Quota,
      left_join: i in assoc(q, :importer),
      where: i.id == ^importer_id and q.credit_status in ["granted", "partial"]
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

  def list_quota_with_pending_eh_job() do
    from(q in Quota,
      where: not is_nil(q.eh_grade_job_url) and is_nil(q.eh_grade)
    )
    |> Repo.all()
  end

  def list_quota_with_eh_cover() do
    from(q in Quota, where: not is_nil(q.eh_cover))
    |> Repo.all()
  end

  def list_quotas_paginated(pagination_args) do
    keyword = "%#{Map.get(pagination_args, :keyword)}%"
    credit_status = "%#{Map.get(pagination_args, :credit_status)}%"

    from(q in Quota,
      left_join: i in assoc(q, :importer),
      where: ilike(i.business_name, ^keyword) and ilike(q.credit_status, ^credit_status)
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  def create_offer(attrs \\ %{}) do
    %Offer{}
    |> Offer.changeset(attrs)
    |> Repo.insert()
  end

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

  defp check_accept_decline(nil), do: nil

  defp check_accept_decline(true), do: "A"

  defp check_accept_decline(false), do: "D"

  def datasource, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(queryable, _), do: queryable
end
