defmodule TransigoAdmin.Meridianlink.XMLRequests.ConsumerCreditNew do
  defstruct [
    :first_name,
    :last_name,
    :middle_name,
    :suffix_name,
    :address_line_text,
    :city_name,
    :country_code,
    :postal_code,
    :state_code,
    :taxpayer_identifier_type,
    :taxpayer_identifier_value
  ]

  def get_request_body(%__MODULE__{} = body)
      when is_binary(body.first_name) and is_binary(body.last_name) and
             is_binary(body.middle_name) and
             is_binary(body.suffix_name) and is_binary(body.address_line_text) and
             is_binary(body.city_name) and
             is_binary(body.country_code) and is_binary(body.postal_code) and
             is_binary(body.state_code) and
             is_binary(body.taxpayer_identifier_type) and
             is_binary(body.taxpayer_identifier_value) do
    {:ok,
     """
     <?xml version="1.0" encoding="utf-8"?>
     <MESSAGE xmlns="http://www.mismo.org/residential/2009/schemas" xmlns:p2="http://www.w3.org/1999/xlink" xmlns:p3="inetapi/MISMO3_4_MCL_Extension.xsd" MessageType="Request">
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
     					<BORROWER>
     						<RESIDENCES>
     							<RESIDENCE>
     								<ADDRESS>
     									<AddressLineText>#{body.address_line_text}</AddressLineText>
     									<CityName>#{body.city_name}</CityName>
     									<CountryCode>#{body.country_code}</CountryCode>
     									<PostalCode>#{body.postal_code}</PostalCode>
     									<StateCode>#{body.state_code}</StateCode>
     								</ADDRESS>
     								<RESIDENCE_DETAIL>
     									<BorrowerResidencyType>Current</BorrowerResidencyType>
     								</RESIDENCE_DETAIL>
     							</RESIDENCE>
     						</RESIDENCES>
     					</BORROWER>
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
     		<!-- Link borrower to the service -->
     		<RELATIONSHIP p2:arcrole="urn:fdc:Meridianlink.com:2017:mortgage/PARTY_IsVerifiedBy_SERVICE" p2:from="Party1" p2:to="Service1"/>
     	</RELATIONSHIPS>
     	<SERVICES>
     		<SERVICE p2:label="Service1">
     			<CREDIT>
     				<CREDIT_REQUEST>
     					<CREDIT_REQUEST_DATAS>
     						<CREDIT_REQUEST_DATA>
     							<CREDIT_REPOSITORY_INCLUDED>
     								<CreditRepositoryIncludedEquifaxIndicator>true</CreditRepositoryIncludedEquifaxIndicator>
     								<CreditRepositoryIncludedExperianIndicator>true</CreditRepositoryIncludedExperianIndicator>
     								<CreditRepositoryIncludedTransUnionIndicator>true</CreditRepositoryIncludedTransUnionIndicator>
     								<EXTENSION>
     									<OTHER>
     										<p3:RequestEquifaxScore>true</p3:RequestEquifaxScore>
     										<p3:RequestExperianFraud>true</p3:RequestExperianFraud>
     										<p3:RequestExperianScore>true</p3:RequestExperianScore>
     										<p3:RequestTransUnionFraud>true</p3:RequestTransUnionFraud>
     										<p3:RequestTransUnionScore>true</p3:RequestTransUnionScore>
     									</OTHER>
     								</EXTENSION>
     							</CREDIT_REPOSITORY_INCLUDED>
     							<CREDIT_REQUEST_DATA_DETAIL>
     								<CreditReportRequestActionType>Submit</CreditReportRequestActionType>
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
     											<p3:PreferredResponseFormatType>Xml</p3:PreferredResponseFormatType>
     										</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>
     									</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>
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
     								</p3:SERVICE_PREFERRED_RESPONSE_FORMATS>
     							</OTHER>
     						</EXTENSION>
     					</SERVICE_PRODUCT_DETAIL>
     				</SERVICE_PRODUCT_REQUEST>
     			</SERVICE_PRODUCT>
     		</SERVICE>
     	</SERVICES>
     </DEAL>
     </DEALS>
     </DEAL_SET>
     </DEAL_SETS>
     </MESSAGE>
     """}
  end

  def get_request_body(_) do
    {:error, "cannot form a valid request body, are your inputs well formed?"}
  end
end
