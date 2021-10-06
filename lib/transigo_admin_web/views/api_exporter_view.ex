defmodule TransigoAdminWeb.ApiExporterView do
  use TransigoAdminWeb, :view
  alias TransigoAdmin.Account.Exporter

  def render("sign_msa.json", %{sign_url: exporter_url}) do
    %{result: %{sign_url: exporter_url}}
  end

  def render("create.json", %{exporter: exporter}) do
    %{result: %{exporter_transigoUID: exporter.exporter_transigo_uid}}
  end

  def render("show.json", %{exporter: exporter}) do
    %{result: %{exporter: render_exporter(exporter)}}
  end

  defp render_exporter(%Exporter{
         exporter_transigo_uid: exporter_transigo_uid,
         business_name: business_name,
         address: address,
         business_address_country: business_address_country,
         registration_number: registration_number,
         signatory_first_name: signatory_first_name,
         signatory_last_name: signatory_last_name,
         signatory_mobile: signatory_mobile,
         signatory_email: signatory_email,
         signatory_title: signatory_title,
         hellosign_signature_request_id: hellosign_signature_request_id,
         hs_signing_status: hs_signing_status,
         marketplace_id: marketplace_id,
         contact_id: contact_id,
         cn_msa: cn_msa
       }) do
    %{
      exporter_transigo_uid: exporter_transigo_uid,
      business_name: business_name,
      address: address,
      business_address_country: business_address_country,
      registration_number: registration_number,
      signatory_first_name: signatory_first_name,
      signatory_last_name: signatory_last_name,
      signatory_mobile: signatory_mobile,
      signatory_email: signatory_email,
      signatory_title: signatory_title,
      hellosign_signature_request_id: hellosign_signature_request_id,
      hs_signing_status: hs_signing_status,
      marketplace_id: marketplace_id,
      contact_id: contact_id,
      cn_msa: cn_msa
    }
  end
end
