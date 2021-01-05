defmodule TransigoAdmin.Credit.TransactionAdmin do
  def index(_) do
    [
      transaction_UID: nil,
      importer_id: nil,
      exporter_id: nil,
      credit_term_days: nil,
      down_payment_USD: nil,
      factoring_fee_USD: nil,
      financed_sum: nil,
      hellosign_signature_request_id: nil,
      hs_signing_status: nil
    ]
  end

  def form_fields(_) do
    [
      transaction_UID: nil,
      importer_id: nil,
      exporter_id: nil,
      credit_term_days: nil,
      down_payment_USD: nil,
      factoring_fee_USD: nil,
      financed_sum: nil,
      hellosign_signature_request_id: nil,
      hs_signing_status: nil
    ]
  end
end
