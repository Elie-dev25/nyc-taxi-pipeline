-- ============================================================================
-- NYC TAXI PIPELINE - MONITORING & SANTÉ DU PIPELINE
-- ============================================================================
USE DATABASE nyc_taxi_db;
USE WAREHOUSE nyc_transform_wh;

-- ============================================================================
-- CHECK 4 : DÉTECTION DE DÉRIVES DE MÉTRIQUES
-- Détecte si les métriques clés changent anormalement d'un jour à l'autre
-- Alerte si le tarif moyen varie de plus de 50% par rapport à la veille
-- ============================================================================
SELECT '=== CHECK 4 : DÉRIVE DES MÉTRIQUES GOLD ===' AS check_name;

WITH dates AS (
    SELECT
        MAX(report_date)                     AS date_aujourdhui,
        DATEADD('day', -1, MAX(report_date)) AS date_veille
    FROM gold.daily_revenue_stats
    WHERE total_trips >= 100  -- ignorer les journées incomplètes
),
yesterday AS (
    SELECT r.taxi_type, r.avg_fare
    FROM gold.daily_revenue_stats r
    JOIN dates d ON r.report_date = d.date_veille
),
today AS (
    SELECT r.taxi_type, r.avg_fare
    FROM gold.daily_revenue_stats r
    JOIN dates d ON r.report_date = d.date_aujourdhui
)
SELECT
    t.taxi_type,
    y.avg_fare                                                        AS tarif_veille,
    t.avg_fare                                                        AS tarif_aujourdhui,
    ROUND(ABS(t.avg_fare - y.avg_fare) / NULLIF(y.avg_fare, 0) * 100, 2) AS variation_pct,
    CASE
        WHEN ABS(t.avg_fare - y.avg_fare) / NULLIF(y.avg_fare, 0) * 100 > 50
        THEN '⚠️  ALERTE - Dérive anormale du tarif'
        ELSE '✅ OK'
    END AS statut
FROM today t
JOIN yesterday y ON t.taxi_type = y.taxi_type;