defmodule TransigoAdmin.ServiceManager.HelloSign.HsMock do
  @behaviour TransigoAdmin.ServiceManager.HelloSign.HsBehavior

  def get_signature_request(_request_id),
    do:
      {:ok,
       %{
         "signature_request" => %{
           "signatures" => [
             %{
               "signer_email_address" => "david@bbiz.com",
               "signature_id" => "some_other_signature_id"
             }
           ]
         }
       }}

  def get_sign_url(_signature_id), do: {:ok, %{"embedded" => %{"sign_url" => "http://hellosign"}}}

  def create_signature_request([]), do: {:ok, %{}}

  def create_signature_request(_),
    do:
      {:ok,
       %{
         "signature_request" => %{
           "signature_request_id" => "signature_request_id",
           "signatures" => [
             %{
               "signer_email_address" => "some_email@some_company.com",
               "signature_id" => "some_signature_id"
             },
             %{
               "signer_email_address" => "david@bbiz.com",
               "signature_id" => "some_other_signature_id"
             }
           ]
         }
       }}

  def fetch_sign_url(_sign_id), do: ""

  def get_signature_file_url(_sign_request_id), do: {:ok, ""}
end
