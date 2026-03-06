-- ============================================================================
-- NYC TAXI PIPELINE - TABLE YELLOW TAXI RAW (BRONZE LAYER)
-- ============================================================================
-- Description : Table pour données brutes Yellow Taxi
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-06
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_loading_wh;

-- ============================================================================
-- TABLE : YELLOW_TRIPS_RAW
-- ============================================================================

CREATE OR REPLACE TABLE yellow_trips_raw (
    -- Colonnes business (du Parquet)
    VendorID                NUMBER(38,0),
    tpep_pickup_datetime    NUMBER(38,0),     -- Unix timestamp (microsecondes)
    tpep_dropoff_datetime   NUMBER(38,0),     -- Unix timestamp (microsecondes)
    passenger_count         NUMBER(38,0),
    trip_distance           REAL,
    RatecodeID              NUMBER(38,0),
    store_and_fwd_flag      VARCHAR(10),
    PULocationID            NUMBER(38,0),
    DOLocationID            NUMBER(38,0),
    payment_type            NUMBER(38,0),
    fare_amount             REAL,
    extra                   REAL,
    mta_tax                 REAL,
    tip_amount              REAL,
    tolls_amount            REAL,
    improvement_surcharge   REAL,
    total_amount            REAL,
    congestion_surcharge    REAL,
    Airport_fee             REAL,
    cbd_congestion_fee      REAL,
    
    -- Colonnes metadata (ajoutées par nous)
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            VARCHAR(500),
    _file_row_number        NUMBER(38,0)
)
COMMENT = 'Table RAW pour Yellow Taxi trips - Données brutes non transformées';

-- Vérifier la création
DESC TABLE yellow_trips_raw;
SHOW TABLES LIKE 'yellow_trips_raw';

-- ============================================================================
-- NOTES
-- ============================================================================
-- 20 colonnes business + 3 colonnes metadata = 23 colonnes total
--
-- Types de données :
-- - NUMBER(38,0) : Entiers (IDs, counts, timestamps)
-- - REAL : Décimaux (montants, distances)
-- - VARCHAR : Textes
--
-- Timestamps en Unix (microsecondes) comme FHV
--
-- Pas de contraintes dans Bronze (données brutes as-is)
-- ============================================================================

SELECT 'Table yellow_trips_raw created successfully' as status;