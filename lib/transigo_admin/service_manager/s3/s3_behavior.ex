defmodule TransigoAdmin.ServiceManager.S3.S3Behavior do
  alias TransigoAdmin.Credit.Transaction

  @callback download_invoice_po_file(Transaction.t(), atom) ::
              {:ok, String.t()} | {:error, HTTPoison.Error.t()}

  @callback get_file_presigned_url(String.t()) :: {:ok, String.t()} | {:error, String.t()}
end
