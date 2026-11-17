# Vayu Air – Data Modeling & Warehouse Engineering

## Project Overview

This project focuses on designing and implementing a data warehouse for Vayu Air using **Microsoft SQL Server**.

The objective is to transform operational airline data into a structured dimensional data warehouse that supports ticket sales analysis, passenger analysis, flight analysis, and business reporting.

The project covers dimensional modeling, surrogate keys, data loading, snowflake schema design, Slowly Changing Dimensions (SCD Type 2), table partitioning, Medallion Architecture, and data contracts.

---

## Technologies Used

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- T-SQL
- Dimensional Modeling
- Data Warehousing

---

## Source Data

The project uses the following source tables:

| Source Table | Description |
|---|---|
| `bronze_bookings` | Booking and ticket transaction records |
| `bronze_passengers` | Passenger master data |
| `bronze_flights` | Flight details |
| `bronze_airports` | Airport information |
| `bronze_aircraft` | Aircraft information |
| `stg_passenger_updates` | Passenger change feed used for SCD Type 2 processing |

---

# Project Tasks

## Question 1 – Fact Table Design and Grain Identification

Identified the grain of the fact table and classified the source columns into measures, dimensions, and identifiers.

**Fact Table:** `FactTicketSales`

**Grain:** One row represents one ticket sold / booking.

**Measures:**
- `FareAmount`
- `TaxAmount`
- `MilesEarned`

These measures are additive and can be aggregated across relevant dimensions.

**Dimension References:**
- Passenger
- Flight
- Booking Date
- Travel Date

Other descriptive attributes include fare class and booking status.

**Key Concept:** Defining the fact table grain correctly ensures that every record represents a consistent business event and prevents incorrect aggregations.

---

## Question 2 – Data Warehouse Schema Design

Created the `dw` schema and designed the dimensional model using fact and dimension tables.

### Dimension Tables

| Table | Purpose |
|---|---|
| `DimPassenger` | Stores passenger attributes |
| `DimFlight` | Stores flight details |
| `DimAirport` | Stores airport information |
| `DimAircraft` | Stores aircraft details |
| `DimDate` | Stores calendar attributes for date-based analysis |

### Fact Table

| Table | Purpose |
|---|---|
| `FactTicketSales` | Stores ticket sales transactions and measures |

Implemented primary keys, surrogate keys, and relationships required to connect the fact table with the dimensions.

**Key Concept:** Star Schema – a central fact table connected to surrounding dimension tables.

---

## Question 3 – Loading Dimensions and Fact Table

Loaded dimension and fact tables from the Bronze source tables.

### Implementation

- Loaded passenger, flight, airport, and aircraft dimensions.
- Generated surrogate keys using `IDENTITY`.
- Created a `DimDate` table with an integer `DateKey` in `YYYYMMDD` format.
- Populated the date dimension using a recursive CTE.
- Loaded the fact table by joining bookings to the dimensions using their business keys.
- Stored the corresponding dimension surrogate keys in the fact table.

### Fact Table Relationships

The fact table uses:

- `PassengerKey`
- `FlightKey`
- `BookingDateKey`
- `TravelDateKey`

The original business identifiers are retained in the dimension tables.

**Key Concept:** Business keys identify records in source systems, whereas surrogate keys provide unique warehouse identifiers for dimensional records.

---

## Question 4 – Snowflake Schema Design

Normalized the airport dimension into three related tables:

1. `DimAirport`
2. `DimCity`
3. `DimCountry`

### Relationships

`DimAirport` → `DimCity` → `DimCountry`

Implemented:

- Primary key constraints
- Foreign key constraints
- Unique constraints to prevent duplicate city-country combinations and airport codes

Created a query to retrieve airport details along with their corresponding city and country information.

**Key Concept:** Snowflake Schema – normalizing dimension tables into related tables to reduce redundant data and improve consistency.

---

## Question 5 – Slowly Changing Dimension Type 2

Implemented SCD Type 2 for the passenger dimension to maintain historical changes in passenger attributes.

### Columns Added

