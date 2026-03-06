-- ============================================================================
-- NYC TAXI PIPELINE - MONITORING SNOWPIPE
-- ============================================================================
-- Description : Surveiller l'activité Snowpipe en temps réel
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-06
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_analytics_wh;

-- ============================================================================
-- STATUT DES PIPES
-- ============================================================================

-- Voir tous les pipes
SHOW PIPES;

-- Statut détaillé de chaque pipe
SELECT SYSTEM$PIPE_STATUS('pipe_fhv') as fhv_status;
SELECT SYSTEM$PIPE_STATUS('pipe_yellow') as yellow_status;
SELECT SYSTEM$PIPE_STATUS('pipe_green') as green_status;

-- ============================================================================
-- HISTORIQUE CHARGEMENT (DERNIÈRE HEURE)
-- ============================================================================

-- Pipe FHV - Dernière heure
SELECT 
    pipe_name,
    file_name,
    stage_location,
    row_count,
    row_parsed,
    error_count,
    first_error_message,
    last_load_time
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'FHV_TRIPS_RAW',
    START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
ORDER BY last_load_time DESC;

-- Pipe Yellow - Dernière heure
SELECT 
    pipe_name,
    file_name,
    row_count,
    last_load_time
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'YELLOW_TRIPS_RAW',
    START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
ORDER BY last_load_time DESC;

-- ============================================================================
-- ACTIVITÉ SNOWPIPE (DERNIÈRES 24H)
-- ============================================================================

SELECT 
    pipe_name,
    credits_used,
    bytes_inserted,
    files_inserted
FROM TABLE(INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(
    DATE_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP())
))
ORDER BY pipe_name;

-- ============================================================================
-- VÉRIFIER LES NOUVELLES LIGNES
-- ============================================================================

-- Compter les lignes chargées dans la dernière heure
SELECT 
    'FHV' as taxi_type,
    COUNT(*) as rows_last_hour
FROM fhv_trips_raw
WHERE _loaded_at > DATEADD('hour', -1, CURRENT_TIMESTAMP())

UNION ALL

SELECT 
    'Yellow',
    COUNT(*)
FROM yellow_trips_raw
WHERE _loaded_at > DATEADD('hour', -1, CURRENT_TIMESTAMP())

UNION ALL

SELECT 
    'Green',
    COUNT(*)
FROM green_trips_raw
WHERE _loaded_at > DATEADD('hour', -1, CURRENT_TIMESTAMP());

-- ============================================================================
-- DERNIERS FICHIERS CHARGÉS
-- ============================================================================

SELECT 
    _source_file,
    COUNT(*) as row_count,
    MAX(_loaded_at) as loaded_at
FROM yellow_trips_raw
WHERE _loaded_at > DATEADD('hour', -1, CURRENT_TIMESTAMP())
GROUP BY _source_file
ORDER BY loaded_at DESC;