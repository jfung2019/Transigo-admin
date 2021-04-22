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

    File.mkdir_p("temp")

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

# exporter/Texp-b401-41f0-fecd-5016-60ad-c97e/Timp-7cbd-d35a-3e5c-ec6d-9e05-a5b8/Ttra-4c6f-52e2-2f14-2cb2-ee94-14d0/Ttra-4c6f-52e2-2f14-2cb2-ee94-14d0_invoice.pdf
