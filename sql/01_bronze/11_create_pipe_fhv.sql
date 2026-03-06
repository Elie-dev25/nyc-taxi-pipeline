-- ============================================================================
-- NYC TAXI PIPELINE - SNOWPIPE FHV (AUTO-INGEST)
-- ============================================================================
-- Description : Pipe pour chargement automatique FHV en temps réel
-- Projet     : NYC Taxi Real-Time Pipeline
-- Auteur     : Elie
-- Date       : 2026-03-06
-- ============================================================================

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;
USE WAREHOUSE nyc_loading_wh;

-- ============================================================================
-- SNOWPIPE : FHV_PIPE
-- ============================================================================

CREATE OR REPLACE PIPE pipe_fhv
  AUTO_INGEST = TRUE
  COMMENT = 'Auto-ingest pipe pour FHV trips - Chargement temps réel'
AS
COPY INTO fhv_trips_raw (
    dispatching_base_num,
    pickup_datetime,
    dropoff_datetime,
    PUlocationID,
    DOlocationID,
    SR_Flag,
    Affiliated_base_number,
    _source_file,
    _file_row_number
)
FROM (
    SELECT 
        $1:dispatching_base_num::VARCHAR(50),
        $1:pickup_datetime::NUMBER(38,0),
        $1:dropOff_datetime::NUMBER(38,0),
        $1:PUlocationID::NUMBER(38,0),
        $1:DOlocationID::NUMBER(38,0),
        $1:SR_Flag::NUMBER(38,0),
        $1:Affiliated_base_number::VARCHAR(50),
        metadata$filename,
        metadata$file_row_number
    FROM @stage_fhv
)
FILE_FORMAT = ff_parquet_nyc;

-- ============================================================================
-- RÉCUPÉRER L'ARN DE LA SQS QUEUE (IMPORTANT POUR AWS)
-- ============================================================================

-- DESC PIPE pipe_fhv;

-- ============================================================================
-- RÉSULTAT ATTENDU :
-- ============================================================================
-- notification_channel : arn:aws:sqs:eu-west-3:123456789:sf-snowpipe-...
-- 
-- ⚠️ COPIER CETTE VALEUR pour configurer S3 Event Notifications dans AWS
-- ============================================================================

-- SHOW PIPES LIKE 'pipe_fhv';

-- ============================================================================
-- NOTES
-- ============================================================================
-- AUTO_INGEST = TRUE : Active le mode automatique
-- Snowflake crée automatiquement une SQS Queue
-- S3 enverra des notifications à cette queue
-- Snowpipe surveille la queue en continu
-- 
-- Coût : ~0.06 crédits par 1000 fichiers chargés
-- ============================================================================

SELECT 'Pipe pipe_fhv created - Copy notification_channel ARN for AWS' as status;