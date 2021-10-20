defmodule TransigoAdmin.Test.Support.Mock.MeridianlinkMock do
  @behaviour TransigoAdmin.ServiceManager.MeridianlinkBehavior

  alias TransigoAdmin.Account
  alias TransigoAdmin.Account.Contact
  alias TransigoAdmin.ServiceManager.Meridianlink.XMLRequests.ConsumerCreditNew
  alias TransigoAdmin.Repo

  def update_contact_consumer_credit_report_by_quota_id(quota_id) do
    Account.get_contact_by_quota_id(quota_id)
    |> mock_meridianlink_data()

    :ok
  end

  def update_contact_consumer_credit_report(contact_id) do
    Account.get_contact_by_id(contact_id, [:us_place])
    |> mock_meridianlink_data()

    :ok
  end

  def get_consumer_credit_report(
        %Contact{} = contact,
        %ConsumerCreditNew{} = _body_params
      ) do
    contact
    |> mock_meridianlink_data()

    :ok
  end

  defp mock_meridianlink_data(%Contact{} = contact) do
    contact
    |> Contact.changeset(%{
      consumer_credit_score: 650,
      consumer_credit_score_percentile: 94,
      consumer_credit_report_meridianlink: "some xml"
    })
    |> Repo.update()
  end
end
