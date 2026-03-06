-- ============================================================================
-- NYC TAXI PIPELINE - TABLE FHV RAW (BRONZE LAYER)
-- ============================================================================
-- Description : Table pour données brutes FHV (Uber, Lyft, Via, etc.)
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-06
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_loading_wh;

-- ============================================================================
-- TABLE : FHV_TRIPS_RAW
-- ============================================================================

CREATE OR REPLACE TABLE fhv_trips_raw (
    -- Colonnes business (du Parquet)
    dispatching_base_num   VARCHAR(50),
    pickup_datetime        NUMBER(38,0),     -- Unix timestamp (microsecondes)
    dropoff_datetime       NUMBER(38,0),     -- Unix timestamp (microsecondes)
    PUlocationID           NUMBER(38,0),
    DOlocationID           NUMBER(38,0),
    SR_Flag                NUMBER(38,0),
    Affiliated_base_number VARCHAR(50),
    
    -- Colonnes metadata (ajoutées)
    _loaded_at             TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(), -- Quand la ligne a été chargée dans Snowflake
    _source_file           VARCHAR(500), -- Nom du fichier source (ex: 'fhv_tripdata_2025-01.parquet')
    _file_row_number       NUMBER(38,0) -- Numéro de ligne dans le fichier source (commence à 1)
)
COMMENT = 'Table RAW pour FHV trips - Données brutes non transformées';

-- Vérifier la création
DESC TABLE fhv_trips_raw;
SHOW TABLES LIKE 'fhv_trips_raw';


SELECT 'Table fhv_trips_raw created successfully' as status;