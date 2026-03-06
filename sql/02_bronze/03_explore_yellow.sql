-- ============================================================================
-- NYC TAXI PIPELINE - EXPLORATION YELLOW TAXI DATA
-- ============================================================================
-- Description : Explorer la structure des fichiers Yellow Taxi Parquet
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-05
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_analytics_wh;


-- INFER_SCHEMA : Détecter structure

SELECT *
FROM TABLE(
  INFER_SCHEMA(
    LOCATION => '@stage_yellow',
    FILE_FORMAT => 'ff_parquet_nyc'
  )
);


-- -- Compter les lignes


-- SELECT 
--     metadata$filename as filename,
--     COUNT(*) as row_count
-- FROM @stage_yellow
-- GROUP BY metadata$filename
-- ORDER BY filename;


-- -- Aperçu des données

-- SELECT *
-- FROM @stage_yellow
-- LIMIT 100;

-- -- Statistiques rapides


-- SELECT 
--     COUNT(*) as total_rows,
--     COUNT(DISTINCT $1:VendorID) as vendors,
--     MIN($1:tpep_pickup_datetime) as earliest_trip,
--     MAX($1:tpep_pickup_datetime) as latest_trip,
--     AVG($1:fare_amount::FLOAT) as avg_fare,
--     AVG($1:trip_distance::FLOAT) as avg_distance
-- FROM @stage_yellow;