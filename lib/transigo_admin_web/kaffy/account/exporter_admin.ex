defmodule TransigoAdmin.Account.ExporterAdmin do
  def ordering(_schema) do
    [desc: :hs_signing_status]
  end

  def index(_) do
    [
      exporter_transigoUID: nil,
      business_name: nil,
      hellosign_signature_request_id: nil,
      hs_signing_status: nil
    ]
  end

  def form_fields(_) do
    [
      exporter_transigoUID: nil,
      business_name: nil,
      hellosign_signature_request_id: nil,
      hs_signing_status: nil
    ]
  end

  def custom_pages(_schema, _conn) do
    [
      %{
        slug: "sign_doc",
        name: "Sign Doc",
        view: TransigoAdminWeb.CustomPageView,
        template: "sign_doc.html"
      },
      %{
        slug: "periodic_jobs",
        name: "Periodic Jobs",
        view: TransigoAdminWeb.CustomPageView,
        template: "oban_job.html"
      }
    ]
  end
end
