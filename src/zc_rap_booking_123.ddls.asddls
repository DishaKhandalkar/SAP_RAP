@EndUserText.label: 'Booking BO Projection view'
@AccessControl.authorizationCheck: #CHECK
@Search.searchable: true
@Metadata.allowExtensions: true
define view entity ZC_RAP_Booking_123
  as projection on ZI_RAP_BOOK_DK_123 as Booking
{
  key BookingUuid,
      TravelUuid,
      @Search.defaultSearchElement: true //Specifying the default search element using this annotation
      BookingId,
      BookingDate,
      @Consumption.valueHelpDefinition: [{ entity : { name : '/DMO/I_CUSTOMER', element : 'CustomerID'}   }]
      @ObjectModel.text.element: ['CustomerName']  //To provide Textual Description for the Element CustomerId
      @Search.defaultSearchElement: true
      CustomerId,
      _Customer.LastName as CustomerName,
      @Consumption.valueHelpDefinition: [{ entity : { name : '/DMO/I_carrier', element : 'AirlineID'}   }]
      @ObjectModel.text.element: ['CarrierName'] //To provide Textual Description for the Element CarrierId
      CarrierId,
      _Carrier.Name      as CarrierName,
      @Consumption.valueHelpDefinition: [{ entity : { name : '/DMO/I_Flight', element : 'ConnectionID'},
                                    additionalBinding: [{localElement: 'CarrierId', element : 'AirlineID' },
                                                        {localElement: 'FlightDate', element : 'FlightDate', usage: #RESULT},
                                                        {localElement: 'FlightPrice', element : 'Price',  usage: #RESULT},
                                                        {localElement: 'CurrencyCode', element : 'CurrencyCode', usage: #RESULT} ] }]
      ConnectionId,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      @Consumption.valueHelpDefinition: [{ entity : { name : 'I_currency', element : 'Currency'}   }]
      CurrencyCode,
      CreatedBy,
      LastChangedBy,
      LocalLastChangedAt,
      /* Associations */

      _Carrier,
      _Connection,
      _Currency,
      _Customer,
      _Flight,
      _Travel : redirected to parent ZC_RAP_TRAVEL_123
}
