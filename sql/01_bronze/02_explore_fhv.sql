-- ============================================================================
-- NYC TAXI PIPELINE - EXPLORATION FHV DATA
-- ============================================================================
-- Description : Explorer la structure des fichiers FHV Parquet
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-05
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_analytics_wh;


-- MÉTHODE 1 : INFER_SCHEMA (Détecter structure automatiquement)


SELECT *
FROM TABLE(
  INFER_SCHEMA(
    LOCATION => '@stage_fhv',
    FILE_FORMAT => 'ff_parquet_nyc'
  )
);


-- -- MÉTHODE 2 : Lire directement les données (APERÇU)

-- -- Voir les 10 premières lignes du premier fichier
-- SELECT 
--     $1 as metadata,
--     * 
-- FROM @stage_fhv/fhv_tripdata_2025-01.parquet
-- LIMIT 10;

-- -- MÉTHODE 3 : Compter les lignes (Volume)

-- -- Combien de lignes dans chaque fichier ?
-- SELECT 
--     metadata$filename as filename,
--     COUNT(*) as row_count
-- FROM @stage_fhv
-- GROUP BY metadata$filename
-- ORDER BY filename;

-- -- MÉTHODE 4 : Aperçu des valeurs (Sample)

-- -- Échantillon de 100 lignes pour comprendre les données
-- SELECT *
-- FROM @stage_fhv
-- LIMIT 100;