@AbapCatalog.sqlViewName: 'ZI_RAP_TRAVEL_D'
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Travel view'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view ZI_RAP_Travel_DK_123
  as select from zrap_travel_dk_1 as Travel

  composition [0..*] of ZI_RAP_BOOK_DK_123 as _booking

  association [0..1] to /DMO/I_Agency      as _Agency   on $projection.AgencyId = _Agency.AgencyID
  association [0..1] to /DMO/I_Customer    as _customer on $projection.CustomerId = _customer.CustomerID
  association [0..1] to I_Currency         as _currency on $projection.CurrencyCode = _currency.Currency

{
  key travel_uuid           as TravelUuid,
      travel_id             as TravelId,
      travel_status         as TravelStatus,
      agency_id             as AgencyId,
      customer_id           as CustomerId,
      begin_date            as BeginDate,
      end_date              as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee           as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price           as TotalPrice,
      currency_code         as CurrencyCode,
      description           as Description,
      overall_status        as OverallStatus,
      @Semantics.user.createdBy : true              //This annotations are necessary to allow the automatic update of the admin fields on every operations 
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true 
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy : true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt : true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      /*association*/
      _booking,
      _Agency,
      _customer,
      _currency
}
