-- ============================================================================
-- NYC TAXI PIPELINE - CRÉATION TABLES GOLD LAYER
-- ============================================================================
USE DATABASE nyc_taxi_db;
USE SCHEMA gold;
USE WAREHOUSE nyc_transform_wh;

-- ============================================================================
-- TABLE 1 : DAILY REVENUE STATS
-- Note : FHV exclu car pas de données de tarification disponibles
-- ============================================================================
CREATE OR REPLACE TABLE daily_revenue_stats (
    report_date            DATE,
    taxi_type              VARCHAR(10),
    total_trips            NUMBER(10,0),
    total_revenue          NUMBER(12,2),
    avg_fare               NUMBER(10,2),
    avg_tip_pct            NUMBER(5,2),
    avg_trip_distance      NUMBER(10,2),
    avg_duration_minutes   NUMBER(10,2),
    _gold_loaded_at        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Revenus journaliers par type de taxi - FHV exclu (pas de données tarifaires)';

-- ============================================================================
-- TABLE 2 : DAILY PASSENGER STATS
-- ============================================================================
CREATE OR REPLACE TABLE daily_passenger_stats (
    report_date            DATE,
    taxi_type              VARCHAR(10),
    total_trips            NUMBER(10,0),
    total_passengers       NUMBER(10,0),
    avg_passengers_per_trip NUMBER(5,2),
    _gold_loaded_at        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Statistiques passagers journalières par type de taxi';

-- ============================================================================
-- TABLE 3 : DAILY FLEET STATS
-- ============================================================================
CREATE OR REPLACE TABLE daily_fleet_stats (
    report_date            DATE,
    taxi_type              VARCHAR(10),
    active_vehicles        NUMBER(10,0),
    total_trips            NUMBER(10,0),
    avg_trips_per_vehicle  NUMBER(10,2),
    _gold_loaded_at        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Activité de la flotte journalière par type de taxi';

-- Vérifications
SELECT 'daily_revenue_stats created'   AS status;
SELECT 'daily_passenger_stats created' AS status;
SELECT 'daily_fleet_stats created'     AS status;