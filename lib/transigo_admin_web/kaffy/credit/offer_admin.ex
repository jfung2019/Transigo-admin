defmodule TransigoAdmin.Credit.OfferAdmin do
  def index(_) do
    [
      transaction_id: nil,
      transaction_usd: nil,
      advance_percentage: nil,
      advance_usd: nil,
      importer_fee: nil,
      offer_accepted_declined: nil
    ]
  end

  def form_fields(_) do
    [
      transaction_id: nil,
      transaction_usd: nil,
      advance_percentage: nil,
      advance_usd: nil,
      importer_fee: nil,
      offer_accepted_declined: nil
    ]
  end
end
