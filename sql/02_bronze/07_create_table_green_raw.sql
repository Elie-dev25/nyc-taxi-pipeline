-- ============================================================================
-- NYC TAXI PIPELINE - TABLE GREEN TAXI RAW (BRONZE LAYER)
-- ============================================================================
-- Description : Table pour données brutes Green Taxi
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-06
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_loading_wh;

-- ============================================================================
-- TABLE : GREEN_TRIPS_RAW
-- ============================================================================

CREATE OR REPLACE TABLE green_trips_raw (
    -- Colonnes business (du Parquet)
    VendorID                NUMBER(38,0),
    lpep_pickup_datetime    NUMBER(38,0),     
    lpep_dropoff_datetime   NUMBER(38,0),     
    store_and_fwd_flag      VARCHAR(10),
    RatecodeID              NUMBER(38,0),
    PULocationID            NUMBER(38,0),
    DOLocationID            NUMBER(38,0),
    passenger_count         NUMBER(38,0),
    trip_distance           REAL,
    fare_amount             REAL,
    extra                   REAL,
    mta_tax                 REAL,
    tip_amount              REAL,
    tolls_amount            REAL,
    ehail_fee               REAL,
    improvement_surcharge   REAL,
    total_amount            REAL,
    payment_type            NUMBER(38,0),
    trip_type               NUMBER(38,0),
    congestion_surcharge    REAL,
    cbd_congestion_fee      REAL,
    
    -- Colonnes metadata (ajoutées par nous)
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            VARCHAR(500),
    _file_row_number        NUMBER(38,0)
)
COMMENT = 'Table RAW pour Green Taxi trips - Données brutes non transformées';

-- Vérifier la création
DESC TABLE green_trips_raw;
SHOW TABLES LIKE 'green_trips_raw';

-- ============================================================================
-- NOTES
-- ============================================================================
-- 21 colonnes business + 3 colonnes metadata = 24 colonnes total
--
-- Différences avec Yellow :
-- - lpep_pickup_datetime au lieu de tpep_pickup_datetime (L = Livery)
-- - ehail_fee : Frais e-hail (spécifique Green)
-- - trip_type : Type de trajet (1=Street-hail, 2=Dispatch)
-- - PAS de Airport_fee (Green ne dessert pas directement les aéroports)
--
-- Sinon structure très similaire à Yellow Taxi
-- ============================================================================

SELECT 'Table green_trips_raw created successfully' as status;