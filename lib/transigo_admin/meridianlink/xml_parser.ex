defmodule TransigoAdmin.Meridianlink.XMLParser do
  import SweetXml

  @vendor_order_identifier_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/SERVICE_PRODUCT_FULFILLMENT/SERVICE_PRODUCT_FULFILLMENT_DETAIL/VendorOrderIdentifier/text()"

  @taxpayer_identifier_value_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/PARTIES/PARTY/TAXPAYER_IDENTIFIERS/TAXPAYER_IDENTIFIER/TaxpayerIdentifierValue/text()"

  @taxpayer_identifier_type_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/PARTIES/PARTY/TAXPAYER_IDENTIFIERS/TAXPAYER_IDENTIFIER/TaxpayerIdentifierType/text()"

  @status_code_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/STATUSES/STATUS/StatusCode/text()"

  @status_code_description_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/STATUSES/STATUS/StatusDescription/text()"

  def get_new_order_response_data(xml) do
    parsed_xml = parse(xml)

    vendor_order_identifier = xpath(parsed_xml, @vendor_order_identifier_x_path)
    taxpayer_identifier_value = xpath(parsed_xml, @taxpayer_identifier_value_x_path)
    taxpayer_identifier_type = xpath(parsed_xml, @taxpayer_identifier_type_x_path)

    %{
      vendor_order_identifier: to_string(vendor_order_identifier),
      taxpayer_identifier_value: to_string(taxpayer_identifier_value),
      taxpayer_identifier_type: to_string(taxpayer_identifier_type)
    }
  end

  def check_retrive_status_code(xml) do
    parsed_xml = parse(xml)

    status_code = xpath(parsed_xml, @status_code_x_path)
    status_code_description = xpath(parsed_xml, @status_code_description_x_path)

    %{
      status_code: to_string(status_code),
      status_code_description: to_string(status_code_description)
    }
  end
end
