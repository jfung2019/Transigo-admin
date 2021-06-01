defmodule TransigoAdminWeb.ApiOfferView do
  use TransigoAdminWeb, :view

  def render("sign_docs.json", %{
        sign_urls: %{exporter_url: exporter_url, importer_url: importer_url}
      }) do
    %{
      result: %{
        signURLImporter: importer_url,
        signURLExporter: exporter_url
      }
    }
  end
end
