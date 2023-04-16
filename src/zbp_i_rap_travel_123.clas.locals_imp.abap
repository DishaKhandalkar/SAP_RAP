CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF travel_status,                      "Constants for the TravelStatus
        open      TYPE c LENGTH 1 VALUE 'O', "open
        accepted  TYPE c LENGTH 1 VALUE 'A', "Accepted
        cancelled TYPE c LENGTH 1 VALUE 'X', "Cancelled
      END OF travel_status.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS recalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~recalcTotalPrice.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTotalPrice.

    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setInitialStatus.

    METHODS calculateTravelID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~calculateTravelID.

    METHODS validateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateAgency.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS is_update_granted  IMPORTING has_before_image      TYPE abap_bool
                                         overall_status        TYPE /dmo/overall_status
                               RETURNING VALUE(update_granted) TYPE abap_bool.


    METHODS is_delete_granted  IMPORTING has_before_image      TYPE abap_bool
                                         overall_status        TYPE /dmo/overall_status
                               RETURNING VALUE(delete_granted) TYPE abap_bool.

    METHODS is_create_granted  RETURNING VALUE(create_granted) TYPE abap_bool.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.
    "Read the travel status of the existing travels
    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
     ENTITY Travel
      FIELDS ( TravelStatus ) WITH CORRESPONDING #( keys )
     RESULT DATA(travels)
      FAILED failed.

    result =
    VALUE #(
      FOR travel IN travels
         LET is_accepted = COND #( WHEN travel-TravelStatus = travel_status-accepted
                                   THEN if_abap_behv=>fc-o-disabled
                                   ELSE if_abap_behv=>fc-o-enabled )
             is_rejected = COND #( WHEN travel-TravelStatus = travel_status-cancelled
                                   THEN if_abap_behv=>fc-o-disabled
                                   ELSE if_abap_behv=>fc-o-enabled )
         IN
         ( %tky                 = travel-%tky
           %action-acceptTravel = is_accepted
           %action-rejectTravel = is_rejected
         ) ).

  ENDMETHOD.

  METHOD acceptTravel.
    "set the  new overall status.
    MODIFY ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    UPDATE
    FIELDS ( TravelStatus )
    WITH VALUE #( FOR key IN keys
                 ( %tky = key-%tky
                   TravelStatus = travel_status-accepted ) )
                   FAILED failed
                   REPORTED reported.


    "fill the response table
    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING  #( keys )
    RESULT DATA(travels).
    result = VALUE #( FOR travel IN travels
                     ( %tky = travel-%tky
                       %param = travel ) ).
  ENDMETHOD.

  METHOD recalcTotalPrice.
    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA : amount_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    " Read all relevAnt travel instance.

    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY travel
    FIELDS ( BookingFee CurrencyCode )
    WITH CORRESPONDING #( keys )
       RESULT DATA(travels) .

    DELETE travels WHERE CurrencyCode IS INITIAL.
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>) .
      "set the start for the calculation by adding the booking fee
      amount_per_currencycode = VALUE #( ( amount = <travel>-BookingFee
                                           currency_code = <travel>-CurrencyCode ) ).

      "read all associated booking and add them to total price
      READ ENTITIES OF  zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel BY \_Booking
    FIELDS ( FlightPrice CurrencyCode )
    WITH VALUE #( ( %tky = <travel>-%tky ) )
    RESULT DATA(bookings).

      LOOP AT bookings INTO DATA(booking) WHERE CurrencyCode IS NOT INITIAL.
        COLLECT VALUE ty_amount_per_currencycode( amount = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode ) INTO amount_per_currencycode.

      ENDLOOP.

      CLEAR <travel>-TotalPrice .
      LOOP AT amount_per_currencycode INTO DATA(single_amount_per_currencycode).

        "if need do a currency conversion
        IF single_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amount_per_currencycode-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
          EXPORTING
          iv_amount  = single_amount_per_currencycode-amount
          iv_currency_code_source = single_amount_per_currencycode-currency_code
          iv_currency_code_target = <travel>-CurrencyCode
          iv_exchange_rate_date = cl_abap_context_info=>get_system_date(  )
          IMPORTING
          ev_amount = DATA(total_booking_price_per_curr)
          ).
          <travel>-TotalPrice += total_booking_price_per_curr.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    "write back the modified total_price of   travel
    MODIFY ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY  Travel
    UPDATE FIELDS ( TotalPrice )
    WITH CORRESPONDING #( travels ).

  ENDMETHOD.

  METHOD rejectTravel.
    "set the new overall status
    MODIFY ENTITIES OF  zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    UPDATE
    FIELDS ( TravelStatus )
    WITH VALUE #( FOR key IN keys
                ( %tky = key-%tky
                   TravelStatus = travel_status-cancelled ) )
                   FAILED failed
                   REPORTED reported.

    "fill the response table
    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(Travels).

    result = VALUE #( FOR travel IN travels
                     ( %tky = travel-%tky
                       %param = travel ) ).
  ENDMETHOD.

  METHOD calculateTotalPrice.
    MODIFY ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY travel
    EXECUTE recalcTotalPrice
    FROM CORRESPONDING #( keys )
    REPORTED DATA(execute_reported).

    reported = CORRESPONDING #( DEEP execute_reported ).
  ENDMETHOD.

  METHOD setInitialStatus.
    "read relevant travel instance  data
    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelStatus ) WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    "remove all travel instance data with define status
    DELETE travels WHERE TravelStatus IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    "set default travel status
    MODIFY ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    UPDATE
    FIELDS ( TravelStatus )
    WITH VALUE #( FOR travel IN travels
                (  %tky = travel-%tky
                   TravelStatus = travel_status-open ) )
      REPORTED DATA(update_reported)   .

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD calculateTravelID.
    "please note that this is just example for calculating field during on save
    "this approach does not endure for gap free or unique travel id's. it just  helps to provide a readable id.
    "the key of this business object is UUID , calculate by the framework.

    " check if travel id is already fill
    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelID ) WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    "Remove line where TravelID is already filled.
    DELETE travels WHERE TravelID IS NOT INITIAL.

    "anything left ?
    CHECK travels IS NOT INITIAL.

    "select max travel id
    SELECT SINGLE
    FROM zrap_travel_dk_1
    FIELDS MAX( travel_ID ) AS travelID
    INTO @DATA(max_travelid).

    "set the travel id
    MODIFY ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    UPDATE
    FROM VALUE #( FOR travel IN travels INDEX INTO i (
        %tky   = travel-%tky
        TravelID = max_travelID + i
        %control-TravelID = if_abap_behv=>mk-on ) )
         REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD validateAgency.
    "read relevant travel data
    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    FIELDS ( AgencyId ) WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DATA agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    "optimization of DB select : extract distinct non_initial agency id's
    agencies = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING Agency_ID = AgencyId EXCEPT * ).
    DELETE agencies WHERE agency_id IS INITIAL.

    IF agencies IS NOT INITIAL.
      "check if agency id is exist
      SELECT FROM /dmo/agency FIELDS agency_id
      FOR ALL ENTRIES IN @agencies
      WHERE agency_id = @agencies-agency_id
      INTO TABLE @DATA(agencies_db).
    ENDIF.

    "Raise message for non existing and initial agencyID
    LOOP AT  travels INTO DATA(travel).
      "clear  state messages that might exist
      APPEND VALUE #( %tky = travel-%tky
                       %state_area = 'VALIDATE_AGENCY' )
       TO reported-travel .

      IF travel-AgencyId IS INITIAL OR NOT line_exists( agencies_db[ agency_id = travel-AgencyId ] ).
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_AGENCY'
                        %msg = NEW zcm_rap_dk(
                         severity = if_abap_behv_message=>severity-error
                         textid  = zcm_rap_dk=>agency_unknown
                         agencyid = travel-AgencyId )
                         %element-Agencyid = if_abap_behv=>mk-on )
           TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.
    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
   ENTITY Travel
   FIELDS ( CustomerId ) WITH CORRESPONDING #( keys )
   RESULT DATA(travels).
    DATA customers  TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    "optimization of DB select : extract distinct non_initial customer id's
    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING Customer_ID = CustomerId EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.

    IF customers IS NOT INITIAL.
      "check if customer id is exist
      SELECT FROM /dmo/customer FIELDS customer_id
      FOR ALL ENTRIES IN @customers
      WHERE customer_id = @customers-customer_id
      INTO TABLE @DATA(customers_db).
    ENDIF.

    "Raise message for non existing and initial customerID
    LOOP AT  travels INTO DATA(travel).
      "clear  state messages that might exist
      APPEND VALUE #( %tky = travel-%tky
                       %state_area = 'VALIDATE_CUSTOMER' )
       TO reported-travel .

      IF travel-CustomerId IS INITIAL OR NOT line_exists( customers_db[ customer_id = travel-CustomerId ] ).
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = NEW zcm_rap_dk(
                         severity = if_abap_behv_message=>severity-error
                         textid  = zcm_rap_dk=>customer_unknown
                         customerid = travel-CustomerId )
                         %element-CustomerID = if_abap_behv=>mk-on )
           TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDates.
    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
   ENTITY Travel
   FIELDS ( TravelId BeginDate EndDate ) WITH CORRESPONDING #( keys )
   RESULT DATA(travels).



    LOOP AT  travels INTO DATA(travel).
      "clear  state messages that might exist
      APPEND VALUE #( %tky = travel-%tky
                       %state_area = 'VALIDATE_DATES' )
       TO reported-travel .

      IF travel-EndDate < travel-BeginDate.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg = NEW zcm_rap_dk(
                         severity = if_abap_behv_message=>severity-error
                         textid  = zcm_rap_dk=>date_interval
                         begindate = travel-BeginDate
                         enddate = travel-EndDate
                         travelid = travel-TravelId )

                         %element-BeginDate = if_abap_behv=>mk-on
                         %element-EndDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    DATA : has_before_image    TYPE abap_bool,
           is_update_requested TYPE abap_bool,
           is_delete_requested TYPE abap_bool,
           update_granted      TYPE abap_bool,
           delete_granted      TYPE abap_bool.

    DATA : failed_travel LIKE LINE OF failed-travel.

    " read the existing travels

    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelStatus ) WITH CORRESPONDING #( keys )
       RESULT DATA(travels)
       FAILED failed.

    CHECK travels IS NOT INITIAL.

    "  in this example authorization is defined based on the activity + travel status
    " for the travel status  we need the before image from the database . we perform this for active (is_draft=00)
    "as well as for draft (is_draft=00) as we can't distinguish.

    SELECT FROM zrap_travel_dk_1
    FIELDS travel_uuid, overall_status
    FOR ALL ENTRIES IN @travels
    WHERE travel_uuid EQ @travels-TravelUuid
    ORDER BY PRIMARY KEY
    INTO TABLE @DATA(travels_before_image).

    is_update_requested = COND #( WHEN requested_authorizations-%update = if_abap_behv=>mk-on OR
                                       requested_authorizations-%action-acceptTravel  = if_abap_behv=>mk-on OR
                                       requested_authorizations-%action-rejectTravel = if_abap_behv=>mk-on OR
                                        requested_authorizations-%assoc-_booking = if_abap_behv=>mk-on
                                        THEN abap_true ELSE abap_false ).



    is_delete_requested = COND #( WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
                                  THEN abap_true ELSE abap_false  ).

    LOOP AT travels INTO DATA(travel).
      update_granted = delete_granted = abap_false.

      READ TABLE travels_before_image INTO DATA(travel_before_image)
      WITH KEY travel_uuid = travel-TravelUuid BINARY SEARCH.
      has_before_image = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

      IF is_update_requested = abap_true.
        "EDIT of an existing record-> check update authorization
        IF has_before_image = abap_true.
          update_granted = is_update_granted( has_before_image = has_before_image overall_status = travel_before_image-overall_status ).
          IF update_granted = abap_false.
            APPEND VALUE #( %tky = travel-%tky
                            %fail-cause = if_abap_behv=>cause-unauthorized ) TO failed-travel.

            APPEND VALUE #( %tky = travel-%tky
                            %msg = NEW zcm_rap_dk( severity = if_abap_behv_message=>severity-error
                                                     textid = zcm_rap_dk=>unotherized )
                                                     ) TO reported-travel.
          ENDIF.
          "creation of new record->check create authorization
        ELSE.
          update_granted = is_create_granted( ).
          IF update_granted = abap_false.
            APPEND VALUE #( %tky = travel-%tky
                             %fail-cause = if_abap_behv=>cause-unauthorized ) TO failed-travel.
            APPEND VALUE #( %tky = travel-%tky
                         %msg = NEW zcm_rap_dk( severity = if_abap_behv_message=>severity-error
                                                  textid = zcm_rap_dk=>unotherized )
                                                  ) TO reported-travel.

          ENDIF.
        ENDIF.
      ENDIF.

      IF is_delete_requested = abap_true.
        delete_granted = is_delete_granted( has_before_image = has_before_image  overall_status = travel_before_image-overall_status ).
        IF delete_granted = abap_false.

          APPEND VALUE #( %tky = travel-%tky
                     %fail-cause = if_abap_behv=>cause-unauthorized ) TO failed-travel.

          APPEND VALUE #( %tky = travel-%tky
                          %msg = NEW zcm_rap_dk( severity = if_abap_behv_message=>severity-error
                          textid = zcm_rap_dk=>unotherized )
                           ) TO reported-travel.
        ENDIF.
      ENDIF.

      APPEND VALUE #( %tky = travel-%tky       "On Delete travel object
                      %update  = COND #( WHEN update_granted = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %action-acceptTravel = COND #( WHEN update_granted = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %assoc-_booking = COND #( WHEN update_granted = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %delete = COND #( WHEN delete_granted = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      ) TO result.
    ENDLOOP.


  ENDMETHOD.

  METHOD is_create_granted.
    AUTHORITY-CHECK OBJECT 'ZOSTAT12DK'
        ID 'ZOSTAT12DK' DUMMY
        ID 'ACTVT' FIELD '01'.
    create_granted = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

    "simulate full access - for testing purpose only! Need to be removed for all productive implementation.

    create_granted = abap_true.
  ENDMETHOD.

  METHOD is_delete_granted.
    IF has_before_image = abap_true.
      AUTHORITY-CHECK OBJECT 'ZOSTAT12DK'
     ID 'ZOSTAT12DK' FIELD travel_status
     ID 'ACTVT' FIELD '06'.

    ELSE .
      AUTHORITY-CHECK OBJECT 'ZOSTAT12DK'
      ID 'ZOSTAT12DK' DUMMY
      ID 'ACTVT' FIELD '06'.
    ENDIF.

    delete_granted = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).
    "simulate full access - for testing purpose only! Need to be removed for all productive implementation.

    delete_granted = abap_true.
  ENDMETHOD.

  METHOD is_update_granted.
    IF has_before_image = abap_true.
      AUTHORITY-CHECK OBJECT 'ZOSTAT12DK'
     ID 'ZOSTAT12DK' FIELD travel_status
     ID 'ACTVT' FIELD '02'.

    ELSE .

      AUTHORITY-CHECK OBJECT 'ZOSTAT12DK'
      ID 'ZOSTAT12DK' DUMMY
      ID 'ACTVT' FIELD '02'.
    ENDIF.


    update_granted = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).
    "simulate full access - for testing purpose only! Need to be removed for all productive implementation.

    update_granted = abap_true.
  ENDMETHOD.

ENDCLASS.
