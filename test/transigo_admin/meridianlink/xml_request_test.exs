defmodule TransigoAdmin.ServiceManager.Meridianlink.XMLRequestTest do
  use TransigoAdmin.DataCase, async: true

  alias TransigoAdmin.ServiceManager.Meridianlink.XMLRequests.ConsumerCreditNew
  alias TransigoAdmin.ServiceManager.Meridianlink.XMLRequests.ConsumerCreditRetrieve

  test "produces a valid new consumer credit request body with valid inputs" do
    valid_params = %ConsumerCreditNew{
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

    assert ConsumerCreditNew.get_request_body(valid_params) ==
             {:ok,
              "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<MESSAGE xmlns=\"http://www.mismo.org/residential/2009/schemas\" xmlns:p2=\"http://www.w3.org/1999/xlink\" xmlns:p3=\"inetapi/MISMO3_4_MCL_Extension.xsd\" MessageType=\"Request\">\n<ABOUT_VERSIONS>\n<ABOUT_VERSION>\n<DataVersionIdentifier>201703</DataVersionIdentifier>\n</ABOUT_VERSION>\n</ABOUT_VERSIONS>\n<DEAL_SETS>\n<DEAL_SET>\n<DEALS>\n<DEAL>\n\t<PARTIES>\n\t\t<PARTY p2:label=\"Party1\">\n\t\t\t<INDIVIDUAL>\n\t\t\t\t<NAME>\n\t\t\t\t\t<FirstName>Bill</FirstName>\n\t\t\t\t\t<LastName>Testcase</LastName>\n\t\t\t\t\t<MiddleName>C</MiddleName>\n         <SuffixName>JR</SuffixName>\n\t\t\t\t</NAME>\n\t\t\t</INDIVIDUAL>\n\t\t\t<ROLES>\n\t\t\t\t<ROLE>\n\t\t\t\t\t<BORROWER>\n\t\t\t\t\t\t<RESIDENCES>\n\t\t\t\t\t\t\t<RESIDENCE>\n\t\t\t\t\t\t\t\t<ADDRESS>\n\t\t\t\t\t\t\t\t\t<AddressLineText>8842 48th Ave</AddressLineText>\n\t\t\t\t\t\t\t\t\t<CityName>Anthill</CityName>\n\t\t\t\t\t\t\t\t\t<CountryCode>US</CountryCode>\n\t\t\t\t\t\t\t\t\t<PostalCode>65488</PostalCode>\n\t\t\t\t\t\t\t\t\t<StateCode>MO</StateCode>\n\t\t\t\t\t\t\t\t</ADDRESS>\n\t\t\t\t\t\t\t\t<RESIDENCE_DETAIL>\n\t\t\t\t\t\t\t\t\t<BorrowerResidencyType>Current</BorrowerResidencyType>\n\t\t\t\t\t\t\t\t</RESIDENCE_DETAIL>\n\t\t\t\t\t\t\t</RESIDENCE>\n\t\t\t\t\t\t</RESIDENCES>\n\t\t\t\t\t</BORROWER>\n\t\t\t\t\t<ROLE_DETAIL>\n\t\t\t\t\t\t<PartyRoleType>Borrower</PartyRoleType>\n\t\t\t\t\t</ROLE_DETAIL>\n\t\t\t\t</ROLE>\n\t\t\t</ROLES>\n\t\t\t<TAXPAYER_IDENTIFIERS>\n\t\t\t\t<TAXPAYER_IDENTIFIER>\n\t\t\t\t\t<TaxpayerIdentifierType>SocialSecurityNumber</TaxpayerIdentifierType>\n\t\t\t\t\t<TaxpayerIdentifierValue>000000015</TaxpayerIdentifierValue>\n\t\t\t\t</TAXPAYER_IDENTIFIER>\n\t\t\t</TAXPAYER_IDENTIFIERS>\n\t\t</PARTY>\n\t</PARTIES>\n\t<RELATIONSHIPS>\n\t\t<!-- Link borrower to the service -->\n\t\t<RELATIONSHIP p2:arcrole=\"urn:fdc:Meridianlink.com:2017:mortgage/PARTY_IsVerifiedBy_SERVICE\" p2:from=\"Party1\" p2:to=\"Service1\"/>\n\t</RELATIONSHIPS>\n\t<SERVICES>\n\t\t<SERVICE p2:label=\"Service1\">\n\t\t\t<CREDIT>\n\t\t\t\t<CREDIT_REQUEST>\n\t\t\t\t\t<CREDIT_REQUEST_DATAS>\n\t\t\t\t\t\t<CREDIT_REQUEST_DATA>\n\t\t\t\t\t\t\t<CREDIT_REPOSITORY_INCLUDED>\n\t\t\t\t\t\t\t\t<CreditRepositoryIncludedEquifaxIndicator>true</CreditRepositoryIncludedEquifaxIndicator>\n\t\t\t\t\t\t\t\t<CreditRepositoryIncludedExperianIndicator>true</CreditRepositoryIncludedExperianIndicator>\n\t\t\t\t\t\t\t\t<CreditRepositoryIncludedTransUnionIndicator>true</CreditRepositoryIncludedTransUnionIndicator>\n\t\t\t\t\t\t\t\t<EXTENSION>\n\t\t\t\t\t\t\t\t\t<OTHER>\n\t\t\t\t\t\t\t\t\t\t<p3:RequestEquifaxScore>true</p3:RequestEquifaxScore>\n\t\t\t\t\t\t\t\t\t\t<p3:RequestExperianFraud>true</p3:RequestExperianFraud>\n\t\t\t\t\t\t\t\t\t\t<p3:RequestExperianScore>true</p3:RequestExperianScore>\n\t\t\t\t\t\t\t\t\t\t<p3:RequestTransUnionFraud>true</p3:RequestTransUnionFraud>\n\t\t\t\t\t\t\t\t\t\t<p3:RequestTransUnionScore>true</p3:RequestTransUnionScore>\n\t\t\t\t\t\t\t\t\t</OTHER>\n\t\t\t\t\t\t\t\t</EXTENSION>\n\t\t\t\t\t\t\t</CREDIT_REPOSITORY_INCLUDED>\n\t\t\t\t\t\t\t<CREDIT_REQUEST_DATA_DETAIL>\n\t\t\t\t\t\t\t\t<CreditReportRequestActionType>Submit</CreditReportRequestActionType>\n\t\t\t\t\t\t\t</CREDIT_REQUEST_DATA_DETAIL>\n\t\t\t\t\t\t</CREDIT_REQUEST_DATA>\n\t\t\t\t\t</CREDIT_REQUEST_DATAS>\n\t\t\t\t</CREDIT_REQUEST>\n\t\t\t</CREDIT>\n\t\t\t<SERVICE_PRODUCT>\n\t\t\t\t<SERVICE_PRODUCT_REQUEST>\n\t\t\t\t\t<SERVICE_PRODUCT_DETAIL>\n\t\t\t\t\t\t<ServiceProductDescription>CreditOrder</ServiceProductDescription>\n\t\t\t\t\t\t<EXTENSION>\n\t\t\t\t\t\t\t<OTHER>\n\t\t\t\t\t\t\t\t<!-- Recommend requesting only the formats you need, to minimize processing time -->\n\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMATS>\n\t\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t\t\t\t<p3:PreferredResponseFormatType>Xml</p3:PreferredResponseFormatType>\n\t\t\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t\t\t\t<p3:PreferredResponseFormatType>Html</p3:PreferredResponseFormatType>\n\t\t\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t\t\t\t<p3:PreferredResponseFormatType>Pdf</p3:PreferredResponseFormatType>\n\t\t\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMATS>\n\t\t\t\t\t\t\t</OTHER>\n\t\t\t\t\t\t</EXTENSION>\n\t\t\t\t\t</SERVICE_PRODUCT_DETAIL>\n\t\t\t\t</SERVICE_PRODUCT_REQUEST>\n\t\t\t</SERVICE_PRODUCT>\n\t\t</SERVICE>\n\t</SERVICES>\n</DEAL>\n</DEALS>\n</DEAL_SET>\n</DEAL_SETS>\n</MESSAGE>\n"}
  end

  test "produces error with ivalid params for new consumer credit" do
    invalid_params = %ConsumerCreditNew{
      first_name: "Bill",
      last_name: 123,
      middle_name: "C",
      suffix_name: "JR",
      address_line_text: "8842 48th Ave",
      city_name: "Anthill",
      country_code: "US",
      postal_code: "65488",
      state_code: "MO",
      taxpayer_identifier_type: 'wrong type',
      taxpayer_identifier_value: "000000015"
    }

    assert ConsumerCreditNew.get_request_body(invalid_params) ==
             {:error, "cannot form a valid request body, are your inputs well formed?"}
  end

  test "produces valid consumer credit retrive body with valid params" do
    valid_params = %ConsumerCreditRetrieve{
      vendor_order_identifier: "12345",
      first_name: "Bill",
      last_name: "Testcase",
      middle_name: "",
      suffix_name: "",
      taxpayer_identifier_type: "SocialSecurityNumber",
      taxpayer_identifier_value: "0000000015"
    }

    assert ConsumerCreditRetrieve.get_request_body(valid_params) ==
             {:ok,
              "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<MESSAGE MessageType=\"Request\" xmlns=\"http://www.mismo.org/residential/2009/schemas\" xmlns:p2=\"http://www.w3.org/1999/xlink\" xmlns:p3=\"inetapi/MISMO3_4_MCL_Extension.xsd\">\n<ABOUT_VERSIONS>\n<ABOUT_VERSION>\n<DataVersionIdentifier>201703</DataVersionIdentifier>\n</ABOUT_VERSION>\n</ABOUT_VERSIONS>\n<DEAL_SETS>\n<DEAL_SET>\n<DEALS>\n<DEAL>\n<PARTIES>\n\t<PARTY p2:label=\"Party1\">\n\t\t<INDIVIDUAL>\n\t\t\t<NAME>\n\t\t\t\t<FirstName>Bill</FirstName>\n\t\t\t\t<LastName>Testcase</LastName>\n\t\t\t\t<MiddleName></MiddleName>\n\t\t\t\t<SuffixName></SuffixName>\n\t\t\t</NAME>\n\t\t</INDIVIDUAL>\n\t\t<ROLES>\n\t\t\t<ROLE>\n\t\t\t\t<ROLE_DETAIL>\n\t\t\t\t\t<PartyRoleType>Borrower</PartyRoleType>\n\t\t\t\t</ROLE_DETAIL>\n\t\t\t</ROLE>\n\t\t</ROLES>\n\t\t<TAXPAYER_IDENTIFIERS>\n\t\t\t<TAXPAYER_IDENTIFIER>\n\t\t\t\t<TaxpayerIdentifierType>SocialSecurityNumber</TaxpayerIdentifierType>\n\t\t\t\t<TaxpayerIdentifierValue>0000000015</TaxpayerIdentifierValue>\n\t\t\t</TAXPAYER_IDENTIFIER>\n\t\t</TAXPAYER_IDENTIFIERS>\n\t</PARTY>\n</PARTIES>\n<RELATIONSHIPS>\n\t<!-- Link the Party (the borrower) to the Service (credit order) -->\n\t<RELATIONSHIP p2:arcrole=\"urn:fdc:Meridianlink.com:2017:mortgage/PARTY_IsVerifiedBy_SERVICE\" p2:from=\"Party1\" p2:to=\"Service1\" />\n</RELATIONSHIPS>\n<SERVICES>\n\t<SERVICE p2:label=\"Service1\">\n\t\t<CREDIT>\n\t\t\t<CREDIT_REQUEST>\n\t\t\t\t<CREDIT_REQUEST_DATAS>\n\t\t\t\t\t<CREDIT_REQUEST_DATA>\n\t\t\t\t\t\t<CREDIT_REPOSITORY_INCLUDED>\n\t\t\t\t\t\t\t<!-- These flags should be left as true to ensure all bureau data present on the file is returned. Can be toggled to filter bureau data -->\n\t\t\t\t\t\t\t<CreditRepositoryIncludedEquifaxIndicator>true</CreditRepositoryIncludedEquifaxIndicator>\n\t\t\t\t\t\t\t<CreditRepositoryIncludedExperianIndicator>true</CreditRepositoryIncludedExperianIndicator>\n\t\t\t\t\t\t\t<CreditRepositoryIncludedTransUnionIndicator>true</CreditRepositoryIncludedTransUnionIndicator>\n\t\t\t\t\t\t</CREDIT_REPOSITORY_INCLUDED>\n\t\t\t\t\t\t<CREDIT_REQUEST_DATA_DETAIL>\n\t\t\t\t\t\t\t<CreditReportRequestActionType>StatusQuery</CreditReportRequestActionType>\n\t\t\t\t\t\t</CREDIT_REQUEST_DATA_DETAIL>\n\t\t\t\t\t</CREDIT_REQUEST_DATA>\n\t\t\t\t</CREDIT_REQUEST_DATAS>\n\t\t\t</CREDIT_REQUEST>\n\t\t</CREDIT>\n\t\t<SERVICE_PRODUCT>\n\t\t\t<SERVICE_PRODUCT_REQUEST>\n\t\t\t\t<SERVICE_PRODUCT_DETAIL>\n\t\t\t\t\t<ServiceProductDescription>CreditOrder</ServiceProductDescription>\n\t\t\t\t\t<EXTENSION>\n\t\t\t\t\t\t<OTHER>\n\t\t\t\t\t\t\t<!-- Recommend requesting only the formats you need, to minimize processing time -->\n\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMATS>\n\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t\t\t<p3:PreferredResponseFormatType>Html</p3:PreferredResponseFormatType>\n\t\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t\t\t<p3:PreferredResponseFormatType>Pdf</p3:PreferredResponseFormatType>\n\t\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t\t\t<p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t\t\t<p3:PreferredResponseFormatType>Xml</p3:PreferredResponseFormatType>\n\t\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT_DETAIL>\n\t\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMAT>\n\t\t\t\t\t\t\t</p3:SERVICE_PREFERRED_RESPONSE_FORMATS>\n\t\t\t\t\t\t</OTHER>\n\t\t\t\t\t</EXTENSION>\n\t\t\t\t</SERVICE_PRODUCT_DETAIL>\n\t\t\t</SERVICE_PRODUCT_REQUEST>\n\t\t</SERVICE_PRODUCT>\n\t\t<SERVICE_PRODUCT_FULFILLMENT>\n\t\t\t<SERVICE_PRODUCT_FULFILLMENT_DETAIL>\n\t\t\t\t<VendorOrderIdentifier>12345</VendorOrderIdentifier>\n\t\t\t</SERVICE_PRODUCT_FULFILLMENT_DETAIL>\n\t\t</SERVICE_PRODUCT_FULFILLMENT>\n\t</SERVICE>\n</SERVICES>\n</DEAL>\n</DEALS>\n</DEAL_SET>\n</DEAL_SETS>\n</MESSAGE>\n"}
  end

  test "produces error on consumer credit retrive body with invalid params" do
    invalid_params = %ConsumerCreditRetrieve{
      vendor_order_identifier: "123abc",
      first_name: "Bill",
      last_name: "Testcase",
      middle_name: "",
      suffix_name: "",
      taxpayer_identifier_type: "SocialSecurityNumber",
      taxpayer_identifier_value: "0000000015"
    }

    assert ConsumerCreditRetrieve.get_request_body(invalid_params) ==
             {:error,
              "Cannot form a valid request body. Input must be a string containing an integer"}

    invalid_params = %ConsumerCreditRetrieve{
      vendor_order_identifier: "12345",
      first_name: "Bill",
      last_name: "Testcase",
      middle_name: "",
      suffix_name: "",
      taxpayer_identifier_type: "SocialSecurityNumber",
      taxpayer_identifier_value: 123
    }

    assert ConsumerCreditRetrieve.get_request_body(invalid_params) ==
             {:error, "Cannot form a valid request body. Input must be a string"}
  end
end
