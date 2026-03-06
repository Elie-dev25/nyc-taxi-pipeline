-- ============================================================================
-- NYC TAXI PIPELINE - FILE FORMAT PARQUET
-- ============================================================================
-- Description : Configuration pour lire fichiers Parquet
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-02
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;

-- ============================================================================
-- FILE FORMAT : PARQUET
-- ============================================================================

CREATE OR REPLACE FILE FORMAT ff_parquet_nyc
  TYPE = 'PARQUET'
  COMPRESSION = 'AUTO'              -- Détecte compression automatiquement
  BINARY_AS_TEXT = FALSE            -- Garde les types binaires
  TRIM_SPACE = FALSE                -- Parquet gère déjà ça
  NULL_IF = ()                      -- Parquet gère les NULL nativement
  COMMENT = 'Parquet file format pour NYC Taxi data';

-- Vérifier
SHOW FILE FORMATS LIKE 'ff_parquet_nyc';
DESC FILE FORMAT ff_parquet_nyc;

-- Afficher 
SELECT 'File format created: ff_parquet_nyc' as status;