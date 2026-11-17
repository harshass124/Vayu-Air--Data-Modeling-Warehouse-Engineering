
DROP SCHEMA IF EXISTS dw;
 GO

CREATE SCHEMA dw;
GO


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
SELECT *
FROM dw.FactTicketSales;

 DROP Table IF EXISTS DimDate;
 GO

CREATE TABLE dw.DimDate
(
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

DROP Table IF EXISTS DimPassenger;
 GO

CREATE TABLE dw.DimPassenger
(
    PassengerKey INT IDENTITY(1,1) PRIMARY KEY,
    PassengerID INT,
    PassengerName VARCHAR(150),
    HomeAirportCode CHAR(3),
    FrequentFlyerTier VARCHAR(30),
    SignupDate DATE
);

DROP Table IF EXISTS DimFlight;
 GO
CREATE TABLE dw.DimFlight
(
    FlightKey INT IDENTITY(1,1) PRIMARY KEY,
    FlightID INT,
    FlightNumber VARCHAR(20),
    OriginAirportCode CHAR(3),
    DestAirportCode CHAR(3),
    AircraftCode VARCHAR(50),
    FlightDate DATE
);

DROP Table IF EXISTS DimAircraft;
 GO
CREATE TABLE dw.DimAircraft
(
    AircraftKey INT IDENTITY(1,1) PRIMARY KEY,
    AircraftCode VARCHAR(50),
    Model VARCHAR(100),
    Manufacturer VARCHAR(100),
    SeatCapacity INT
);

DROP Table IF EXISTS DimAirport;
 GO

CREATE TABLE dw.DimAirport
(
    AirportKey INT IDENTITY(1,1) PRIMARY KEY,
    AirportCode CHAR(3),
    AirportName VARCHAR(150),
    City VARCHAR(100),
    Country VARCHAR(100),
    Region VARCHAR(100)
);


