-- ============================================================================
-- NYC TAXI PIPELINE - SNOWPIPE YELLOW TAXI
-- ============================================================================
-- Description : Pipe pour chargement automatique Yellow Taxi
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-06
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_loading_wh;

-- ============================================================================
-- SNOWPIPE : PIPE_YELLOW
-- ============================================================================

CREATE OR REPLACE PIPE pipe_yellow
  AUTO_INGEST = TRUE
  COMMENT = 'Auto-ingest pipe pour Yellow Taxi trips'
AS
COPY INTO yellow_trips_raw (
    VendorID,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    passenger_count,
    trip_distance,
    RatecodeID,
    store_and_fwd_flag,
    PULocationID,
    DOLocationID,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    Airport_fee,
    cbd_congestion_fee,
    _source_file,
    _file_row_number
)
FROM (
    SELECT 
        $1:VendorID::NUMBER(38,0),
        $1:tpep_pickup_datetime::NUMBER(38,0),
        $1:tpep_dropoff_datetime::NUMBER(38,0),
        $1:passenger_count::NUMBER(38,0),
        $1:trip_distance::REAL,
        $1:RatecodeID::NUMBER(38,0),
        $1:store_and_fwd_flag::VARCHAR(10),
        $1:PULocationID::NUMBER(38,0),
        $1:DOLocationID::NUMBER(38,0),
        $1:payment_type::NUMBER(38,0),
        $1:fare_amount::REAL,
        $1:extra::REAL,
        $1:mta_tax::REAL,
        $1:tip_amount::REAL,
        $1:tolls_amount::REAL,
        $1:improvement_surcharge::REAL,
        $1:total_amount::REAL,
        $1:congestion_surcharge::REAL,
        $1:Airport_fee::REAL,
        $1:cbd_congestion_fee::REAL,
        metadata$filename,
        metadata$file_row_number
    FROM @stage_yellow
)
FILE_FORMAT = ff_parquet_nyc;

-- Récupérer notification_channel
-- DESC PIPE pipe_yellow;

-- SHOW PIPES LIKE 'pipe_yellow';

SELECT 'Pipe pipe_yellow created' as status;