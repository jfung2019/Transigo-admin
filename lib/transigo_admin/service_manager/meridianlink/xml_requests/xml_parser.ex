defmodule TransigoAdmin.ServiceManager.Meridianlink.XMLRequests.XMLParser do
  import SweetXml

  @vendor_order_identifier_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/SERVICE_PRODUCT_FULFILLMENT/SERVICE_PRODUCT_FULFILLMENT_DETAIL/VendorOrderIdentifier/text()"

  @taxpayer_identifier_value_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/PARTIES/PARTY/TAXPAYER_IDENTIFIERS/TAXPAYER_IDENTIFIER/TaxpayerIdentifierValue/text()"

  @taxpayer_identifier_type_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/PARTIES/PARTY/TAXPAYER_IDENTIFIERS/TAXPAYER_IDENTIFIER/TaxpayerIdentifierType/text()"

  @status_code_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/STATUSES/STATUS/StatusCode/text()"

  @status_code_description_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/STATUSES/STATUS/StatusDescription/text()"

  # @credit_source_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/CREDIT/CREDIT_RESPONSE/CREDIT_TRADE_REFERENCES/CREDIT_TRADE_REFERENCE/CREDIT_REPOSITORIES/CREDIT_REPOSITORY/CreditRepositorySourceType/text()"l
  @credit_source_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/CREDIT/CREDIT_RESPONSE/CREDIT_SCORES/CREDIT_SCORE/CREDIT_SCORE_DETAIL/CreditScoreModelNameType/text()"l
  # @credit_source_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/CREDIT/CREDIT_RESPONSE/CREDIT_SCORES/CREDIT_SCORE"l

  @credit_score_rank_percentile_value_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/CREDIT/CREDIT_RESPONSE/CREDIT_SCORES/CREDIT_SCORE/CREDIT_SCORE_DETAIL/CreditScoreRankPercentileValue/text()"l

  @credit_score_value_x_path ~x"/MESSAGE/DEAL_SETS/DEAL_SET/DEALS/DEAL/SERVICES/SERVICE/CREDIT/CREDIT_RESPONSE/CREDIT_SCORES/CREDIT_SCORE/CREDIT_SCORE_DETAIL/CreditScoreValue/text()"l

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

  def get_credit_score_fields(xml) do
    parsed_xml = parse(xml)

    credit_source = xpath(parsed_xml, @credit_source_x_path)
    credit_score_rank_percentile = xpath(parsed_xml, @credit_score_rank_percentile_value_x_path)
    credit_score_value = xpath(parsed_xml, @credit_score_value_x_path)

    Enum.zip([credit_source, credit_score_rank_percentile, credit_score_value])
    |> Enum.map(fn {source, percentile, score} ->
      %{
        credit_source: to_string(source),
        credit_score_rank_percentile: to_string(percentile),
        credit_score_value: to_string(score)
      }
    end)
  end

  def get_equifax_credit_score_fields(xml) do
    res =
      xml
      |> get_credit_score_fields()
      |> Enum.filter(fn x ->
        FuzzyCompare.similarity(x.credit_source, "equifax") == 1.0
      end)

    if length(res) == 1 do
      {:ok, List.first(res)}
    else
      {:error, "Could not find equifax credit score fields"}
    end
  end
end
