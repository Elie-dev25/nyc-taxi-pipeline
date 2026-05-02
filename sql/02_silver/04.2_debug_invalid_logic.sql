-- Ce fichier est pour investiguer les trajets qui ont des flags contradictoires car on des 
--flags de timestamps et locations invalides mais qui sont considérés comme des trajets valides 
--(is_valid_trip = TRUE) dans la table silver.C'est bizarre et on veut comprendre pourquoi.

USE DATABASE nyc_taxi_db;
USE SCHEMA silver;

-- Voir un trajet qui a cette combinaison bizarre
SELECT 
    -- Les flags
    has_valid_timestamps,
    has_valid_locations,
    is_valid_trip,
    
    -- Les données brutes pour comprendre
    pickup_datetime,
    dropoff_datetime,
    pickup_location_id,
    dropoff_location_id,
    
    -- Les calculs
    trip_duration_minutes
    
FROM fhv_trips_clean
WHERE has_valid_timestamps = FALSE
  AND has_valid_locations = FALSE
  AND is_valid_trip = TRUE
LIMIT 5;