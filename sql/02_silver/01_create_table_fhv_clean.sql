-- ============================================================================
-- NYC TAXI PIPELINE - TABLE FHV CLEAN (SILVER LAYER)
-- ============================================================================
-- Description : Données FHV nettoyées et transformées
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-08
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA silver;
USE WAREHOUSE nyc_transform_wh;

-- ============================================================================
-- TABLE : FHV_TRIPS_CLEAN
-- ============================================================================

CREATE OR REPLACE TABLE fhv_trips_clean (
    -- IDs
    dispatching_base_num   VARCHAR(50),
    affiliated_base_number VARCHAR(50),
    
    -- Timestamps convertis (LISIBLES !)
    pickup_datetime        TIMESTAMP_NTZ,
    dropoff_datetime       TIMESTAMP_NTZ,
    
    -- Locations
    pickup_location_id     NUMBER(38,0),
    dropoff_location_id    NUMBER(38,0),
    
    -- Shared Ride
    shared_ride_flag       BOOLEAN,
    
    -- Calculs dérivés
    trip_duration_minutes  NUMBER(10,2),
    trip_duration_hours    NUMBER(10,2),
    
    -- Extraction temporelle
    pickup_hour            NUMBER(2,0),
    pickup_day_of_week     VARCHAR(10),
    pickup_date            DATE,
    pickup_month           NUMBER(2,0),
    pickup_year            NUMBER(4,0),
    
    -- Flags qualité
    is_valid_trip          BOOLEAN,
    is_anomaly             BOOLEAN,
    has_valid_timestamps   BOOLEAN,
    has_valid_locations    BOOLEAN,
    anomaly_reason         VARCHAR(500),
    
    -- Metadata
    _source_file           VARCHAR(500),
    _bronze_loaded_at      TIMESTAMP_NTZ,
    _silver_loaded_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Table CLEAN pour FHV trips - Données transformées et validées';

-- Vérifier
DESC TABLE fhv_trips_clean;

SELECT 'Table fhv_trips_clean created successfully' as status;