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

  def render("offer.json", %{offer: %{transaction: transaction} = offer}) do
    %{
      result: %{
        offer: %{
          transactionTransigoUID: transaction.transaction_uid,
          transactionUSD: offer.transaction_usd,
          downPaymentPercentage: offer.advance_percentage,
          downPaymentUSD: offer.advance_usd,
          creditTermDays: transaction.credit_term_days,
          secondInstallmentUSD: transaction.second_installment_usd,
          secondInstallmentDate: cal_second_installment_date(transaction),
          importerFee: offer.importer_fee,
          offerAcceptedDeclined: offer.offer_accepted_declined,
          offerAcceptDeclineDateTime: offer.offer_accept_decline_datetime
        }
      }
    }
  end

  defp cal_second_installment_date(%{invoice_date: nil}), do: nil

  defp cal_second_installment_date(%{invoice_date: invoice_date, credit_term_days: credit_term_days}) do
    invoice_date
    |> Timex.shift(days: credit_term_days)
  end
end
