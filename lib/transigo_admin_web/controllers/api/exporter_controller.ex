defmodule TransigoAdminWeb.Api.ExporterController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Account
  alias TransigoAdmin.Credit
  alias TransigoAdmin.Account.Contact
  alias TransigoAdmin.Account.Exporter

  @exporter_view TransigoAdminWeb.ApiExporterView
  @hello_sign_view TransigoAdminWeb.HellosignView
  @error_view TransigoAdminWeb.ApiErrorView
  @hs_client_id "transigo hellosign client id"

  def update_exporter(conn, %{"exporter_uid" => _} = params) do
    case Account.update_exporter(params) do
      {:ok, %{Contact => _contact, Exporter => exporter}} ->
        conn
        |> put_status(200)
        |> put_view(@exporter_view)
        |> render("show.json", exporter: exporter)

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end

  def show_exporter(conn, %{"exporter_uid" => uid}) do
    case Account.get_exporter_by_exporter_uid(uid) do
      {:ok, exporter} ->
        conn
        |> put_status(200)
        |> put_view(@exporter_view)
        |> render("show.json", exporter: exporter)

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end

  def create_exporter(conn, params) do
    case Account.create_exporter(params) do
      {:ok, %{Contact => _contact, Exporter => exporter}} ->
        conn
        |> put_status(200)
        |> put_view(@exporter_view)
        |> render("create.json", exporter: exporter)

      _ ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: "Could not create exporter")
    end
  end

  def get_msa(conn, %{"exporter_uid" => _} = params) do
    case Account.get_msa(params) do
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

  def sign_transaction(
        conn,
        %{"exporter_uid" => _exp_uid, "transaction_uid" => _trans_uid} = params
      ) do
    case Credit.sign_transaction(params) do
      {:ok, url} ->
        conn
        |> put_status(200)
        |> put_view(@hello_sign_view)
        |> render("index.html", %{sign_url: url, hs_client_id: @hs_client_id})

      _ ->
        conn
        |> put_status(400)
        |> put_view(@hello_sign_view)
        |> render("failed.html")
    end
  end

  def sign_msa(conn, %{"exporter_uid" => exporter_uid} = param) do
    case Account.sign_msa(exporter_uid, Map.get(param, "cn_msa")) do
      {:ok, %{msa_url: sign_url}} ->
        conn
        |> put_status(200)
        |> put_view(@exporter_view)
        |> render("sign_msa.json", sign_url: sign_url)

      {:error, message} ->
        conn
        |> put_status(400)
        |> put_view(@error_view)
        |> render("errors.json", message: message)
    end
  end
end
