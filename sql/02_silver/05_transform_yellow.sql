-- ============================================================================
-- NYC TAXI PIPELINE - TRANSFORMATION YELLOW (BRONZE → SILVER)
-- ============================================================================
USE DATABASE nyc_taxi_db;
USE SCHEMA silver;
USE WAREHOUSE nyc_transform_wh;

TRUNCATE TABLE yellow_trips_clean;

INSERT INTO yellow_trips_clean (
    vendor_id,
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    ratecode_id,
    store_and_fwd_flag,
    pickup_location_id,
    dropoff_location_id,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee,
    trip_duration_minutes,
    trip_duration_hours,
    avg_speed_mph,
    tip_percentage,
    cost_per_mile,
    trip_distance_category,
    fare_category,
    pickup_hour,
    pickup_day_of_week,
    pickup_date,
    pickup_month,
    pickup_year,
    is_weekend,
    is_rush_hour,
    is_valid_trip,
    is_anomaly,
    anomaly_reason,
    _source_file,
    _bronze_loaded_at,
    _silver_loaded_at
)

WITH converted AS (
    -- Même chose qu'avant : conversions de types
    SELECT
        VENDORID AS vendor_id,
        TO_TIMESTAMP_NTZ(tpep_pickup_datetime / 1000000)  AS pickup_datetime,
        TO_TIMESTAMP_NTZ(tpep_dropoff_datetime / 1000000) AS dropoff_datetime,
        passenger_count,
        trip_distance,
        RATECODEID AS ratecode_id,
        store_and_fwd_flag,
        PULocationID AS pickup_location_id,
        DOLocationID AS dropoff_location_id,
        payment_type,
        CAST(fare_amount           AS NUMBER(10,2)) AS fare_amount,
        CAST(extra                 AS NUMBER(10,2)) AS extra,
        CAST(mta_tax               AS NUMBER(10,2)) AS mta_tax,
        CAST(tip_amount            AS NUMBER(10,2)) AS tip_amount,
        CAST(tolls_amount          AS NUMBER(10,2)) AS tolls_amount,
        CAST(improvement_surcharge AS NUMBER(10,2)) AS improvement_surcharge,
        CAST(total_amount          AS NUMBER(10,2)) AS total_amount,
        CAST(congestion_surcharge  AS NUMBER(10,2)) AS congestion_surcharge,
        CAST(airport_fee           AS NUMBER(10,2)) AS airport_fee,
        CAST(cbd_congestion_fee    AS NUMBER(10,2)) AS cbd_congestion_fee,
        TIMESTAMPDIFF(SECOND,
            TO_TIMESTAMP_NTZ(tpep_pickup_datetime / 1000000),
            TO_TIMESTAMP_NTZ(tpep_dropoff_datetime / 1000000)
        ) / 60.0   AS trip_duration_minutes,
        TIMESTAMPDIFF(SECOND,
            TO_TIMESTAMP_NTZ(tpep_pickup_datetime / 1000000),
            TO_TIMESTAMP_NTZ(tpep_dropoff_datetime / 1000000)
        ) / 3600.0 AS trip_duration_hours,
        HOUR(TO_TIMESTAMP_NTZ(tpep_pickup_datetime / 1000000))    AS pickup_hour,
        DAYNAME(TO_TIMESTAMP_NTZ(tpep_pickup_datetime / 1000000)) AS pickup_day_of_week,
        DATE(TO_TIMESTAMP_NTZ(tpep_pickup_datetime / 1000000))    AS pickup_date,
        MONTH(TO_TIMESTAMP_NTZ(tpep_pickup_datetime / 1000000))   AS pickup_month,
        YEAR(TO_TIMESTAMP_NTZ(tpep_pickup_datetime / 1000000))    AS pickup_year,
        _source_file,
        _loaded_at AS _bronze_loaded_at
    FROM bronze.yellow_trips_raw
),

