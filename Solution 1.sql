/*
VAYU AIR - DATA WAREHOUSE ASSIGNMENT
QUESTION 1: FACT TABLE DESIGN

1. GRAIN:
One row in FactTicketSales represents one ticket sold (one booking).

2. COLUMN CLASSIFICATION:

Dimension Keys:
- passenger_id
- flight_id
- booking_date
- travel_date

Measures:
- fare_amount
- tax_amount
- miles_earned

Transaction Identifier:
- booking_id

Dimension Attributes:
- fare_class
- booking_status

3. ADDITIVE VS NON-ADDITIVE MEASURES:

Additive Measures:
- fare_amount
- tax_amount
- miles_earned

Non-additive Example:
- Average fare, because averages cannot be directly summed.
*/



SELECT * FROM bronze_bookings