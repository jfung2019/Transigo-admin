defmodule TransigoAdmin.Meridianlink do
  require Logger

  alias TransigoAdmin.Account
  alias TransigoAdmin.Account.Contact
  alias TransigoAdmin.Meridianlink.XMLRequests.ConsumerCreditNew
  alias TransigoAdmin.Meridianlink.XMLRequests.ConsumerCreditRetrieve
  alias TransigoAdmin.Meridianlink.XMLParser

  @new_consumer_credit_report_retries 3
  @retrieve_consumer_credit_report_retries 90

  @status_codes %{new: "New", processing: "Processing", completed: "Completed", error: "Error"}

  # testing url
  # @base_url "https://demo.mortgagecreditlink.com/inetapi/request_products.aspx"

  # production url
  # @base_url "https://premium.meridianlink.com/inetapi/request_products.aspx"

  # production data url
  # @base_url "https://cdc.meridianlink.com/inetapi/request_products.aspx"

  @test_case %ConsumerCreditNew{
    first_name: "Bill",
    last_name: "Testcase",
    middle_name: "C",
    suffix_name: "JR",
    address_line_text: "8842 48th Ave",
    city_name: "Anthill",
    country_code: "US",
    postal_code: "65488",
    state_code: "MO",
    taxpayer_identifier_type: "SocialSecurityNumber",
    taxpayer_identifier_value: "000000015"
  }

  def update_contact_consumer_credit_report_by_quota_id(quota_id) do
    contact = Account.get_contact_by_quota_id(quota_id)
    request_fields = get_consumer_credit_fields_from_contact(contact)
    get_consumer_credit_report(contact, request_fields)
  end

  def update_contact_consumer_credit_report(contact_id) do
    contact = Account.get_contact_by_id(contact_id, [:us_place])
    request_fields = get_consumer_credit_fields_from_contact(contact)
    get_consumer_credit_report(contact, request_fields)
  end

  def get_consumer_credit_fields_from_contact(contact = %Contact{}) do
    %ConsumerCreditNew{
      first_name: Map.get(contact, :first_name),
      last_name: Map.get(contact, :last_name),
      middle_name: "",
      suffix_name: "",
      address_line_text: contact.us_place.street_address,
      city_name: contact.us_place.city,
      country_code: contact.us_place.country,
      postal_code: contact.us_place.zip_code,
      state_code: contact.us_place.state,
      taxpayer_identifier_type: "SocialSecurityNumber",
      taxpayer_identifier_value: Map.get(contact, :ssn)
    }
  end

  def get_consumer_credit_report(
        %Contact{} = contact,
        %ConsumerCreditNew{} = body_params \\ @test_case
      ) do
    do_get_consumer_credit_report(contact, body_params, 0)
  end

  defp do_get_consumer_credit_report(_, _, @new_consumer_credit_report_retries) do
    Logger.error("Unable to order a consumer credit report. Trying again...")
    {:error, "Unable to order a consumer credit report. Meridianlink error."}
  end

  defp do_get_consumer_credit_report(contact, body_params, step) do
    Logger.info("ordering a new consumer credit report")

    case order_new_consumer_credit_report(body_params) do
      {:ok, res} ->
        Logger.info("successfully ordered a new consumer credit report. Polling for results.")

        %{
          vendor_order_identifier: vendor_order_identifier,
          taxpayer_identifier_value: _taxpayer_identifier_value,
          taxpayer_identifier_type: _taxpayer_identifier_type
        } = response_data = XMLParser.get_new_order_response_data(res.body)

        Logger.info("VendorOrderIdentifier: #{vendor_order_identifier}")

        if same_consumer?(response_data, body_params) do
          Logger.info("consumers match!")
          loop_retrive_credit_report(contact, res.body, vendor_order_identifier)
        else
          Logger.error("Consumers do not match! Meridianlink error")
          {:error, "Consumers do not match! Meridianlink error."}
        end

      {:error, _message} ->
        Logger.error("Unable to order a consumer credit report. Trying again...")
        Process.sleep(1000)
        do_get_consumer_credit_report(contact, body_params, step + 1)
    end
  end

  defp loop_retrive_credit_report(contact, res, vendor_order_identifier) do
    do_loop_retrive_credit_report(contact, res, vendor_order_identifier, 0)
  end

  defp do_loop_retrieve_credit_report(
         _contact,
         _res,
         _vendor_order_identifier,
         @retrieve_consumer_credit_report_retries
       ) do
    Logger.info("Unable to retrive consumer credit report. Too many attempts.")
    :error
  end

  defp do_loop_retrive_credit_report(contact, res, vendor_order_identifier, step) do
    Logger.info("Polling...")
    Process.sleep(1000)

    case retrieve_existing_credit_report(vendor_order_identifier) do
      {:ok, res} ->
        %{status_code: status_code} =
          if(res.body != "" and not is_nil(res.body)) do
            XMLParser.check_retrive_status_code(res.body)
          else
            %{status_code: @status_codes.processing}
          end

        case status_code do
          code when code == @status_codes.completed ->
            Logger.info("Successfully retrived consumer credit report")

            case XMLParser.get_equifax_credit_score_fields(res.body) do
              {:ok,
               %{
                 credit_score_rank_percentile: credit_score_percentile,
                 credit_score_value: credit_score
               }} ->
                case Account.insert_contact_consumer_credit_report(contact, %{
                       consumer_credit_score: credit_score,
                       consumer_credit_score_percentile: credit_score_percentile,
                       consumer_credit_report_meridianlink: res.body
                     }) do
                  {:ok, _contact} ->
                    :ok

                  {:error, _changeset} ->
                    {:error, "Could not update contact with fields"}
                end

              {:error, message} ->
                {:error, message}
            end

          code when code == @status_codes.error ->
            Logger.error("Unable to order a consumer credit report. Meridianlink error.")
            :error

          code when code in [@status_codes.new, @status_codes.processing] ->
            Logger.info("Consumer credit report not ready yet trying again")
            do_loop_retrive_credit_report(contact, res, vendor_order_identifier, step + 1)
        end

      {:error, _message} ->
        do_loop_retrive_credit_report(contact, res, vendor_order_identifier, step + 1)
    end
  end

  defp same_consumer?(
         %{taxpayer_identifier_value: id_val, taxpayer_identifier_type: id_type},
         %ConsumerCreditNew{} = req
       ) do
    id_val == req.taxpayer_identifier_value and id_type == req.taxpayer_identifier_type
  end

  defp get_headers do
    [
      "MCL-Interface": Application.get_env(:transigo_admin, :meridianlink_mcl_interface),
      Authorization: Application.get_env(:transigo_admin, :meridianlink_authorization)
    ]
  end

  defp get_base_url do
    Application.get_env(:transigo_admin, :meridianlink_url)
  end

  defp retrieve_existing_credit_report(vendor_order_identifier) do
    case ConsumerCreditRetrieve.get_request_body(vendor_order_identifier) do
      {:ok, body} ->
        HTTPoison.post(get_base_url(), body, get_headers())

      {:error, message} ->
        {:error, message}
    end
  end

  defp order_new_consumer_credit_report(%ConsumerCreditNew{} = body_params) do
    case ConsumerCreditNew.get_request_body(body_params) do
      {:ok, body} ->
        HTTPoison.post(get_base_url(), body, get_headers())

      {:error, message} ->
        {:error, message}
    end
  end
end
