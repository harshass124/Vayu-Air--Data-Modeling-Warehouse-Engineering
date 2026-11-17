
/*
=========================================================
PROJECT: Vayu Air Data Warehouse
TASK: Create and Populate Dimension Tables
      and Prepare Fact Table
=========================================================

OBJECTIVE:
1. Create the DW schema.
2. Create the fact and dimension tables.
3. Generate surrogate keys using IDENTITY.
4. Populate dimensions from Bronze tables.
5. Generate DimDate with YYYYMMDD DateKey.

NOTE:
This script performs an initial load.
=========================================================
*/


/*=======================================================
  1. DROP EXISTING TABLES AND RECREATE DW SCHEMA
=======================================================*/

-- Drop fact table first, followed by dimension tables.
-- This order is useful when foreign key constraints exist.

DROP TABLE IF EXISTS dw.FactTicketSales;
DROP TABLE IF EXISTS dw.DimDate;
DROP TABLE IF EXISTS dw.DimPassenger;
DROP TABLE IF EXISTS dw.DimFlight;
DROP TABLE IF EXISTS dw.DimAircraft;
DROP TABLE IF EXISTS dw.DimAirport;
GO

-- Recreate the DW schema.

IF SCHEMA_ID('dw') IS NOT NULL
    DROP SCHEMA dw;
GO

CREATE SCHEMA dw;
GO


/*=======================================================
  2. CREATE FACT TABLE
=======================================================

  Grain: One row per ticket sold / booking.

  TicketSalesKey : Surrogate primary key generated
                   automatically.

  Dimension Keys : Foreign keys retrieved from
                   corresponding dimension tables.

  Measures       : Fare, tax and miles earned.
=======================================================*/

CREATE TABLE dw.FactTicketSales
(
    -- Surrogate Primary Key
    TicketSalesKey INT IDENTITY(1,1) PRIMARY KEY,

    -- Degenerate Dimension
    BookingID INT,

    -- Dimension Foreign Keys
    PassengerKey INT,
    FlightKey INT,
    BookingDateKey INT,
    TravelDateKey INT,

    -- Measures
    FareAmount DECIMAL(10,2),
    TaxAmount DECIMAL(10,2),
    MilesEarned INT
);
GO


/*=======================================================
  3. CREATE DIMENSION TABLES
=======================================================*/


-- 3.1 DIMENSION: DATE

CREATE TABLE dw.DimDate
(
    -- DateKey format: YYYYMMDD
    DateKey INT PRIMARY KEY,

    FullDate DATE,
    Day INT,
    Month INT,
    MonthName VARCHAR(20),
    Quarter INT,
    Year INT,
    DayOfWeek VARCHAR(20),
    IsWeekend BIT
);
GO


-- 3.2 DIMENSION: PASSENGER

CREATE TABLE dw.DimPassenger
(
    -- Surrogate Key
    PassengerKey INT IDENTITY(1,1) PRIMARY KEY,

    -- Business Key and Attributes
    PassengerID INT,
    PassengerName VARCHAR(150),
    HomeAirportCode CHAR(3),
    FrequentFlyerTier VARCHAR(30),
    SignupDate DATE
);
GO


-- 3.3 DIMENSION: FLIGHT

CREATE TABLE dw.DimFlight
(
    -- Surrogate Key
    FlightKey INT IDENTITY(1,1) PRIMARY KEY,

    -- Business Key and Attributes
    FlightID INT,
    FlightNumber VARCHAR(20),
    OriginAirportCode CHAR(3),
    DestAirportCode CHAR(3),
    AircraftCode VARCHAR(50),
    FlightDate DATE
);
GO


-- 3.4 DIMENSION: AIRCRAFT

CREATE TABLE dw.DimAircraft
(
    -- Surrogate Key
    AircraftKey INT IDENTITY(1,1) PRIMARY KEY,

    -- Business Key and Attributes
    AircraftCode VARCHAR(50),
    Model VARCHAR(100),
    Manufacturer VARCHAR(100),
    SeatCapacity INT
);
GO


-- 3.5 DIMENSION: AIRPORT

CREATE TABLE dw.DimAirport
(
    -- Surrogate Key
    AirportKey INT IDENTITY(1,1) PRIMARY KEY,

    -- Business Key and Attributes
    AirportCode CHAR(3),
    AirportName VARCHAR(150),
    City VARCHAR(100),
    Country VARCHAR(100),
    Region VARCHAR(100)
);
GO


/*=======================================================
  4. POPULATE DIMENSION TABLES FROM BRONZE
=======================================================

  Surrogate keys are generated automatically
  using IDENTITY.

  We insert business keys and descriptive attributes.
=======================================================*/


-- 4.1 LOAD DIMENSION: PASSENGER

INSERT INTO dw.DimPassenger
(
    PassengerID,
    PassengerName,
    HomeAirportCode,
    FrequentFlyerTier,
    SignupDate
)
SELECT
    passenger_id,
    passenger_name,
    home_airport_code,
    frequent_flyer_tier,
    signup_date
