defmodule TransigoAdminWeb.ApiExporterView do
  use TransigoAdminWeb, :view

  def render("sign_msa.json", %{sign_url: exporter_url}) do
    %{result: %{sign_url: exporter_url}}
  end

  def render("create.json", %{exporter: exporter}) do
    %{result: %{exporter_transigoUID: exporter.exporter_transigo_uid}}
  end
end
