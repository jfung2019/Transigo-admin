defmodule TransigoAdmin.ServiceManager.S3.S3Mock do
  @behaviour TransigoAdmin.ServiceManager.S3.S3Behavior

  def download_invoice_file(%{transaction_uid: transaction_uid}),
    do: {:ok, "#{transaction_uid}_invoice.pdf"}
end
