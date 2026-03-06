-- ============================================================================
-- NYC TAXI PIPELINE - VIRTUAL WAREHOUSES
-- ============================================================================
-- Description : Warehouses dédiés (isolation compute)
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-02
-- ============================================================================

USE ROLE ACCOUNTADMIN;


-- WAREHOUSE 1 : LOADING (pour Snowpipe et chargement)


CREATE WAREHOUSE IF NOT EXISTS nyc_loading_wh
WITH 
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60              -- 1 minute 
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    COMMENT = 'Warehouse pour Snowpipe et chargement données NYC Taxi';


-- WAREHOUSE 2 : TRANSFORMATION (pour Tasks et transformations)

CREATE WAREHOUSE IF NOT EXISTS nyc_transform_wh
WITH 
    WAREHOUSE_SIZE = 'SMALL'       -- Plus gros pour transformations
    AUTO_SUSPEND = 300             -- 5 minutes 
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2          -- Peut scale si besoin
    COMMENT = 'Warehouse pour transformations et Tasks NYC Taxi';


-- WAREHOUSE 3 : ANALYTICS (pour queries ad-hoc)


CREATE WAREHOUSE IF NOT EXISTS nyc_analytics_wh
WITH 
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 600             -- 10 minutes 
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3          -- Peut scale pour plusieurs analystes
    COMMENT = 'Warehouse pour analyses et queries ad-hoc NYC Taxi';

-- Vérifier
SHOW WAREHOUSES LIKE 'nyc_%';

-- ============================================================================
-- ESTIMATION COÛTS (avec tarif 2€/crédit)
-- ============================================================================
-- nyc_loading_wh    : 1 crédit/h × 2€ = 2€/h
-- nyc_transform_wh  : 2 crédits/h × 2€ = 4€/h
-- nyc_analytics_wh  : 1 crédit/h × 2€ = 2€/h
--
-- Avec auto-suspend agressif :
-- Coût mensuel estimé : 50-100€ (utilisation modérée)
-- ============================================================================

SELECT 
    'Warehouses created' as status,
    '3 warehouses: loading, transform, analytics' as details;