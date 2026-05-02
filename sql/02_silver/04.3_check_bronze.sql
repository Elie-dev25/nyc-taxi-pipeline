USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;

SELECT 
    pickup_datetime as bronze_pickup_raw,
    TO_TIMESTAMP_NTZ(pickup_datetime / 1000000) as bronze_pickup_converted,
    dropoff_datetime as bronze_dropoff_raw,
    TO_TIMESTAMP_NTZ(dropoff_datetime / 1000000) as bronze_dropoff_converted
FROM fhv_trips_raw
WHERE TO_TIMESTAMP_NTZ(pickup_datetime / 1000000) = '2025-03-28 13:59:11'
LIMIT 1;