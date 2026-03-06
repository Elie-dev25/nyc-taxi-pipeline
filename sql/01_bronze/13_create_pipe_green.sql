-- ============================================================================
-- NYC TAXI PIPELINE - SNOWPIPE GREEN TAXI
-- ============================================================================
-- Description : Pipe pour chargement automatique Green Taxi
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-06
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_loading_wh;

-- ============================================================================
-- SNOWPIPE : PIPE_GREEN
-- ============================================================================

CREATE OR REPLACE PIPE pipe_green
  AUTO_INGEST = TRUE
  COMMENT = 'Auto-ingest pipe pour Green Taxi trips'
AS
COPY INTO green_trips_raw (
    VendorID,
    lpep_pickup_datetime,
    lpep_dropoff_datetime,
    store_and_fwd_flag,
    RatecodeID,
    PULocationID,
    DOLocationID,
    passenger_count,
    trip_distance,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    ehail_fee,
    improvement_surcharge,
    total_amount,
    payment_type,
    trip_type,
    congestion_surcharge,
    cbd_congestion_fee,
    _source_file,
    _file_row_number
)
FROM (
    SELECT 
        $1:VendorID::NUMBER(38,0),
        $1:lpep_pickup_datetime::NUMBER(38,0),
        $1:lpep_dropoff_datetime::NUMBER(38,0),
        $1:store_and_fwd_flag::VARCHAR(10),
        $1:RatecodeID::NUMBER(38,0),
        $1:PULocationID::NUMBER(38,0),
        $1:DOLocationID::NUMBER(38,0),
        $1:passenger_count::NUMBER(38,0),
        $1:trip_distance::REAL,
        $1:fare_amount::REAL,
        $1:extra::REAL,
        $1:mta_tax::REAL,
        $1:tip_amount::REAL,
        $1:tolls_amount::REAL,
        $1:ehail_fee::REAL,
        $1:improvement_surcharge::REAL,
        $1:total_amount::REAL,
        $1:payment_type::NUMBER(38,0),
        $1:trip_type::NUMBER(38,0),
        $1:congestion_surcharge::REAL,
        $1:cbd_congestion_fee::REAL,
        metadata$filename,
        metadata$file_row_number
    FROM @stage_green
)
FILE_FORMAT = ff_parquet_nyc;

-- Récupérer notification_channel
-- DESC PIPE pipe_green;

-- SHOW PIPES LIKE 'pipe_green';

SELECT 'Pipe pipe_green created' as status;