-- ============================================================================
-- NYC TAXI PIPELINE - STORAGE INTEGRATION
-- ============================================================================
-- Description : Connexion sécurisée AWS S3 ↔ Snowflake (dédiée NYC Taxi)
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2024-03-02
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Créer Storage Integration dédiée à ce projet
CREATE OR REPLACE STORAGE INTEGRATION s3_int_nyc
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::599073790652:role/snowflake-access-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://elie-nyc-taxi-pipeline/')
  COMMENT = 'Storage Integration pour NYC Taxi Pipeline - Projet isolé';

-- Vérifier la création
DESC STORAGE INTEGRATION s3_int_nyc;
