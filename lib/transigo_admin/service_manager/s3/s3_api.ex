defmodule TransigoAdmin.ServiceManager.S3.S3Api do
  @behaviour TransigoAdmin.ServiceManager.S3.S3Behavior

  def download_invoice_file(%{
        transaction_uid: transaction_uid,
        exporter: %{exporter_transigo_uid: exporter_uid},
        importer: %{importer_transigo_uid: importer_uid}
      }) do
    invoice_s3_key =
      "exporter/#{exporter_uid}/#{importer_uid}/#{transaction_uid}/#{transaction_uid}_invoice.pdf"

    invoice_file = "temp/#{transaction_uid}_invoice.pdf"

    download =
      ExAws.S3.download_file(
        Application.get_env(:transigo_admin, :s3_bucket_name),
        invoice_s3_key,
        invoice_file
      )
      |> ExAws.request()

    case download do
      {:ok, :done} ->
        {:ok, invoice_file}

      _ ->
        {:error, "Fail to download invoice"}
    end
  end
end
