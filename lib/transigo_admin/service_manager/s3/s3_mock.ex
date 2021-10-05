defmodule TransigoAdmin.ServiceManager.S3.S3Mock do
  @behaviour TransigoAdmin.ServiceManager.S3.S3Behavior

  def download_file(%{transaction_uid: transaction_uid}, :invoice),
    do: {:ok, "#{transaction_uid}_invoice.pdf"}

  def upload_file(%{transaction_uid: transaction_uid}, _key, :invoice),
    do: {:ok, "#{transaction_uid}_invoice.pdf"}

  def get_file_presigned_url(_key), do: {:ok, "url"}

  def check_file_exists?(_file), do: true
end