FROM bronze_passengers;


-- 4.2 LOAD DIMENSION: AIRCRAFT

INSERT INTO dw.DimAircraft
(
    AircraftCode,
    Model,
    Manufacturer,
    SeatCapacity
)
SELECT
    aircraft_code,
    model,
    manufacturer,
    seat_capacity
FROM bronze_aircraft;


-- 4.3 LOAD DIMENSION: AIRPORT

INSERT INTO dw.DimAirport
(
    AirportCode,
    AirportName,
    City,
    Country,
    Region
)
SELECT
    airport_code,
    airport_name,
    city,
    country,
    region
FROM bronze_airports;


-- 4.4 LOAD DIMENSION: FLIGHT

INSERT INTO dw.DimFlight
(
    FlightID,
    FlightNumber,
    OriginAirportCode,
    DestAirportCode,
    AircraftCode,
    FlightDate
)
SELECT
    flight_id,
    flight_number,
    origin_airport_code,
    dest_airport_code,
    aircraft_code,
    flight_date
FROM bronze_flights;


/*=======================================================
  5. POPULATE DIMENSION: DATE
=======================================================

  There is no dedicated Bronze Date table.

  We collect dates from:
  - Bronze Bookings (Booking Date)
  - Bronze Bookings (Travel Date)
  - Bronze Flights (Flight Date)
  - Bronze Passengers (Signup Date)

  Then:
  1. Find the minimum and maximum dates.
  2. Generate every date in between.
  3. Derive calendar attributes.
  4. Generate DateKey in YYYYMMDD format.
=======================================================*/

;WITH AllDates AS
(
    -- Booking dates
    SELECT booking_date AS dt
    FROM bronze_bookings

    UNION ALL

    -- Travel dates
    SELECT travel_date
    FROM bronze_bookings

    UNION ALL

    -- Flight dates
    SELECT flight_date
    FROM bronze_flights

    UNION ALL

    -- Passenger signup dates
    SELECT signup_date
    FROM bronze_passengers
),

-- Find the overall date range
DateRange AS
(
    SELECT
        MIN(dt) AS MinDate,
        MAX(dt) AS MaxDate
    FROM AllDates
    WHERE dt IS NOT NULL
),

-- Generate a continuous calendar
Calendar AS
(
    -- Anchor member: Start with the earliest date
    SELECT MinDate AS FullDate
    FROM DateRange
    WHERE MinDate IS NOT NULL

    UNION ALL

    -- Recursive member: Add one day at a time
    SELECT DATEADD(DAY, 1, c.FullDate)
    FROM Calendar c
    CROSS JOIN DateRange r
    WHERE c.FullDate < r.MaxDate
)

-- Insert generated dates into DimDate
INSERT INTO dw.DimDate
(
    DateKey,
    FullDate,
    Day,
    Month,
    MonthName,
    Quarter,
    Year,
    DayOfWeek,
    IsWeekend
)
SELECT
    -- Convert date to YYYYMMDD integer
    CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)),

    FullDate,
    DAY(FullDate),
    MONTH(FullDate),
    DATENAME(MONTH, FullDate),
    DATEPART(QUARTER, FullDate),
    YEAR(FullDate),
    DATENAME(WEEKDAY, FullDate),

    -- Identify Saturday and Sunday
    CASE
        WHEN DATEDIFF(DAY, '19000101', FullDate) % 7 IN (5, 6)
        THEN 1
        ELSE 0
    END

FROM Calendar
OPTION (MAXRECURSION 0);
GO


/*=======================================================
  6. VALIDATE DIMENSION TABLES
=======================================================*/

-- Check passenger dimension
SELECT * FROM dw.DimPassenger;

-- Check aircraft dimension
SELECT * FROM dw.DimAircraft;

-- Check airport dimension
SELECT * FROM dw.DimAirport;

-- Check flight dimension
SELECT * FROM dw.DimFlight;

-- Check date dimension
SELECT * FROM dw.DimDate;

-- Check fact table structure and current contents
SELECT * FROM dw.FactTicketSales;
GO



INSERT INTO dw.FactTicketSales
(
    BookingID,
    PassengerKey,
    FlightKey,
    BookingDateKey,
    TravelDateKey,
    FareAmount,
    TaxAmount,
    MilesEarned
)
SELECT
    b.booking_id,

    -- Retrieve PassengerKey from DimPassenger
    p.PassengerKey,

    -- Retrieve FlightKey from DimFlight
    f.FlightKey,

    -- Retrieve DateKey for booking date
    bd.DateKey,

    -- Retrieve DateKey for travel date
    td.DateKey,

    -- Measures directly from Bronze Bookings
   b.fare_amount,
   b.tax_amount,
   b.miles_earned
    

FROM bronze_bookings b

-- Match passenger using business key
INNER JOIN dw.DimPassenger p
    ON b.passenger_id=p.PassengerID

