defmodule TransigoAdminWeb.ApiExporterView do
  use TransigoAdminWeb, :view

  def render("sign_msa.json", %{sign_url: exporter_url}) do
    %{result: %{sign_url: exporter_url}}
  end
end
