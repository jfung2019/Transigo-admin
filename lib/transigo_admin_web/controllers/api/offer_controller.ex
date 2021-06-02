defmodule TransigoAdminWeb.Api.OfferController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Credit

  @offer_view TransigoAdminWeb.ApiOfferView
  @error_view TransigoAdminWeb.ApiErrorView

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

  def get_offer(conn, %{"transaction_uid" => transaction_uid}) do
    case Credit.get_offer_by_transaction_uid(transaction_uid, [:transaction]) do
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
end
