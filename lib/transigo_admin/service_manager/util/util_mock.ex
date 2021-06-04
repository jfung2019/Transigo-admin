defmodule TransigoAdmin.ServiceManager.Util.UtilMock do
  @behaviour TransigoAdmin.ServiceManager.Util.UtilBehavior

  def get_uid("mes"), do: "Tmes-1234-abcd-1234-abcd"

  def create_importer(_param), do: {:ok, %HTTPoison.Response{body: ""}}

  def generate_assignment_notice(_payload),
    do: {:ok, "assignment_notice.pdf"}

  def generate_exporter_msa(_payload), do: {:ok, "msa.pdf"}

  def generate_transaction_doc(_payload),
    do: {:ok, "transaction.pdf"}
end
