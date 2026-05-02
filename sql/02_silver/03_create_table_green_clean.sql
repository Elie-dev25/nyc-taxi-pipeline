-- ============================================================================
-- NYC TAXI PIPELINE - TABLE GREEN CLEAN (SILVER LAYER)
-- ============================================================================
-- Description : Données Green Taxi nettoyées et transformées
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-08
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA silver;
USE WAREHOUSE nyc_transform_wh;

-- ============================================================================
-- TABLE : GREEN_TRIPS_CLEAN
-- ============================================================================

CREATE OR REPLACE TABLE green_trips_clean (
    -- IDs
    vendor_id              NUMBER(38,0),
    
    -- Timestamps convertis
    pickup_datetime        TIMESTAMP_NTZ,
    dropoff_datetime       TIMESTAMP_NTZ,
    
    -- Trip info
    passenger_count        NUMBER(38,0),
    trip_distance          NUMBER(10,2),
    ratecode_id            NUMBER(38,0),
    store_and_fwd_flag     VARCHAR(10),
    trip_type              NUMBER(38,0),  -- Spécifique Green
    
    -- Locations
    pickup_location_id     NUMBER(38,0),
    dropoff_location_id    NUMBER(38,0),
    
    -- Payment
    payment_type           NUMBER(38,0),
    fare_amount            NUMBER(10,2),
    extra                  NUMBER(10,2),
    mta_tax                NUMBER(10,2),
    tip_amount             NUMBER(10,2),
    tolls_amount           NUMBER(10,2),
    ehail_fee              NUMBER(10,2),  -- Spécifique Green
    improvement_surcharge  NUMBER(10,2),
    total_amount           NUMBER(10,2),
    congestion_surcharge   NUMBER(10,2),
    cbd_congestion_fee     NUMBER(10,2),
    
    -- Calculs dérivés
    trip_duration_minutes  NUMBER(10,2),
    trip_duration_hours    NUMBER(10,2),
    avg_speed_mph          NUMBER(10,2),
    tip_percentage         NUMBER(10,2),
    cost_per_mile          NUMBER(10,2),
    
    -- Catégorisation
    trip_distance_category VARCHAR(20),
    fare_category          VARCHAR(20),
    
    -- Extraction temporelle
    pickup_hour            NUMBER(2,0),
    pickup_day_of_week     VARCHAR(10),
    pickup_date            DATE,
    pickup_month           NUMBER(2,0),
    pickup_year            NUMBER(4,0),
    is_weekend             BOOLEAN,
    is_rush_hour           BOOLEAN,
    
    -- Flags qualité
    is_valid_trip          BOOLEAN,
    is_anomaly             BOOLEAN,
    anomaly_reason         VARCHAR(500),
    
    -- Metadata
    _source_file           VARCHAR(500),
    _bronze_loaded_at      TIMESTAMP_NTZ,
    _silver_loaded_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Table CLEAN pour Green Taxi trips - Données transformées et validées';

-- Vérifier
DESC TABLE green_trips_clean;

SELECT 'Table green_trips_clean created successfully' as status;