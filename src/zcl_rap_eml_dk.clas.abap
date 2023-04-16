CLASS zcl_rap_eml_dk DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_RAP_EML_DK IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    " Step 1 - READ
*    READ ENTITIES OF zi_rap_travel_dk_123
*    ENTITY Travel
*    FROM VALUE #( ( TravelUuid = '15D6A360B4EFB944180076A6C57DDD4A' ) )
*    RESULT DATA(travels).
*    out->write( travels ).

*" Step 2 - READ WITH FIELDS
*    READ ENTITIES OF zi_rap_travel_dk_123
*    ENTITY Travel
*    FIELDS ( AgencyId CustomerId )
*    WITH VALUE #( ( TravelUuid = '15D6A360B4EFB944180076A6C57DDD4A' ) )
*    RESULT DATA(travels).
*    out->write( travels ).

*" Step 3 - READ WITH ALL FIELDS
*    READ ENTITIES OF zi_rap_travel_dk_123
*    ENTITY Travel
*    ALL FIELDS WITH VALUE #( ( TravelUuid = '15D6A360B4EFB944180076A6C57DDD4A' ) )
*    RESULT DATA(travels).
*    out->write( travels ).

*" Step 4 - READ BY ASSOCIATIONS
*    READ ENTITIES OF zi_rap_travel_dk_123
*    ENTITY Travel BY \_Booking
*    ALL FIELDS WITH  VALUE #( ( TravelUuid = '15D6A360B4EFB944180076A6C57DDD4A' ) )
*    RESULT DATA(bookings).
*    out->write( bookings ).

*" Step 5 - UNSUCCESSFULL READ
*    READ ENTITIES OF zi_rap_travel_dk_123
*    ENTITY Travel
*    ALL FIELDS WITH  VALUE #( ( TravelUuid = '11111111111111111111111111111111' ) )
*    RESULT DATA(travels)
*    FAILED DATA(failed)
*    REPORTED DATA(reported).
*    out->write( travels ).
*    out->write( failed ). " complex structure not supported by the console output.
*    out->write( reported ). " complex structure not supported by the console output.

*" Step 6 - Modify Update
*    MODIFY ENTITIES OF zi_rap_travel_dk_123
*    ENTITY Travel
*    UPDATE
*    SET FIELDS WITH VALUE #( ( TravelUuid = '15D6A360B4EFB944180076A6C57DDD4A'
*                               Description = 'I Like RAP@openSAP') )
*    FAILED DATA(failed)
*    REPORTED DATA(reported).
*    out->write( 'UPDATE DONE' ).
*
**" Step 6b - Commit entities
**
*    COMMIT ENTITIES
*    RESPONSE OF zi_rap_travel_dk_123
*    FAILED DATA(failed_commit)
*    REPORTED DATA(reported_commit).

*" Step 7- Modify Update
*    MODIFY ENTITIES OF zi_rap_travel_dk_123
*    ENTITY Travel
*    CREATE
*    SET FIELDS WITH VALUE
*           #( (  %cid = 'MyContentID_1'
*                 AgencyId = '70012'
*                 CustomerId = '25'
*                 BeginDate = cl_abap_context_info=>get_system_date(  )
*                 EndDate =  cl_abap_context_info=>get_system_date(  ) + 10
*                 Description = 'I Like RAP@openSAP'
*    ) )
*
*        MAPPED DATA(mapped)
*        FAILED DATA(failed)
*        REPORTED DATA(reported).
*    out->write( mapped-travel ).
*
*    COMMIT ENTITIES
*    RESPONSE OF zi_rap_travel_dk_123
*    FAILED DATA(failed_commit)
*    REPORTED DATA(reported_commit).
*
*    out->write('Create Done' ).

    " Step 8- Modify Delete
    MODIFY ENTITIES OF zi_rap_travel_dk_123
    ENTITY travel
    DELETE FROM
    VALUE
    #( ( TravelUuid = 'E1E4A360B4EFB944180076A6C57DDD4A') )
         FAILED DATA(failed)
         REPORTED DATA(reported).

    COMMIT ENTITIES
    RESPONSE OF z1_rap_travel_1212
    FAILED DATA(failed_commit)
    REPORTED DATA(reported_commit).
    out->write('Delete Done' ).




  ENDMETHOD.
ENDCLASS.
