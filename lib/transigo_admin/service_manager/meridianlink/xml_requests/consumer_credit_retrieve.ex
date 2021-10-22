defmodule TransigoAdmin.ServiceManager.Meridianlink.XMLRequests.ConsumerCreditRetrieve do
  defstruct [
    :vendor_order_identifier,
    :first_name,
    :last_name,
    :middle_name,
    :suffix_name,
    :taxpayer_identifier_type,
    :taxpayer_identifier_value
  ]

  def get_request_body(%__MODULE__{} = body)
      when is_binary(body.vendor_order_identifier) and
             is_binary(body.first_name) and is_binary(body.last_name) and
             is_binary(body.middle_name) and
             is_binary(body.suffix_name) and
             is_binary(body.taxpayer_identifier_type) and
             is_binary(body.taxpayer_identifier_value) do
    case Integer.parse(body.vendor_order_identifier) do
      {_, ""} ->
        {:ok,
         """
         <?xml version="1.0" encoding="utf-8"?>
         <MESSAGE MessageType="Request" xmlns="http://www.mismo.org/residential/2009/schemas" xmlns:p2="http://www.w3.org/1999/xlink" xmlns:p3="inetapi/MISMO3_4_MCL_Extension.xsd">
         <ABOUT_VERSIONS>
         <ABOUT_VERSION>
         <DataVersionIdentifier>201703</DataVersionIdentifier>
         </ABOUT_VERSION>
         </ABOUT_VERSIONS>
         <DEAL_SETS>
         <DEAL_SET>
         <DEALS>
         <DEAL>
         <PARTIES>
         	<PARTY p2:label="Party1">
         		<INDIVIDUAL>
         			<NAME>
         				<FirstName>#{body.first_name}</FirstName>
         				<LastName>#{body.last_name}</LastName>
         				<MiddleName>#{body.middle_name}</MiddleName>
         				<SuffixName>#{body.suffix_name}</SuffixName>
         			</NAME>
         		</INDIVIDUAL>
         		<ROLES>
         			<ROLE>
         				<ROLE_DETAIL>
         					<PartyRoleType>Borrower</PartyRoleType>
         				</ROLE_DETAIL>
         			</ROLE>
         		</ROLES>
         		<TAXPAYER_IDENTIFIERS>
         			<TAXPAYER_IDENTIFIER>
         				<TaxpayerIdentifierType>#{body.taxpayer_identifier_type}</TaxpayerIdentifierType>
         				<TaxpayerIdentifierValue>#{body.taxpayer_identifier_value}</TaxpayerIdentifierValue>
         			</TAXPAYER_IDENTIFIER>
         		</TAXPAYER_IDENTIFIERS>
         	</PARTY>
         </PARTIES>
         <RELATIONSHIPS>
         	<!-- Link the Party (the borrower) to the Service (credit order) -->
         	<RELATIONSHIP p2:arcrole="urn:fdc:Meridianlink.com:2017:mortgage/PARTY_IsVerifiedBy_SERVICE" p2:from="Party1" p2:to="Service1" />
         </RELATIONSHIPS>
         <SERVICES>
         	<SERVICE p2:label="Service1">
         		<CREDIT>
         			<CREDIT_REQUEST>
         				<CREDIT_REQUEST_DATAS>
         					<CREDIT_REQUEST_DATA>
         						<CREDIT_REPOSITORY_INCLUDED>
         							<!-- These flags should be left as true to ensure all bureau data present on the file is returned. Can be toggled to filter bureau data -->
         							<CreditRepositoryIncludedEquifaxIndicator>true</CreditRepositoryIncludedEquifaxIndicator>
         							<CreditRepositoryIncludedExperianIndicator>true</CreditRepositoryIncludedExperianIndicator>
         							<CreditRepositoryIncludedTransUnionIndicator>true</CreditRepositoryIncludedTransUnionIndicator>
         						</CREDIT_REPOSITORY_INCLUDED>
         						<CREDIT_REQUEST_DATA_DETAIL>
         							<CreditReportRequestActionType>StatusQuery</CreditReportRequestActionType>
         						</CREDIT_REQUEST_DATA_DETAIL>
         					</CREDIT_REQUEST_DATA>
         				</CREDIT_REQUEST_DATAS>
         			</CREDIT_REQUEST>
         		</CREDIT>
         		<SERVICE_PRODUCT>
         			<SERVICE_PRODUCT_REQUEST>
         				<SERVICE_PRODUCT_DETAIL>
         					<ServiceProductDescription>CreditOrder</ServiceProductDescription>
         					<EXTENSION>
         						<OTHER>
         							<!-- Recommend requesting only the formats you need, to minimize processing time -->
         							<p3:SERVICE_PREFERRED_RESPONSE_FORMATS>
         								<p3:SERVICE_PREFERRED_RESPONSE_FORMAT>
         									<p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>
         										<p3:PreferredResponseFormatType>Html</p3:PreferredResponseFormatType>
         									</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>
         								</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>
         								<p3:SERVICE_PREFERRED_RESPONSE_FORMAT>
         									<p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>
         										<p3:PreferredResponseFormatType>Pdf</p3:PreferredResponseFormatType>
         									</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>
         								</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>
         								<p3:SERVICE_PREFERRED_RESPONSE_FORMAT>
         									<p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>
         										<p3:PreferredResponseFormatType>Xml</p3:PreferredResponseFormatType>
         									</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>
         								</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>
         							</p3:SERVICE_PREFERRED_RESPONSE_FORMATS>
         						</OTHER>
         					</EXTENSION>
         				</SERVICE_PRODUCT_DETAIL>
         			</SERVICE_PRODUCT_REQUEST>
         		</SERVICE_PRODUCT>
         		<SERVICE_PRODUCT_FULFILLMENT>
         			<SERVICE_PRODUCT_FULFILLMENT_DETAIL>
         				<VendorOrderIdentifier>#{body.vendor_order_identifier}</VendorOrderIdentifier>
         			</SERVICE_PRODUCT_FULFILLMENT_DETAIL>
         		</SERVICE_PRODUCT_FULFILLMENT>
         	</SERVICE>
         </SERVICES>
         </DEAL>
         </DEALS>
         </DEAL_SET>
         </DEAL_SETS>
         </MESSAGE>
         """}

      _ ->
        {:error, "Cannot form a valid request body. Input must be a string containing an integer"}
    end
  end

  def get_request_body(_) do
    {:error, "Cannot form a valid request body. Input must be a string"}
  end
end
