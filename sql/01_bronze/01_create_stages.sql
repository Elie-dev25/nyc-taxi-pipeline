-- ============================================================================
-- NYC TAXI PIPELINE - STAGES (External Stages)
-- ============================================================================
-- Description : Stages pour accéder aux fichiers Parquet dans S3
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-05
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_loading_wh;


-- STAGE 1 : FHV (For-Hire Vehicles)

CREATE OR REPLACE STAGE stage_fhv
  STORAGE_INTEGRATION = s3_int_nyc
  URL = 's3://elie-nyc-taxi-pipeline/landing/fhv/'
  FILE_FORMAT = ff_parquet_nyc
  COMMENT = 'Stage pour fichiers FHV (Uber, Lyft, Via, etc.)';

-- Vérifier
SHOW STAGES LIKE 'stage_fhv';

-- STAGE 2 : YELLOW TAXI

CREATE OR REPLACE STAGE stage_yellow
  STORAGE_INTEGRATION = s3_int_nyc
  URL = 's3://elie-nyc-taxi-pipeline/landing/yellow/'
  FILE_FORMAT = ff_parquet_nyc
  COMMENT = 'Stage pour fichiers Yellow Taxi';

SHOW STAGES LIKE 'stage_yellow';


-- STAGE 3 : GREEN TAXI


CREATE OR REPLACE STAGE stage_green
  STORAGE_INTEGRATION = s3_int_nyc
  URL = 's3://elie-nyc-taxi-pipeline/landing/green/'
  FILE_FORMAT = ff_parquet_nyc
  COMMENT = 'Stage pour fichiers Green Taxi';

SHOW STAGES LIKE 'stage_green';


-- VÉRIFICATION : Lister les fichiers dans chaque stage


-- -- FHV
-- SELECT 'FHV Files:' as stage_name;
-- LIST @stage_fhv;

-- -- Yellow
-- SELECT 'Yellow Taxi Files:' as stage_name;
-- LIST @stage_yellow;

-- -- Green
-- SELECT 'Green Taxi Files:' as stage_name;
-- LIST @stage_green;






-- ============================================================================
-- NOTES
-- ============================================================================
-- Ces stages pointent vers les fichiers Parquet dans S3
-- Ils utilisent la Storage Integration s3_int_nyc pour l'authentification
-- Le File Format ff_parquet_nyc définit comment lire les Parquet
-- ============================================================================