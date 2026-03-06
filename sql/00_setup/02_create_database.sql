-- ============================================================================
-- NYC TAXI PIPELINE - DATABASE SETUP
-- ============================================================================
-- Description : Création database et schemas (architecture Medallion)
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-02
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- DATABASE
-- ============================================================================

CREATE DATABASE IF NOT EXISTS nyc_taxi_db
  COMMENT = 'NYC Taxi Real-Time Pipeline - Isolated project';

-- Vérifier
SHOW DATABASES LIKE 'nyc_taxi_db';

-- ============================================================================
-- SCHEMAS (Medallion Architecture)
-- ============================================================================

USE DATABASE nyc_taxi_db;

-- Bronze Layer : Données brutes (Raw)
CREATE SCHEMA IF NOT EXISTS bronze
  COMMENT = 'Raw data from S3 - No transformations';

-- Silver Layer : Données nettoyées (Clean)
CREATE SCHEMA IF NOT EXISTS silver
  COMMENT = 'Cleaned and validated data';

-- Gold Layer : Données business (KPIs, Aggregates)
CREATE SCHEMA IF NOT EXISTS gold
  COMMENT = 'Business-ready data - KPIs and aggregates';

-- Monitoring : Santé du pipeline
CREATE SCHEMA IF NOT EXISTS monitoring
  COMMENT = 'Pipeline monitoring and data quality checks';

-- Vérifier
SHOW SCHEMAS IN DATABASE nyc_taxi_db;

-- ============================================================================
-- DOCUMENTATION
-- ============================================================================
-- Bronze : Snowpipe charge ici (raw parquet data)
-- Silver : Tasks nettoient et valident
-- Gold   : Tasks créent KPIs et agrégations
-- Monitoring : Vues pour surveiller le pipeline
-- ============================================================================

SELECT 
    'Database created: nyc_taxi_db' as status,
    '4 schemas created: bronze, silver, gold, monitoring' as details;