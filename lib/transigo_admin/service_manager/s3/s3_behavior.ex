defmodule TransigoAdmin.ServiceManager.S3.S3Behavior do
  alias TransigoAdmin.Credit.Transaction

  @callback download_invoice_file(Transaction.t()) ::
              {:ok, String.t()} | {:error, HTTPoison.Error.t()}
end
