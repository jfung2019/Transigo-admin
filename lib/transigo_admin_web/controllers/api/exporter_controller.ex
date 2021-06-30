defmodule TransigoAdminWeb.Api.ExporterController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Account

  @exporter_view TransigoAdminWeb.ApiExporterView
  @error_view TransigoAdminWeb.ApiErrorView

  def sign_msa(conn, %{"exporter_uid" => exporter_uid} = param) do
    case Account.sign_msa(exporter_uid, Map.get(param, "cn")) do
      {:ok, sign_url} ->
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