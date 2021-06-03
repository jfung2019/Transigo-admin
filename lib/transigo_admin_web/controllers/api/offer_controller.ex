defmodule TransigoAdminWeb.Api.OfferController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Credit

  @offer_view TransigoAdminWeb.ApiOfferView
  @error_view TransigoAdminWeb.ApiErrorView

  def generate_offer(conn, param) do
    case Credit.generate_offer(param) do
      {:ok, offer} ->
        conn
        |> put_status(200)
        |> put_view(@offer_view)
        |> render("offer.json", offer: offer)

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end

  def get_offer(conn, %{"transaction_uid" => transaction_uid}) do
    case Credit.get_offer_by_transaction_uid(transaction_uid, [:transaction]) do
      nil ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: "Offer not found")

      offer ->
        conn
        |> put_status(200)
        |> put_view(@offer_view)
        |> render("offer.json", offer: offer)
    end
  end

  def accept_decline_offer(conn, %{"transaction_uid" => transaction_uid} = params) do
    case Credit.accept_decline_offer(transaction_uid, Map.get(params, "acceptDecline")) do
      {:ok, offer} ->
        conn
        |> put_status(200)
        |> put_view(@offer_view)
        |> render("accept_decline_offer.json", offer: offer)

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end

  def confirm_downpayment(conn, %{"transaction_uid" => transaction_uid} = params) do
    case Credit.confirm_downpayment(transaction_uid, params) do
      {:ok, transaction} ->
        conn
        |> put_status(200)
        |> put_view(@offer_view)
        |> render("simple_message.json", message: "#{transaction_uid} downpayment confirmed")

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end

  def upload_invoice(conn, %{"transaction_uid" => transaction_uid} = params) do
    case Credit.upload_invoice(transaction_uid, params) do
      {:ok, %{transaction_uid: transaction_uid}} ->
        conn
        |> put_status(200)
        |> put_view(@offer_view)
        |> render("simple_message.json", message: "#{transaction_uid} invoice uploaded")

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end

  def upload_po(conn, %{"transaction_uid" => transaction_uid} = params) do
    case Credit.upload_po(transaction_uid, params) do
      {:ok, %{transaction_uid: transaction_uid}} ->
        conn
        |> put_status(200)
        |> put_view(@offer_view)
        |> render("simple_message.json", message: "#{transaction_uid} po uploaded")

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end

  def sign_docs(conn, %{"transaction_uid" => transaction_uid}) do
    case Credit.sign_docs(transaction_uid) do
      {:ok, urls} ->
        conn
        |> put_status(200)
        |> put_view(@offer_view)
        |> render("sign_docs.json", sign_urls: urls)

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end

  def get_tran_doc(conn, %{"transaction_uid" => transaction_uid}) do
    case Credit.get_tran_doc(transaction_uid) do
      {:ok, url} ->
        conn
        |> redirect(external: url)

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end
end
