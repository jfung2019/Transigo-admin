defmodule TransigoAdmin.ServiceManager.Util.UtilMock do
  @behaviour TransigoAdmin.ServiceManager.Util.UtilBehavior

  def get_message_uid, do: "Tmes-1234-abcd-1234-abcd"

  def create_importer(_param), do: {:ok, %HTTPoison.Response{body: ""}}

  def generate_assignment_notice(_payload, transaction_uid),
    do: {:ok, "temp/#{transaction_uid}_assignment_notice.pdf"}

  def generate_exporter_msa(_payload, exporter_uid), do: {:ok, "temp/#{exporter_uid}_msa.pdf"}

  def generate_exporter_msa(_payload, transaction_uid),
    do: {:ok, "temp/#{transaction_uid}_transaction.pdf"}
end
