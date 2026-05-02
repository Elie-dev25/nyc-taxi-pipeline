-- ============================================================================
-- NYC TAXI PIPELINE - TRANSFORMATION GOLD LAYER
-- ============================================================================
USE DATABASE nyc_taxi_db;
USE SCHEMA gold;
USE WAREHOUSE nyc_transform_wh;

-- ============================================================================
-- TABLE 1 : DAILY REVENUE STATS
-- Note : FHV exclu car pas de données de tarification disponibles
-- Source : yellow_trips_clean + green_trips_clean (Silver Layer)
-- ============================================================================
TRUNCATE TABLE daily_revenue_stats;

INSERT INTO daily_revenue_stats (
    report_date,
    taxi_type,
    total_trips,
    total_revenue,
    avg_fare,
    avg_tip_pct,
    avg_trip_distance,
    avg_duration_minutes,
    _gold_loaded_at
)

-- Yellow
SELECT
    pickup_date                        AS report_date,
    'Yellow'                           AS taxi_type,
    COUNT(*)                           AS total_trips,
    ROUND(SUM(total_amount), 2)        AS total_revenue,
    ROUND(AVG(fare_amount), 2)         AS avg_fare,
    ROUND(AVG(tip_percentage), 2)      AS avg_tip_pct,
    ROUND(AVG(trip_distance), 2)       AS avg_trip_distance,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    CURRENT_TIMESTAMP()                AS _gold_loaded_at
FROM silver.yellow_trips_clean
WHERE is_valid_trip = TRUE
GROUP BY pickup_date

UNION ALL

-- Green
SELECT
    pickup_date                        AS report_date,
    'Green'                            AS taxi_type,
    COUNT(*)                           AS total_trips,
    ROUND(SUM(total_amount), 2)        AS total_revenue,
    ROUND(AVG(fare_amount), 2)         AS avg_fare,
    ROUND(AVG(tip_percentage), 2)      AS avg_tip_pct,
    ROUND(AVG(trip_distance), 2)       AS avg_trip_distance,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    CURRENT_TIMESTAMP()                AS _gold_loaded_at
FROM silver.green_trips_clean
WHERE is_valid_trip = TRUE
GROUP BY pickup_date

ORDER BY report_date, taxi_type;

-- ============================================================================
-- TABLE 2 : DAILY PASSENGER STATS
-- Note : FHV inclus mais passenger_count sera NULL (non disponible)
-- ============================================================================
TRUNCATE TABLE daily_passenger_stats;

INSERT INTO daily_passenger_stats (
    report_date,
    taxi_type,
    total_trips,
    total_passengers,
    avg_passengers_per_trip,
    _gold_loaded_at
)

-- Yellow
SELECT
    pickup_date                             AS report_date,
    'Yellow'                                AS taxi_type,
    COUNT(*)                                AS total_trips,
    SUM(passenger_count)                    AS total_passengers,
    ROUND(AVG(passenger_count), 2)          AS avg_passengers_per_trip,
    CURRENT_TIMESTAMP()                     AS _gold_loaded_at
FROM silver.yellow_trips_clean
WHERE is_valid_trip = TRUE
GROUP BY pickup_date

UNION ALL

-- Green
SELECT
    pickup_date                             AS report_date,
    'Green'                                 AS taxi_type,
    COUNT(*)                                AS total_trips,
    SUM(passenger_count)                    AS total_passengers,
    ROUND(AVG(passenger_count), 2)          AS avg_passengers_per_trip,
    CURRENT_TIMESTAMP()                     AS _gold_loaded_at
FROM silver.green_trips_clean
WHERE is_valid_trip = TRUE
GROUP BY pickup_date

UNION ALL

-- FHV (pas de passenger_count — NULL explicite)
SELECT
    pickup_date                             AS report_date,
    'FHV'                                   AS taxi_type,
    COUNT(*)                                AS total_trips,
    NULL                                    AS total_passengers,
    NULL                                    AS avg_passengers_per_trip,
    CURRENT_TIMESTAMP()                     AS _gold_loaded_at
FROM silver.fhv_trips_clean
WHERE is_valid_trip = TRUE
GROUP BY pickup_date

ORDER BY report_date, taxi_type;

-- ============================================================================
-- TABLE 3 : DAILY FLEET STATS
-- Note : active_vehicles disponible uniquement pour FHV (dispatching_base_num)
--        Yellow et Green n'exposent pas d'identifiant unique par véhicule
--        dans les données publiques TLC — colonne NULL pour ces types
-- ============================================================================
TRUNCATE TABLE daily_fleet_stats;

INSERT INTO daily_fleet_stats (
    report_date,
    taxi_type,
    active_vehicles,
    total_trips,
    avg_trips_per_vehicle,
    _gold_loaded_at
)

-- Yellow
SELECT
    pickup_date                                    AS report_date,
    'Yellow'                                       AS taxi_type,
    NULL                                           AS active_vehicles,
    COUNT(*)                                       AS total_trips,
    NULL                                           AS avg_trips_per_vehicle,
    CURRENT_TIMESTAMP()                            AS _gold_loaded_at
FROM silver.yellow_trips_clean
WHERE is_valid_trip = TRUE
GROUP BY pickup_date

UNION ALL

-- Green
SELECT
    pickup_date                                    AS report_date,
    'Green'                                        AS taxi_type,
    NULL                                           AS active_vehicles,
    COUNT(*)                                       AS total_trips,
    NULL                                           AS avg_trips_per_vehicle,
    CURRENT_TIMESTAMP()                            AS _gold_loaded_at
FROM silver.green_trips_clean
WHERE is_valid_trip = TRUE
GROUP BY pickup_date

UNION ALL

-- FHV
SELECT
    pickup_date                                              AS report_date,
    'FHV'                                                    AS taxi_type,
    COUNT(DISTINCT dispatching_base_num)                     AS active_vehicles,
    COUNT(*)                                                 AS total_trips,
    ROUND(COUNT(*) / COUNT(DISTINCT dispatching_base_num), 2) AS avg_trips_per_vehicle,
    CURRENT_TIMESTAMP()                                      AS _gold_loaded_at
FROM silver.fhv_trips_clean
WHERE is_valid_trip = TRUE
GROUP BY pickup_date

ORDER BY report_date, taxi_type;

-- ============================================================================
-- VÉRIFICATIONS
-- ============================================================================
SELECT 'DAILY REVENUE STATS' AS table_name, COUNT(*) AS rows FROM daily_revenue_stats
UNION ALL
SELECT 'DAILY PASSENGER STATS', COUNT(*) FROM daily_passenger_stats
UNION ALL
SELECT 'DAILY FLEET STATS', COUNT(*) FROM daily_fleet_stats;

-- Aperçu revenus
SELECT * FROM daily_revenue_stats
ORDER BY report_date DESC, taxi_type
LIMIT 10;

-- Aperçu passagers
SELECT * FROM daily_passenger_stats
ORDER BY report_date DESC, taxi_type
LIMIT 10;

-- Aperçu flotte
SELECT * FROM daily_fleet_stats
ORDER BY report_date DESC, taxi_type
LIMIT 10;