| Column | Purpose |
|---|---|
| `PassengerKey` | Unique surrogate key for each passenger version |
| `PassengerID` | Stable business key identifying the passenger |
| `EffectiveStartDate` | Date from which the version is valid |
| `EffectiveEndDate` | Date on which the version expires |
| `IsCurrent` | Indicates whether the record is the current version |

### Implementation Logic

**Step 1 – Expire Existing Records**

When a passenger's frequent flyer tier or home airport changes:
- Update the old record's effective end date.
- Set `IsCurrent = 0`.
- Preserve the previous attribute values.

**Step 2 – Insert New Records**

- Insert a new version for the changed passenger.
- Generate a new surrogate key.
- Set the new effective start date.
- Set `EffectiveEndDate = NULL`.
- Set `IsCurrent = 1`.

New passengers are inserted as single current records.

**Key Concept:** SCD Type 2 preserves historical changes by maintaining multiple versions of the same business entity.

---

## Question 6 – Fact Table Partitioning

Partitioned the largest fact table, `FactTicketSales`, based on `BookingDateKey`.

### Implementation

- Created a partition function using `RANGE RIGHT`.
- Defined yearly partition boundaries:
  - `20250101`
  - `20260101`
- Created a partition scheme using the partition function.
- Preserved `TicketSalesKey` as a nonclustered primary key.
- Created a clustered index on `BookingDateKey` using the partition scheme.
- Verified record distribution across partitions.

### Partition Elimination

Compared two queries:

**Query 1:** Filters using the partition key, `BookingDateKey`.

**Query 2:** Filters using a non-partition column, such as `PassengerKey`.

Enabled the Actual Execution Plan in SSMS to compare partition access.

**Key Concept:** Partition elimination allows SQL Server to skip irrelevant partitions when a query filters on the partitioning column.

---

## Question 7 – Medallion Architecture and Data Contracts

### Part A – Medallion Architecture

Mapped the pipeline tables to the three Medallion layers.

| Layer | Description |
|---|---|
| Bronze | Raw source data received from operational systems |
| Silver | Cleaned, validated, deduplicated, and standardized data |
| Gold | Business-ready fact and dimension tables used for analytics |

The current implementation contains Bronze source tables and Gold dimensional warehouse tables. A separate Silver layer has not been implemented.

### Part B – Data Contract

Created a data contract for `bronze_bookings`.

The contract documents:

- Dataset overview and purpose
- Column names and data types
- Allowed values for `fare_class`
- Allowed values for `booking_status`
- Data freshness and delivery SLA
- Data ownership and responsibilities
- Breaking and non-breaking schema changes

**Key Concept:** A data contract establishes an agreement between data producers and consumers about schema, data quality, delivery expectations, and change management.

---

# Concepts Covered

| Area | Concepts |
|---|---|
| Dimensional Modeling | Fact tables, dimensions, grain, measures |
| Schema Design | Star schema, Snowflake schema |
| SQL Server | Primary keys, foreign keys, unique constraints, identity columns |
| Data Loading | INSERT, SELECT, JOIN, CTE, recursive CTE |
| Data Warehousing | Business keys, surrogate keys, date dimension |
| Historical Tracking | SCD Type 2, effective dates, current records |
| Performance Optimization | Partition function, partition scheme, clustered and nonclustered indexes, partition elimination |
| Data Architecture | Medallion Architecture, Bronze, Silver, Gold |
| Data Governance | Data contracts, schema evolution, SLAs |

---

# Project Outcome

Through this project, I worked on building a dimensional data warehouse for airline ticket sales, starting from raw source tables and progressing towards analytical fact and dimension tables.

The implementation provided practical experience in:

- Designing fact and dimension tables based on business requirements.
- Loading warehouse tables using surrogate keys.
- Building and normalizing dimensional models.
- Maintaining historical passenger information using SCD Type 2.
- Partitioning large fact tables for query optimization.
- Understanding Medallion Architecture and defining data contracts.

**Overall, this project strengthened my understanding of SQL Server, dimensional modeling, and foundational Data Engineering concepts.**
