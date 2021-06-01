defmodule TransigoAdmin.ServiceManager.S3.S3Mock do
  @behaviour TransigoAdmin.ServiceManager.S3.S3Behavior

  def download_invoice_po_file(%{transaction_uid: transaction_uid}, :invoice),
    do: {:ok, "#{transaction_uid}_invoice.pdf"}
end
