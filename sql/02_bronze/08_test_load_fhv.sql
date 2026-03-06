-- ============================================================================
-- NYC TAXI PIPELINE - TEST CHARGEMENT FHV
-- ============================================================================
-- Description : Tester le chargement manuel avant Snowpipe
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-06
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_loading_wh;

-- ============================================================================
-- CHARGEMENT MANUEL (COPY INTO)
-- ============================================================================

-- Vider la table (si on a déjà testé)
TRUNCATE TABLE fhv_trips_raw;

-- Charger les données
COPY INTO fhv_trips_raw (
    dispatching_base_num,
    pickup_datetime,
    dropoff_datetime,
    PUlocationID,
    DOlocationID,
    SR_Flag,
    Affiliated_base_number,
    _source_file,
    _file_row_number
)
FROM (
    SELECT 
        $1:dispatching_base_num::VARCHAR(50),
        $1:pickup_datetime::NUMBER(38,0),
        $1:dropOff_datetime::NUMBER(38,0),  -- Note: 'dropOff' avec majuscule O
        $1:PUlocationID::NUMBER(38,0),
        $1:DOlocationID::NUMBER(38,0),
        $1:SR_Flag::NUMBER(38,0),
        $1:Affiliated_base_number::VARCHAR(50),
        metadata$filename,
        metadata$file_row_number
    FROM @stage_fhv
)
FILE_FORMAT = ff_parquet_nyc
ON_ERROR = 'CONTINUE';

-- ============================================================================
-- VÉRIFICATIONS
-- ============================================================================

-- Combien de lignes chargées ?
-- SELECT COUNT(*) as total_rows FROM fhv_trips_raw;

-- Voir les 10 premières lignes
-- SELECT * FROM fhv_trips_raw LIMIT 10;

-- Stats par fichier source
-- SELECT 
--     _source_file,
--     COUNT(*) as row_count,
--     MIN(_loaded_at) as first_loaded,
--     MAX(_loaded_at) as last_loaded
-- FROM fhv_trips_raw
-- GROUP BY _source_file
-- ORDER BY _source_file;

-- Vérifier les timestamps (convertir en dates lisibles)
-- SELECT 
--     pickup_datetime as pickup_raw,
--     TO_TIMESTAMP_NTZ(pickup_datetime / 1000000) as pickup_converted,
--     dropoff_datetime as dropoff_raw,
--     TO_TIMESTAMP_NTZ(dropoff_datetime / 1000000) as dropoff_converted,
--     _source_file
-- FROM fhv_trips_raw
-- LIMIT 5;
