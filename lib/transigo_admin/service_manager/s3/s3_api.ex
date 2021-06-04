defmodule TransigoAdmin.ServiceManager.S3.S3Api do
  @behaviour TransigoAdmin.ServiceManager.S3.S3Behavior

  def download_file(
        %{
          transaction_uid: transaction_uid,
          exporter: %{exporter_transigo_uid: exporter_uid},
          importer: %{importer_transigo_uid: importer_uid}
        },
        :invoice
      ),
      do: do_download(transaction_uid, exporter_uid, importer_uid, "invoice")

  def download_file(
        %{
          transaction_uid: transaction_uid,
          exporter: %{exporter_transigo_uid: exporter_uid},
          importer: %{importer_transigo_uid: importer_uid}
        },
        :po
      ),
      do: do_download(transaction_uid, exporter_uid, importer_uid, "po")

  def upload_file(
        %{
          transaction_uid: transaction_uid,
          exporter: %{exporter_transigo_uid: exporter_uid},
          importer: %{importer_transigo_uid: importer_uid}
        },
        file,
        :invoice
      ),
      do: do_upload_file(transaction_uid, exporter_uid, importer_uid, file, "invoice")

  def upload_file(
        %{
          transaction_uid: transaction_uid,
          exporter: %{exporter_transigo_uid: exporter_uid},
          importer: %{importer_transigo_uid: importer_uid}
        },
        file,
        :po
      ),
      do: do_upload_file(transaction_uid, exporter_uid, importer_uid, file, "po")

  def get_file_presigned_url(key) do
    ExAws.Config.new(:s3)
    |> ExAws.S3.presigned_url(:get, Application.get_env(:transigo_admin, :s3_bucket_name), key)
  end

  defp do_download(transaction_uid, exporter_uid, importer_uid, type) do
    s3_key =
      "exporter/#{exporter_uid}/#{importer_uid}/#{transaction_uid}/#{transaction_uid}_#{type}.pdf"

    {:ok, temp} = Briefly.create(extname: ".pdf")

    download =
      ExAws.S3.download_file(
        Application.get_env(:transigo_admin, :s3_bucket_name),
        s3_key,
        temp
      )
      |> ExAws.request()

    case download do
      {:ok, :done} ->
        {:ok, temp}

      _ ->
        {:error, "Fail to download invoice"}
    end
  end

  defp do_upload_file(transaction_uid, exporter_uid, importer_uid, file, type) do
    key =
      "exporter/#{exporter_uid}/#{importer_uid}/#{transaction_uid}/#{transaction_uid}_#{type}.pdf"

    file
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(Application.get_env(:transigo_admin, :s3_bucket_name), key, [
      {:content_type, "application/pdf"}
    ])
    |> ExAws.request()
  end
end
