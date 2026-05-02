-- ============================================================================
-- NYC TAXI PIPELINE - MONITORING & SANTÉ DU PIPELINE
-- ============================================================================
USE DATABASE nyc_taxi_db;
USE WAREHOUSE nyc_transform_wh;

-- ============================================================================
-- CHECK 1 : FRAÎCHEUR DES DONNÉES
-- Détecte si les données n'arrivent plus (dernière date chargée)
-- Alerte si pas de nouvelles données depuis plus de 2 jours
-- ============================================================================
SELECT '=== CHECK 1 : FRAÎCHEUR DES DONNÉES ===' AS check_name;

SELECT
    'Bronze - Yellow' AS source,
    MAX(DATE(_loaded_at)) AS derniere_charge,
    DATEDIFF('day', MAX(DATE(_loaded_at)), CURRENT_DATE()) AS jours_depuis_charge,
    CASE
        WHEN DATEDIFF('day', MAX(DATE(_loaded_at)), CURRENT_DATE()) > 2
        THEN '⚠️  ALERTE - Données trop anciennes'
        ELSE '✅ OK'
    END AS statut
FROM bronze.yellow_trips_raw

UNION ALL

SELECT
    'Bronze - Green',
    MAX(DATE(_loaded_at)),
    DATEDIFF('day', MAX(DATE(_loaded_at)), CURRENT_DATE()),
    CASE
        WHEN DATEDIFF('day', MAX(DATE(_loaded_at)), CURRENT_DATE()) > 2
        THEN '⚠️  ALERTE - Données trop anciennes'
        ELSE '✅ OK'
    END
FROM bronze.green_trips_raw

UNION ALL

SELECT
    'Bronze - FHV',
    MAX(DATE(_loaded_at)),
    DATEDIFF('day', MAX(DATE(_loaded_at)), CURRENT_DATE()),
    CASE
        WHEN DATEDIFF('day', MAX(DATE(_loaded_at)), CURRENT_DATE()) > 2
        THEN '⚠️  ALERTE - Données trop anciennes'
        ELSE '✅ OK'
    END
FROM bronze.fhv_trips_raw

UNION ALL

SELECT
    'Silver - Yellow',
    MAX(DATE(_silver_loaded_at)),
    DATEDIFF('day', MAX(DATE(_silver_loaded_at)), CURRENT_DATE()),
    CASE
        WHEN DATEDIFF('day', MAX(DATE(_silver_loaded_at)), CURRENT_DATE()) > 2
        THEN '⚠️  ALERTE - Données trop anciennes'
        ELSE '✅ OK'
    END
FROM silver.yellow_trips_clean

UNION ALL

SELECT
    'Silver - Green',
    MAX(DATE(_silver_loaded_at)),
    DATEDIFF('day', MAX(DATE(_silver_loaded_at)), CURRENT_DATE()),
    CASE
        WHEN DATEDIFF('day', MAX(DATE(_silver_loaded_at)), CURRENT_DATE()) > 2
        THEN '⚠️  ALERTE - Données trop anciennes'
        ELSE '✅ OK'
    END
FROM silver.green_trips_clean

UNION ALL

SELECT
    'Silver - FHV',
    MAX(DATE(_silver_loaded_at)),
    DATEDIFF('day', MAX(DATE(_silver_loaded_at)), CURRENT_DATE()),
    CASE
        WHEN DATEDIFF('day', MAX(DATE(_silver_loaded_at)), CURRENT_DATE()) > 2
        THEN '⚠️  ALERTE - Données trop anciennes'
        ELSE '✅ OK'
    END
FROM silver.fhv_trips_clean

UNION ALL

SELECT
    'Gold',
    MAX(DATE(_gold_loaded_at)),
    DATEDIFF('day', MAX(DATE(_gold_loaded_at)), CURRENT_DATE()),
    CASE
        WHEN DATEDIFF('day', MAX(DATE(_gold_loaded_at)), CURRENT_DATE()) > 2
        THEN '⚠️  ALERTE - Données trop anciennes'
        ELSE '✅ OK'
    END
FROM gold.daily_revenue_stats

ORDER BY source;