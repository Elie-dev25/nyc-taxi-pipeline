-- ============================================================================
-- NYC TAXI PIPELINE - MONITORING & SANTÉ DU PIPELINE
-- ============================================================================
USE DATABASE nyc_taxi_db;
USE WAREHOUSE nyc_transform_wh;

-- ============================================================================
-- CHECK 3 : QUALITÉ DES DONNÉES SILVER
-- Détecte si le taux de validité chute en dessous du seuil acceptable
-- Seuil : 85% minimum (alerte si moins)
-- ============================================================================
SELECT '=== CHECK 3 : QUALITÉ DES DONNÉES SILVER ===' AS check_name;

SELECT
    'Yellow' AS taxi_type,
    COUNT(*) AS total_lignes,
    SUM(CASE WHEN is_valid_trip THEN 1 ELSE 0 END) AS lignes_valides,
    ROUND(SUM(CASE WHEN is_valid_trip THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS taux_validite,
    CASE
        WHEN ROUND(SUM(CASE WHEN is_valid_trip THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) < 85
        THEN '⚠️  ALERTE - Qualité dégradée'
        ELSE '✅ OK'
    END AS statut
FROM silver.yellow_trips_clean

UNION ALL

SELECT
    'Green',
    COUNT(*),
    SUM(CASE WHEN is_valid_trip THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN is_valid_trip THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
    CASE
        WHEN ROUND(SUM(CASE WHEN is_valid_trip THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) < 85
        THEN '⚠️  ALERTE - Qualité dégradée'
        ELSE '✅ OK'
    END
FROM silver.green_trips_clean

UNION ALL

SELECT
    'FHV',
    COUNT(*),
    SUM(CASE WHEN is_valid_trip THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN is_valid_trip THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
    CASE
        WHEN ROUND(SUM(CASE WHEN is_valid_trip THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) < 85
        THEN '⚠️  ALERTE - Qualité dégradée'
        ELSE '✅ OK'
    END
FROM silver.fhv_trips_clean;