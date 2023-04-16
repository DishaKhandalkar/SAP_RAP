CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateBookingID FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateBookingID.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateTotalPrice.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD calculateBookingID.
    DATA max_bookingid TYPE /dmo/booking_id.
    DATA update TYPE TABLE FOR UPDATE zi_rap_travel_dk_123\\booking.

    "read all travels for the requested booking
    "if the multiple bookings of same travel are requested, the travel is return only once.
    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY booking BY \_Travel
    FIELDS ( TravelUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    "Process all affected travels  read respective booking, determine the max-id and update booking without id.

    LOOP AT travels INTO DATA(travel).
      READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
      ENTITY Travel BY \_booking
      FIELDS ( BookingID )
      WITH VALUE #( ( %tky = travel-%tky  ) )
      RESULT DATA(Bookings).

      "find max used in all bookings of this travel
      max_bookingID ='000'.
      LOOP AT bookings INTO DATA(booking).
        IF booking-BookingId > max_bookingid.
        ENDIF.
      ENDLOOP.

      "Provide  a booking id for  all bookings that have known
      LOOP AT bookings INTO booking WHERE BookingID IS INITIAL.
        max_bookingid += 10.
        APPEND VALUE #( %tky = booking-%tky
                        BookingID = max_bookingid
                         ) TO update .
      ENDLOOP.
    ENDLOOP.

    "update the Booking ID  of all relevant bookings
    MODIFY ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Booking
    UPDATE FIELDS ( BookingId ) WITH update
    REPORTED DATA(update_reported).
    reported = CORRESPONDING #( DEEP update_reported  ).

  ENDMETHOD.

  METHOD calculateTotalPrice.
    "read all travels for the requested bookings.
    "if multiple bookings of the same travels are requested, the travels return only once.

    READ ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Booking BY \_Travel
    FIELDS ( TravelUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels)
    FAILED DATA(read_failed).

    "trigger calculate of the total price
    MODIFY ENTITIES OF zi_rap_travel_dk_123 IN LOCAL MODE
    ENTITY Travel
    EXECUTE recalcTotalPrice
    FROM CORRESPONDING #( travels )
    REPORTED DATA(execute_reported).
    reported = CORRESPONDING #( DEEP execute_reported ).
  ENDMETHOD.

ENDCLASS.
