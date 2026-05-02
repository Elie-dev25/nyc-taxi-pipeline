-- sql/02_silver/08_count_nulls_bronze.sql
USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;

SELECT 
    COUNT(*) as total_rows,
    
    COUNT(CASE WHEN pickup_datetime IS NULL THEN 1 END) as pickup_null,
    COUNT(CASE WHEN dropoff_datetime IS NULL THEN 1 END) as dropoff_null,
    COUNT(CASE WHEN TO_TIMESTAMP_NTZ(dropoff_datetime / 1000000) <= TO_TIMESTAMP_NTZ(pickup_datetime / 1000000) THEN 1 END) as dropoff_before_pickup,
    
    -- Combien ont timestamps invalides selon ta logique FLAG 1 ?
    COUNT(CASE 
        WHEN TO_TIMESTAMP_NTZ(pickup_datetime / 1000000) IS NULL THEN 1
        WHEN TO_TIMESTAMP_NTZ(dropoff_datetime / 1000000) IS NULL THEN 1
        WHEN TO_TIMESTAMP_NTZ(dropoff_datetime / 1000000) <= TO_TIMESTAMP_NTZ(pickup_datetime / 1000000) THEN 1
    END) as invalid_timestamps_count
    
FROM fhv_trips_raw;