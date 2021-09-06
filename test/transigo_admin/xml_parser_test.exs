defmodule TransigoAdmin.Meridianlink.XMLParserTest do
  use TransigoAdmin.DataCase, async: false

  alias TransigoAdmin.Meridianlink.XMLParser

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
end
