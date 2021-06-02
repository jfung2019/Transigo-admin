defmodule TransigoAdmin.ServiceManager.S3.S3Api do
  @behaviour TransigoAdmin.ServiceManager.S3.S3Behavior

  def download_invoice_po_file(
        %{
          transaction_uid: transaction_uid,
          exporter: %{exporter_transigo_uid: exporter_uid},
          importer: %{importer_transigo_uid: importer_uid}
        },
        :invoice
      ),
      do: do_download_invoice_po(transaction_uid, exporter_uid, importer_uid, "invoice")

  def download_invoice_po_file(
        %{
          transaction_uid: transaction_uid,
          exporter: %{exporter_transigo_uid: exporter_uid},
          importer: %{importer_transigo_uid: importer_uid}
        },
        :po
      ),
      do: do_download_invoice_po(transaction_uid, exporter_uid, importer_uid, "po")

  def get_file_presigned_url(key) do
    ExAws.Config.new(:s3)
    |> ExAws.S3.presigned_url(:get, Application.get_env(:transigo_admin, :s3_bucket_name), key)
  end

  defp do_download_invoice_po(transaction_uid, exporter_uid, importer_uid, type) do
    s3_key =
      "exporter/#{exporter_uid}/#{importer_uid}/#{transaction_uid}/#{transaction_uid}_#{type}.pdf"

    file = "temp/#{transaction_uid}_#{type}.pdf"

    File.mkdir_p("temp")

    download =
      ExAws.S3.download_file(
        Application.get_env(:transigo_admin, :s3_bucket_name),
        s3_key,
        file
      )
      |> ExAws.request()

    case download do
      {:ok, :done} ->
        {:ok, file}

      _ ->
        {:error, "Fail to download invoice"}
    end
  end
end

# exporter/Texp-b401-41f0-fecd-5016-60ad-c97e/Timp-7cbd-d35a-3e5c-ec6d-9e05-a5b8/Ttra-4c6f-52e2-2f14-2cb2-ee94-14d0/Ttra-4c6f-52e2-2f14-2cb2-ee94-14d0_invoice.pdf