with_calculations AS (
    -- NOUVEAU CTE : calculs dérivés qui ont besoin des types corrects
    SELECT
        *,
        CASE
            WHEN trip_duration_hours > 0 AND trip_distance > 0
                THEN ROUND(trip_distance / trip_duration_hours, 2)
            ELSE NULL
        END AS avg_speed_mph,
        CASE
            WHEN fare_amount > 0 AND tip_amount IS NOT NULL
                THEN ROUND((tip_amount / fare_amount) * 100, 2)
            ELSE 0
        END AS tip_percentage,
        CASE
            WHEN trip_distance > 0 AND total_amount IS NOT NULL
                THEN ROUND(total_amount / trip_distance, 2)
            ELSE NULL
        END AS cost_per_mile,
        CASE
            WHEN trip_distance < 1    THEN 'Short'
            WHEN trip_distance <= 5   THEN 'Medium'
            ELSE                           'Long'
        END AS trip_distance_category,
        CASE
            WHEN fare_amount < 10  THEN 'Low'
            WHEN fare_amount <= 30 THEN 'Medium'
            ELSE                        'High'
        END AS fare_category,
        CASE
            WHEN pickup_day_of_week IN ('Sat', 'Sun') THEN TRUE
            ELSE FALSE
        END AS is_weekend,
        CASE
            WHEN pickup_day_of_week NOT IN ('Sat', 'Sun')
             AND (pickup_hour BETWEEN 7 AND 8
               OR pickup_hour BETWEEN 17 AND 18)
            THEN TRUE
            ELSE FALSE
        END AS is_rush_hour
    FROM converted
),

with_flags AS (
    -- Maintenant avg_speed_mph est disponible !
    SELECT
        *,
        CASE
            WHEN pickup_datetime IS NULL               THEN FALSE
            WHEN dropoff_datetime IS NULL              THEN FALSE
            WHEN dropoff_datetime <= pickup_datetime   THEN FALSE
            ELSE TRUE
        END AS has_valid_timestamps,
        CASE
            WHEN pickup_location_id IS NULL  THEN FALSE
            WHEN dropoff_location_id IS NULL THEN FALSE
            ELSE TRUE
        END AS has_valid_locations,
        CASE
            WHEN trip_duration_minutes < 1    THEN TRUE
            WHEN trip_duration_minutes > 1440 THEN TRUE
            WHEN trip_distance <= 0           THEN TRUE
            WHEN fare_amount <= 0             THEN TRUE
            WHEN avg_speed_mph > 65           THEN TRUE
            ELSE FALSE
        END AS is_anomaly,
        CASE
            WHEN trip_duration_minutes < 1    THEN 'Durée trop courte (< 1 min)'
            WHEN trip_duration_minutes > 1440 THEN 'Durée trop longue (> 24h)'
            WHEN trip_distance <= 0           THEN 'Distance invalide (<= 0)'
            WHEN fare_amount <= 0             THEN 'Tarif invalide (<= 0)'
            WHEN avg_speed_mph > 65           THEN 'Vitesse moyenne trop élevée (> 65 mph)'
            ELSE NULL
        END AS anomaly_reason
    FROM with_calculations
),

final AS (
    SELECT
        *,
        has_valid_timestamps AND has_valid_locations AND NOT is_anomaly AS is_valid_trip,
        CURRENT_TIMESTAMP() AS _silver_loaded_at
    FROM with_flags
)

SELECT
    vendor_id, pickup_datetime, dropoff_datetime,
    passenger_count, trip_distance, ratecode_id, store_and_fwd_flag,
    pickup_location_id, dropoff_location_id,
    payment_type, fare_amount, extra, mta_tax, tip_amount, tolls_amount,
    improvement_surcharge, total_amount, congestion_surcharge,
    airport_fee, cbd_congestion_fee,
    trip_duration_minutes, trip_duration_hours,
    avg_speed_mph, tip_percentage, cost_per_mile,
    trip_distance_category, fare_category,
    pickup_hour, pickup_day_of_week, pickup_date, pickup_month, pickup_year,
    is_weekend, is_rush_hour,
    is_valid_trip, is_anomaly, anomaly_reason,
    _source_file, _bronze_loaded_at, _silver_loaded_at
FROM final;

-- ============================================================================
-- VÉRIFICATIONS
-- ============================================================================
SELECT COUNT(*) AS total_rows FROM yellow_trips_clean;

SELECT is_valid_trip, is_anomaly, COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM yellow_trips_clean
GROUP BY is_valid_trip, is_anomaly ORDER BY count DESC;

SELECT is_anomaly, anomaly_reason, COUNT(*) AS count
FROM yellow_trips_clean
GROUP BY is_anomaly, anomaly_reason ORDER BY count DESC;

SELECT
    ROUND(AVG(fare_amount), 2)          AS avg_fare,
    ROUND(AVG(tip_percentage), 2)       AS avg_tip_pct,
    ROUND(AVG(trip_distance), 2)        AS avg_distance_miles,
    ROUND(AVG(trip_duration_minutes),2) AS avg_duration_min,
    ROUND(AVG(avg_speed_mph), 2)        AS avg_speed
FROM yellow_trips_clean
WHERE is_valid_trip = TRUE;