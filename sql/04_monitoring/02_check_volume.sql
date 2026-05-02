-- ============================================================================
-- NYC TAXI PIPELINE - MONITORING & SANTÉ DU PIPELINE
-- ============================================================================
USE DATABASE nyc_taxi_db;
USE WAREHOUSE nyc_transform_wh;

-- ============================================================================
-- CHECK 2 : VOLUME DES TABLES
-- Détecte si une table est vide ou a un volume anormalement bas
-- ============================================================================
SELECT '=== CHECK 2 : VOLUME DES TABLES ===' AS check_name;

SELECT
    'bronze.yellow_trips_raw'    AS table_name,
    COUNT(*)                      AS total_lignes,
    CASE WHEN COUNT(*) = 0 THEN '⚠️  ALERTE - Table vide' ELSE '✅ OK' END AS statut
FROM bronze.yellow_trips_raw
UNION ALL
SELECT 'bronze.green_trips_raw', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '⚠️  ALERTE - Table vide' ELSE '✅ OK' END
FROM bronze.green_trips_raw
UNION ALL
SELECT 'bronze.fhv_trips_raw', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '⚠️  ALERTE - Table vide' ELSE '✅ OK' END
FROM bronze.fhv_trips_raw
UNION ALL
SELECT 'silver.yellow_trips_clean', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '⚠️  ALERTE - Table vide' ELSE '✅ OK' END
FROM silver.yellow_trips_clean
UNION ALL
SELECT 'silver.green_trips_clean', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '⚠️  ALERTE - Table vide' ELSE '✅ OK' END
FROM silver.green_trips_clean
UNION ALL
SELECT 'silver.fhv_trips_clean', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '⚠️  ALERTE - Table vide' ELSE '✅ OK' END
FROM silver.fhv_trips_clean
UNION ALL
SELECT 'gold.daily_revenue_stats', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '⚠️  ALERTE - Table vide' ELSE '✅ OK' END
FROM gold.daily_revenue_stats
UNION ALL
SELECT 'gold.daily_passenger_stats', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '⚠️  ALERTE - Table vide' ELSE '✅ OK' END
FROM gold.daily_passenger_stats
UNION ALL
SELECT 'gold.daily_fleet_stats', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '⚠️  ALERTE - Table vide' ELSE '✅ OK' END
FROM gold.daily_fleet_stats;