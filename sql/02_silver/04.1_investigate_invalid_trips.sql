-- Créer ce fichier pour investiguer car on a détecté plus de 84% des trajets invalides (is_valid_trip = FALSE) dans la table silver.
-- On va analyser les données brutes pour comprendre pourquoi ces trajets sont considérés comme invalid

USE DATABASE nyc_taxi_db;
USE SCHEMA bronze;

-- Combien ont pickup_datetime NULL ?
SELECT 
    'pickup_datetime NULL' as issue,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fhv_trips_raw), 2) as percentage
FROM fhv_trips_raw
WHERE pickup_datetime IS NULL

UNION ALL

-- Combien ont dropoff_datetime NULL ?
SELECT 
    'dropoff_datetime NULL',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fhv_trips_raw), 2)
FROM fhv_trips_raw
WHERE dropoff_datetime IS NULL

UNION ALL

-- Combien ont dropoff <= pickup ?
SELECT 
    'dropoff <= pickup',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fhv_trips_raw), 2)
FROM fhv_trips_raw
WHERE dropoff_datetime <= pickup_datetime

UNION ALL

-- Combien ont locations NULL ?
SELECT 
    'location NULL',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fhv_trips_raw), 2)
FROM fhv_trips_raw
WHERE PUlocationID IS NULL OR DOlocationID IS NULL;
