-- ============================================================================
-- VÉRIFICATION SIMPLE - Nouvelles lignes chargées ?
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_analytics_wh;

-- ============================================================================
-- QUESTION 1 : Combien de lignes au total dans yellow_trips_raw ?
-- ============================================================================

SELECT COUNT(*) as total_rows 
FROM yellow_trips_raw;

-- ============================================================================
-- QUESTION 2 : Combien de lignes chargées dans les 5 dernières minutes ?
-- ============================================================================

SELECT COUNT(*) as rows_last_5_minutes
FROM yellow_trips_raw
WHERE _loaded_at > DATEADD('minute', -5, CURRENT_TIMESTAMP());

--  > 0 → Snowpipe a chargé quelque chose

-- ============================================================================
-- QUESTION 3 : Quels fichiers ont été chargés récemment ?
-- ============================================================================

SELECT 
    _source_file as fichier,
    COUNT(*) as nombre_lignes,
    MAX(_loaded_at) as heure_chargement
FROM yellow_trips_raw
WHERE _loaded_at > DATEADD('minute', -10, CURRENT_TIMESTAMP())
GROUP BY _source_file
ORDER BY heure_chargement DESC;

-- Voir TEST_SNOWPIPE_yellow.parquet  Signifie que ca marche 

-- ============================================================================
-- QUESTION 4 : Voir quelques lignes du nouveau fichier
-- ============================================================================

SELECT *
FROM yellow_trips_raw
WHERE _source_file LIKE '%TEST_SNOWPIPE%'
LIMIT 10;