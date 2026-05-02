-- ============================================================================
-- NYC TAXI PIPELINE - TRANSFORMATION FHV (BRONZE → SILVER)
-- ============================================================================
-- Description : Nettoyage et transformation données FHV
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-08
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA silver;
USE WAREHOUSE nyc_transform_wh;

-- Vider la table (pour ce test manuel)
TRUNCATE TABLE fhv_trips_clean;

-- ============================================================================
-- TRANSFORMATION EN 3 ÉTAPES (CTEs)
-- ============================================================================

INSERT INTO fhv_trips_clean (
    dispatching_base_num,
    affiliated_base_number,
    pickup_datetime,
    dropoff_datetime,
    pickup_location_id,
    dropoff_location_id,
    shared_ride_flag,
    trip_duration_minutes,
    trip_duration_hours,
    pickup_hour,
    pickup_day_of_week,
    pickup_date,
    pickup_month,
    pickup_year,
    is_valid_trip,
    is_anomaly,
    has_valid_timestamps,
    has_valid_locations,
    anomaly_reason,
    _source_file,
    _bronze_loaded_at,
    _silver_loaded_at
)
WITH converted AS (
    SELECT 
        -- IDs (pas de transformation)
        dispatching_base_num,
        Affiliated_base_number as affiliated_base_number,
        
        -- CONVERSION TIMESTAMPS (Unix → Date lisible)
        TO_TIMESTAMP_NTZ(pickup_datetime / 1000000) as pickup_datetime,
        TO_TIMESTAMP_NTZ(dropoff_datetime / 1000000) as dropoff_datetime,
        
        -- Locations (renommage pour cohérence)
        PUlocationID as pickup_location_id,
        DOlocationID as dropoff_location_id,
        
        -- Shared Ride (convertir en BOOLEAN)
        CASE WHEN SR_Flag = 1 THEN TRUE ELSE FALSE END as shared_ride_flag,
        
        -- ⭐ CALCULS DÉRIVÉS : Durée du trajet
        TIMESTAMPDIFF(
            SECOND, 
            TO_TIMESTAMP_NTZ(pickup_datetime / 1000000),
            TO_TIMESTAMP_NTZ(dropoff_datetime / 1000000)
        ) / 60.0 as trip_duration_minutes,
        
        TIMESTAMPDIFF(
            SECOND, 
            TO_TIMESTAMP_NTZ(pickup_datetime / 1000000),
            TO_TIMESTAMP_NTZ(dropoff_datetime / 1000000)
        ) / 3600.0 as trip_duration_hours,
        
        -- ⭐ EXTRACTION TEMPORELLE
        HOUR(TO_TIMESTAMP_NTZ(pickup_datetime / 1000000)) as pickup_hour,
        DAYNAME(TO_TIMESTAMP_NTZ(pickup_datetime / 1000000)) as pickup_day_of_week,
        DATE(TO_TIMESTAMP_NTZ(pickup_datetime / 1000000)) as pickup_date,
        MONTH(TO_TIMESTAMP_NTZ(pickup_datetime / 1000000)) as pickup_month,
        YEAR(TO_TIMESTAMP_NTZ(pickup_datetime / 1000000)) as pickup_year,
        
        -- Metadata
        _source_file,
        _loaded_at as _bronze_loaded_at
        
    FROM bronze.fhv_trips_raw
),

with_flags AS (
    SELECT 
        *,
        
        -- ⭐ FLAG 1 : Timestamps valides ?
        CASE 
            WHEN pickup_datetime IS NULL THEN FALSE
            WHEN dropoff_datetime IS NULL THEN FALSE
            WHEN dropoff_datetime <= pickup_datetime THEN FALSE
            ELSE TRUE
        END as has_valid_timestamps,
        
        -- ⭐ FLAG 2 : Locations valides ?
        CASE
            WHEN pickup_location_id IS NULL THEN FALSE
            WHEN dropoff_location_id IS NULL THEN FALSE
            ELSE TRUE
        END as has_valid_locations,
        
        -- ⭐ DÉTECTION ANOMALIES
        CASE 
            WHEN trip_duration_minutes < 1 THEN TRUE
            WHEN trip_duration_minutes > 1440 THEN TRUE
            ELSE FALSE
        END as is_anomaly,
        
        -- Raison de l'anomalie
        CASE 
            WHEN trip_duration_minutes < 1 THEN 'Durée trop courte (< 1 min)'
            WHEN trip_duration_minutes > 1440 THEN 'Durée trop longue (> 24h)'
            ELSE NULL
        END as anomaly_reason
        
    FROM converted
),

final AS (
    SELECT 
        *,
        has_valid_timestamps AND NOT is_anomaly as is_valid_trip,
        CURRENT_TIMESTAMP() as _silver_loaded_at
    FROM with_flags
)

SELECT 
    dispatching_base_num,
    affiliated_base_number,
    pickup_datetime,
    dropoff_datetime,
    pickup_location_id,
    dropoff_location_id,
    shared_ride_flag,
    trip_duration_minutes,
    trip_duration_hours,
    pickup_hour,
    pickup_day_of_week,
    pickup_date,
    pickup_month,
    pickup_year,
    is_valid_trip,
    is_anomaly,
    has_valid_timestamps,
    has_valid_locations,
    anomaly_reason,
    _source_file,
    _bronze_loaded_at,
    _silver_loaded_at
FROM final;

-- ============================================================================
-- VÉRIFICATIONS
-- ============================================================================

SELECT COUNT(*) as total_rows FROM fhv_trips_clean;

SELECT 
    has_valid_timestamps,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM fhv_trips_clean
GROUP BY has_valid_timestamps;

SELECT 
    has_valid_locations,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM fhv_trips_clean
GROUP BY has_valid_locations;

SELECT 
    is_valid_trip,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM fhv_trips_clean
GROUP BY is_valid_trip;

SELECT 
    is_anomaly,
    anomaly_reason,
    COUNT(*) as count
FROM fhv_trips_clean
GROUP BY is_anomaly, anomaly_reason
ORDER BY count DESC;

SELECT
    has_valid_timestamps,
    has_valid_locations,
    is_valid_trip,
    COUNT(*) as count
FROM fhv_trips_clean
GROUP BY has_valid_timestamps, has_valid_locations, is_valid_trip
ORDER BY count DESC;

SELECT 
    pickup_datetime,
    dropoff_datetime,
    trip_duration_minutes,
    has_valid_timestamps,
    has_valid_locations,
    is_valid_trip,
    is_anomaly
FROM fhv_trips_clean
LIMIT 10;