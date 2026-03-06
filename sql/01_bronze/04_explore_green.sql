-- ============================================================================
-- NYC TAXI PIPELINE - EXPLORATION GREEN TAXI DATA
-- ============================================================================
-- Description : Explorer la structure des fichiers Green Taxi Parquet
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2024-03-05
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_analytics_wh;

-- ============================================================================
-- INFER_SCHEMA : Détecter structure
-- ============================================================================

SELECT *
FROM TABLE(
  INFER_SCHEMA(
    LOCATION => '@stage_green',
    FILE_FORMAT => 'ff_parquet_nyc'
  )
);


-- -- Compter les lignes

-- SELECT 
--     metadata$filename as filename,
--     COUNT(*) as row_count
-- FROM @stage_green
-- GROUP BY metadata$filename
-- ORDER BY filename;


-- -- Aperçu des données


-- SELECT *
-- FROM @stage_green
-- LIMIT 100;