-- Match flight using business key
INNER JOIN dw.DimFlight f
    ON b.flight_id=f.FlightID

-- Match booking date
INNER JOIN dw.DimDate bd
    ON b.booking_date=bd.FullDate

-- Match travel date
INNER JOIN dw.DimDate td
    ON b.travel_date=td.FullDate;


Select * From dw.FactTicketSales


-- Drop old tables if they exist
DROP TABLE IF EXISTS dw.DimCity;
DROP TABLE IF EXISTS dw.DimCountry;
DROP TABLE IF EXISTS dw.DimAirport;
GO

CREATE TABLE dw.DimCountry
(
  CountryKey INT IDENTITY(1,1) PRIMARY KEY,
  CountryName VARCHAR(100) UNIQUE
);
GO

CREATE TABLE dw.DimCity
(
  CityKey INT IDENTITY(1,1) PRIMARY KEY,
  CityName VARCHAR(100),
  Region VARCHAR(100),
  CountryKey INT

      CONSTRAINT FK_DimCity_DimCountry
      FOREIGN KEY (CountryKey)
      REFERENCES dw.DimCountry(CountryKey),

      CONSTRAINT UQ_DimCity
      UNIQUE (CityName, Region, CountryKey)
);
GO


CREATE TABLE dw.DimAirport
(
    -- Surrogate Key
    AirportKey INT IDENTITY(1,1) PRIMARY KEY,

    -- Business Key and Attributes
    AirportCode CHAR(3),
    AirportName VARCHAR(150),
    CityKey INT

     CONSTRAINT FK_DimAirport_DimCity
      FOREIGN KEY (CityKey)
      REFERENCES dw.DimCity(CityKey)

);
GO

-- 4.5 LOAD DIMENSION: COUNTRY, CITY, AIRPORT

INSERT INTO dw.DimCountry (CountryName)
    SELECT 
          DISTINCT country 
          FROM bronze_airports
    WHERE country IS NOT NULL;

INSERT INTO dw.DimCity 
( CityName,
  Region,
  CountryKey)

    SELECT 
          DISTINCT b.city,b.region,c.CountryKey 
          FROM bronze_airports b INNER JOIN dw.DimCountry c ON b.country=c.CountryName


 
INSERT INTO dw.DimAirport
(
    AirportCode,
    AirportName,
    CityKey
)
SELECT
    airport_code,
    airport_name,
    CityKey
FROM bronze_airports b 
INNER JOIN dw.DimCity c
    ON b.city = c.CityName
    AND b.region = c.Region
INNER JOIN dw.DimCountry co
    ON b.country = co.CountryName
    AND c.CountryKey = co.CountryKey;


    
    -- QUESTION 5: Slowly Changing Dimension (SCD) Type 2
-- Rebuild DimPassenger to maintain historical passenger records.
-- When a passenger's Frequent Flyer Tier or Home Airport changes,
-- expire the existing record and insert a new version with a new surrogate key.
-- Use EffectiveFrom, EffectiveTo, and IsCurrent to track record validity.
-- Insert brand-new passengers as a single current record.
-- Follow the two-step pattern: Expire old records first, then insert new versions.

EXEC sp_help 'dbo.stg_passenger_updates';
select * from dw.DimPassenger
where PassengerID='701121'
select * from dbo.stg_passenger_updates


ALTER TABLE dw.DimPassenger
ADD
    EffectiveStartDate DATE,
    EffectiveEndDate DATE,
    IsCurrent BIT;


UPDATE dw.DimPassenger
SET
    EffectiveStartDate = SignupDate,
    EffectiveEndDate = NULL,
    IsCurrent = 1;


UPDATE d
SET
      d.EffectiveEndDate = CAST(GETDATE() AS DATE),
      d.IsCurrent = 0
  
FROM dw.DimPassenger d INNER JOIN stg_passenger_updates s 
                       ON d.PassengerID=s.passenger_id
WHERE d.IsCurrent=1 AND (d.FrequentFlyerTier<>s.frequent_flyer_tier OR d.HomeAirportCode<>s.home_airport_code)
  
  SELECT TOP 5 *
FROM stg_passenger_updates;

INSERT INTO dw.DimPassenger
(
    PassengerID,
    PassengerName,
    HomeAirportCode,
    FrequentFlyerTier,
    SignupDate,
    EffectiveStartDate,
    EffectiveEndDate,
    IsCurrent
)
SELECT
    s.passenger_id,
    s.passenger_name,
    s.home_airport_code,
    s.frequent_flyer_tier,
    d.SignupDate,
    CAST(GETDATE() AS DATE),
    NULL,
    1
FROM stg_passenger_updates s
INNER JOIN dw.DimPassenger d
    ON s.passenger_id = d.PassengerID
WHERE
    d.IsCurrent = 0
    AND d.EffectiveEndDate = CAST(GETDATE() AS DATE);