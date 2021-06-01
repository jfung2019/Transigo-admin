defmodule TransigoAdmin.ServiceManager.S3.S3Behavior do
  alias TransigoAdmin.Credit.Transaction

  @callback download_invoice_po_file(Transaction.t(), atom) ::
              {:ok, String.t()} | {:error, HTTPoison.Error.t()}
end
