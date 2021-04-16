defmodule TransigoAdmin.Credit.TransactionAdmin do
  def index(_) do
    [
      transaction_uid: nil,
      importer_id: nil,
      exporter_id: nil,
      transaction_state: nil,
      credit_term_days: nil,
      down_payment_usd: nil,
      down_payment_confirmed_datetime: nil,
      factoring_fee_usd: nil,
      financed_sum: nil,
      invoice_date: nil,
      invoice_ref: nil,
      po_date: nil,
      po_ref: nil,
      second_installment_usd: nil,
      repaid_datetime: nil,
      hellosign_signature_request_id: nil,
      hs_signing_status: nil,
      inserted_at: %{name: "created datetime"},
      updated_at: %{name: "last modified datetime"}
    ]
  end

  def form_fields(_) do
    [
      transaction_uid: nil,
      importer_id: nil,
      exporter_id: nil,
      transaction_state: nil,
      credit_term_days: nil,
      down_payment_usd: nil,
      down_payment_confirmed_datetime: nil,
      factoring_fee_usd: nil,
      financed_sum: nil,
      invoice_date: nil,
      invoice_ref: nil,
      po_date: nil,
      po_ref: nil,
      second_installment_usd: nil,
      repaid_datetime: nil,
      hellosign_signature_request_id: nil,
      hs_signing_status: nil,
      inserted_at: %{name: "created datetime"},
      updated_at: %{name: "last modified datetime"}
    ]
  end
end
