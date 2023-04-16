@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Booking View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_RAP_BOOK_DK_123 
as select from zrap_booking_1  as booking

association to parent ZI_RAP_Travel_DK_123       as _Travel     on $projection.TravelUuid = _Travel.TravelUuid
association [1..1] to /DMO/I_Customer           as _Customer   on $projection.CustomerId = _Customer.CustomerID
association [1..1] to /DMO/I_Carrier            as _Carrier    on $projection.CarrierId = _Carrier.AirlineID
association [1..1] to /DMO/I_Connection         as _Connection on $projection.CarrierId = _Connection.AirlineID
                                                               and $projection.ConnectionId = _Connection.ConnectionID
association [1..1] to /DMO/I_Flight             as _Flight     on $projection.CarrierId = _Flight.AirlineID  
                                                               and $projection.ConnectionId = _Flight.ConnectionID  
                                                               and $projection.FlightDate = _Flight.FlightDate     
 association [0..1] to I_Currency               as _Currency   on $projection.CurrencyCode = _Currency.Currency                                                                            
{
    key booking_uuid         as BookingUuid,
    travel_uuid              as TravelUuid,
    booking_id               as BookingId,
    booking_date             as BookingDate,
    customer_id              as CustomerId,
    carrier_id               as CarrierId,
    connection_id            as ConnectionId,
    flight_date              as FlightDate,
    @Semantics.amount.currencyCode: 'CurrencyCode'  
    flight_price             as FlightPrice,
    currency_code            as CurrencyCode,
    @Semantics.user.createdBy : true
    created_by               as CreatedBy,      
    @Semantics.user.lastChangedBy: true
    last_changed_by          as LastChangedBy,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    local_last_changed_at    as LocalLastChangedAt,
    
    /* Associations*/
    _Travel,
    _Customer,
    _Carrier,
    _Connection,
    _Flight,
    _Currency
        
}
