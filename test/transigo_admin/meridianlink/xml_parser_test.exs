defmodule TransigoAdmin.ServiceManager.Meridianlink.XMLRequests.XMLParserTest do
  use TransigoAdmin.DataCase, async: true

  alias TransigoAdmin.ServiceManager.Meridianlink.XMLRequests.XMLParser

  test "can parse desired fields from consumer credit retrive response" do
    {:ok, xml} =
      ["test", "support", "meridianlink", "consumer_credit_retrieve_response.xml"]
      |> Path.join()
      |> File.read()

    assert XMLParser.get_credit_score_fields(xml) == [
             %{
               credit_score_rank_percentile: "34",
               credit_score_value: "0669",
               credit_source: "ExperianFairIsaac"
             },
             %{
               credit_score_rank_percentile: "35",
               credit_score_value: "683",
               credit_source: "FICORiskScoreClassic04"
             },
             %{
               credit_score_rank_percentile: "29",
               credit_score_value: "00658",
               credit_source: "EquifaxBeacon5.0"
             }
           ]
  end

  test "can get Equifax credit score and percentil" do
    {:ok, xml} =
      ["test", "support", "meridianlink", "consumer_credit_retrieve_response.xml"]
      |> Path.join()
      |> File.read()

    assert {:ok,
            %{
              credit_score_value: "00658",
              credit_score_rank_percentile: "29",
              credit_source: _
            }} = XMLParser.get_equifax_credit_score_fields(xml)
  end

  test "can parse desired fields from new consumer credit response" do
    {:ok, xml} =
      ["test", "support", "meridianlink", "consumer_credit_new_response.xml"]
      |> Path.join()
      |> File.read()

    assert XMLParser.get_new_order_response_data(xml) == %{
             taxpayer_identifier_type: "SocialSecurityNumber",
             taxpayer_identifier_value: "000000015",
             vendor_order_identifier: "1227056"
           }

    assert XMLParser.check_retrive_status_code(xml) == %{
             status_code: "New",
             status_code_description: "NOT READY"
           }
  end
end
