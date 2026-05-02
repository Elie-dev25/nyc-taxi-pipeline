-- ============================================================================
-- NYC TAXI PIPELINE - MONITORING & SANTÉ DU PIPELINE
-- ============================================================================
USE DATABASE nyc_taxi_db;
USE WAREHOUSE nyc_transform_wh;

-- ============================================================================
-- CHECK 5 : COHÉRENCE BRONZE → SILVER
-- Vérifie que le nombre de lignes Silver est proche du Bronze
-- Alerte si on perd plus de 20% des lignes entre Bronze et Silver
-- ============================================================================
SELECT '=== CHECK 5 : COHÉRENCE BRONZE → SILVER ===' AS check_name;

SELECT
    'Yellow' AS taxi_type,
    b.total_bronze,
    s.total_silver,
    ROUND((b.total_bronze - s.total_silver) * 100.0 / b.total_bronze, 2) AS pct_perte,
    CASE
        WHEN ROUND((b.total_bronze - s.total_silver) * 100.0 / b.total_bronze, 2) > 20
        THEN '⚠️  ALERTE - Perte excessive de lignes'
        ELSE '✅ OK'
    END AS statut
FROM
    (SELECT COUNT(*) AS total_bronze FROM bronze.yellow_trips_raw) b,
    (SELECT COUNT(*) AS total_silver FROM silver.yellow_trips_clean) s

UNION ALL

SELECT
    'Green',
    b.total_bronze, s.total_silver,
    ROUND((b.total_bronze - s.total_silver) * 100.0 / b.total_bronze, 2),
    CASE
        WHEN ROUND((b.total_bronze - s.total_silver) * 100.0 / b.total_bronze, 2) > 20
        THEN '⚠️  ALERTE - Perte excessive de lignes'
        ELSE '✅ OK'
    END
FROM
    (SELECT COUNT(*) AS total_bronze FROM bronze.green_trips_raw) b,
    (SELECT COUNT(*) AS total_silver FROM silver.green_trips_clean) s

UNION ALL

SELECT
    'FHV',
    b.total_bronze, s.total_silver,
    ROUND((b.total_bronze - s.total_silver) * 100.0 / b.total_bronze, 2),
    CASE
        WHEN ROUND((b.total_bronze - s.total_silver) * 100.0 / b.total_bronze, 2) > 20
        THEN '⚠️  ALERTE - Perte excessive de lignes'
        ELSE '✅ OK'
    END
FROM
    (SELECT COUNT(*) AS total_bronze FROM bronze.fhv_trips_raw) b,
    (SELECT COUNT(*) AS total_silver FROM silver.fhv_trips_clean) s;
