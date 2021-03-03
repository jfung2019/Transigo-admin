defmodule TransigoAdmin.Account.ExporterAdmin do
  def ordering(_schema) do
    [desc: :hs_signing_status]
  end

  def index(_) do
    [
      exporter_transigoUID: nil,
      business_name: nil,
      address: nil,
      business_address_country: nil,
      registration_number: nil,
      signatory_first_name: nil,
      signatory_last_name: nil,
      signatory_mobile: nil,
      signatory_email: nil,
      signatory_title: nil,
      hellosign_signature_request_id: nil,
      hs_signing_status: nil,
      inserted_at: %{name: "created datetime"},
      updated_at: %{name: "last modified datetime"}
    ]
  end

  def form_fields(_) do
    [
      exporter_transigoUID: nil,
      business_name: nil,
      address: nil,
      business_address_country: nil,
      registration_number: nil,
      signatory_first_name: nil,
      signatory_last_name: nil,
      signatory_mobile: nil,
      signatory_email: nil,
      signatory_title: nil,
      hellosign_signature_request_id: nil,
      hs_signing_status: nil,
      inserted_at: %{name: "created datetime"},
      updated_at: %{name: "last modified datetime"}
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
