@EndUserText.label: 'Travel BO Projection view'
@AccessControl.authorizationCheck: #CHECK
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity ZC_RAP_TRAVEL_123
  as projection on ZI_RAP_Travel_DK_123 as Travel
{
  key TravelUuid,
      @Search.defaultSearchElement: true //Specifying the default search element using this annotation
      TravelId,
      @Consumption.valueHelpDefinition: [{ entity : { name : '/DMO/I_AGENCY', element : 'AgencyID'}   }]  //To Define Value Help to the element AgencyId Using the Target CDS View entity name and element
      @ObjectModel.text.element: ['AgencyName']   //To provide Textual Description for the Element AgencyId
      @Search.defaultSearchElement: true
      AgencyId,
      _Agency.Name       as AgencyName,
      @Consumption.valueHelpDefinition: [{ entity : { name : '/DMO/I_CUSTOMER', element : 'CustomerID'}   }]
      @ObjectModel.text.element: ['CustomerName']  //To provide Textual Description for the Element CustomerId
      @Search.defaultSearchElement: true
      CustomerId,
      _customer.LastName as CustomerName,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode' //Specifying the CurrencyCode as the reference field to the Currency Fields
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      @Consumption.valueHelpDefinition: [{ entity : { name : 'I_currency', element : 'Currency'}   }]
      CurrencyCode,
      Description,
      TravelStatus,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      /* Associations */
      _Agency,
      _booking : redirected to composition child ZC_RAP_Booking_123,
      _currency
}
