# NYC Taxi Pipeline — Data Dictionary

**Projet :** NYC Taxi Real-Time Pipeline  
**Auteur :** Elie Njine  
**Dernière mise à jour :** 2026-05-02  
**Warehouse :** nyc_transform_wh  
**Database :** nyc_taxi_db  

---

## Architecture

Ce pipeline suit l'architecture **Medallion** (Bronze → Silver → Gold) :

- **Bronze** : Données brutes chargées depuis les fichiers sources TLC (NYC Taxi & Limousine Commission). Aucune transformation.
- **Silver** : Données nettoyées, typées, enrichies de flags qualité et de colonnes dérivées.
- **Gold** : Agrégations journalières prêtes pour l'analyse business.

### Schéma global
```
bronze.yellow_trips_raw  ──┐
bronze.green_trips_raw   ──┼──► silver.trips_clean ──► gold.daily_stats
bronze.fhv_trips_raw     ──┘
```

---

## Bronze Layer

### `bronze.yellow_trips_raw`
Données brutes des Yellow Taxis chargées depuis les fichiers TLC.

| Colonne | Type | Description |
|---|---|---|
| VENDORID | NUMBER | ID du fournisseur de technologie (1=Creative Mobile, 2=VeriFone) |
| TPEP_PICKUP_DATETIME | NUMBER | Timestamp Unix (µs) du début de course |
| TPEP_DROPOFF_DATETIME | NUMBER | Timestamp Unix (µs) de fin de course |
| PASSENGER_COUNT | NUMBER | Nombre de passagers |
| TRIP_DISTANCE | NUMBER | Distance en miles |
| RATECODEID | NUMBER | Code tarifaire (1=Standard, 2=JFK, etc.) |
| STORE_AND_FWD_FLAG | VARCHAR | Enregistrement différé (Y/N) |
| PULOCATIONID | NUMBER | Zone TLC de prise en charge |
| DOLOCATIONID | NUMBER | Zone TLC de dépose |
| PAYMENT_TYPE | NUMBER | Mode de paiement (1=CB, 2=Cash, etc.) |
| FARE_AMOUNT | NUMBER | Tarif de base |
| EXTRA | NUMBER | Suppléments |
| MTA_TAX | NUMBER | Taxe MTA |
| TIP_AMOUNT | NUMBER | Pourboire |
| TOLLS_AMOUNT | NUMBER | Péages |
| IMPROVEMENT_SURCHARGE | NUMBER | Surcharge amélioration |
| TOTAL_AMOUNT | NUMBER | Montant total |
| CONGESTION_SURCHARGE | NUMBER | Surcharge congestion |
| AIRPORT_FEE | NUMBER | Frais aéroport |
| CBD_CONGESTION_FEE | NUMBER | Frais congestion centre-ville |
| _LOADED_AT | TIMESTAMP_NTZ | Date/heure de chargement en Bronze |
| _SOURCE_FILE | VARCHAR | Nom du fichier source |
| _FILE_ROW_NUMBER | NUMBER | Numéro de ligne dans le fichier source |

### `bronze.green_trips_raw`
Données brutes des Green Taxis. Structure similaire à Yellow avec deux différences :
- `LPEP_PICKUP_DATETIME` / `LPEP_DROPOFF_DATETIME` au lieu de `TPEP_*`
- Colonnes supplémentaires : `TRIP_TYPE`, `EHAIL_FEE`

### `bronze.fhv_trips_raw`
Données brutes des FHV (For-Hire Vehicles : Uber, Lyft, Via, etc.).

| Colonne | Type | Description |
|---|---|---|
| DISPATCHING_BASE_NUM | VARCHAR | Numéro de base de dispatch |
| AFFILIATED_BASE_NUMBER | VARCHAR | Numéro de base affiliée |
| PICKUP_DATETIME | NUMBER | Timestamp Unix (µs) du début de course |
| DROPOFF_DATETIME | NUMBER | Timestamp Unix (µs) de fin de course |
| PULOCATIONID | NUMBER | Zone TLC de prise en charge (optionnel pour FHV) |
| DOLOCATIONID | NUMBER | Zone TLC de dépose (optionnel pour FHV) |
| SR_FLAG | NUMBER | Shared ride flag (1=oui, NULL=non) |
| _LOADED_AT | TIMESTAMP_NTZ | Date/heure de chargement en Bronze |
| _SOURCE_FILE | VARCHAR | Nom du fichier source |

---

## Silver Layer

### Logique commune aux 3 tables

#### Architecture en CTEs
Chaque script de transformation utilise **4 CTEs séquentiels** :

1. `converted` — conversion des types (VARCHAR/Unix → types natifs Snowflake)
2. `with_calculations` — colonnes dérivées (vitesse, pourboire %, coût/mile)
3. `with_flags` — flags qualité et détection d'anomalies
4. `final` — assemblage + `is_valid_trip` + métadonnées Silver

> **Pourquoi 4 CTEs ?** Snowflake ne permet pas de référencer un alias calculé dans le même `SELECT`. Les CTEs séquentiels permettent à chaque étape de référencer les colonnes de l'étape précédente.

#### Flags qualité

| Flag | Description |
|---|---|
| `has_valid_timestamps` | pickup et dropoff non NULL, dropoff > pickup |
| `has_valid_locations` | pickup_location_id et dropoff_location_id non NULL |
| `is_anomaly` | TRUE si durée < 1 min, > 24h, distance ≤ 0, tarif ≤ 0, ou vitesse > 65 mph |
| `anomaly_reason` | Texte explicatif de l'anomalie |
| `is_valid_trip` | Combinaison des flags (varie selon le type, voir ci-dessous) |

#### Définition de `is_valid_trip` par type

| Type | Formule |
|---|---|
| Yellow | `has_valid_timestamps AND has_valid_locations AND NOT is_anomaly` |
| Green | `has_valid_timestamps AND has_valid_locations AND NOT is_anomaly` |
| FHV | `has_valid_timestamps AND NOT is_anomaly` |

> **Pourquoi FHV diffère ?** Les FHV (Uber/Lyft) ne sont pas obligés de reporter les zone IDs de pickup/dropoff au TLC — ces champs sont optionnels pour eux. Exclure `has_valid_locations` de leur `is_valid_trip` évite de rejeter à tort 84% des trajets FHV valides.

#### Seuils d'anomalies

| Condition | Seuil | Raison |
|---|---|---|
| Durée minimale | 1 minute | En dessous = course annulée ou erreur |
| Durée maximale | 1440 minutes (24h) | Au-dessus = erreur de saisie |
| Distance | > 0 miles | Distance nulle ou négative impossible |
| Tarif (Yellow/Green) | > 0 $ | Tarif nul ou négatif = données corrompues |
| Vitesse moyenne | ≤ 65 mph | Limite légale autoroute NYC — au-delà = erreur |

---

### `silver.yellow_trips_clean`

| Colonne | Type | Description |
|---|---|---|
| vendor_id | NUMBER | ID fournisseur (depuis VENDORID Bronze) |
| pickup_datetime | TIMESTAMP_NTZ | Timestamp converti depuis Unix µs |
| dropoff_datetime | TIMESTAMP_NTZ | Timestamp converti depuis Unix µs |
| passenger_count | NUMBER | Nombre de passagers |
| trip_distance | NUMBER(10,2) | Distance en miles |
| ratecode_id | NUMBER | Code tarifaire (depuis RATECODEID Bronze) |
| store_and_fwd_flag | VARCHAR | Enregistrement différé |
| pickup_location_id | NUMBER | Zone TLC pickup |
| dropoff_location_id | NUMBER | Zone TLC dropoff |
| payment_type | NUMBER | Mode de paiement |
| fare_amount | NUMBER(10,2) | Tarif de base |
| extra | NUMBER(10,2) | Suppléments |
| mta_tax | NUMBER(10,2) | Taxe MTA |
| tip_amount | NUMBER(10,2) | Pourboire |
| tolls_amount | NUMBER(10,2) | Péages |
| improvement_surcharge | NUMBER(10,2) | Surcharge amélioration |
| total_amount | NUMBER(10,2) | Montant total |
| congestion_surcharge | NUMBER(10,2) | Surcharge congestion |
| airport_fee | NUMBER(10,2) | Frais aéroport |
| cbd_congestion_fee | NUMBER(10,2) | Frais congestion centre-ville |
| trip_duration_minutes | NUMBER(10,2) | Durée calculée en minutes |
| trip_duration_hours | NUMBER(10,2) | Durée calculée en heures |
| avg_speed_mph | NUMBER(10,2) | Vitesse moyenne = distance / durée_heures |
| tip_percentage | NUMBER(10,2) | Pourboire % = (tip / fare) × 100 |
| cost_per_mile | NUMBER(10,2) | Coût par mile = total / distance |
| trip_distance_category | VARCHAR | Short (<1mi), Medium (1-5mi), Long (>5mi) |
| fare_category | VARCHAR | Low (<$10), Medium ($10-30), High (>$30) |
| pickup_hour | NUMBER | Heure de prise en charge (0-23) |
| pickup_day_of_week | VARCHAR | Jour de la semaine (Mon, Tue, etc.) |
| pickup_date | DATE | Date de prise en charge |
| pickup_month | NUMBER | Mois (1-12) |
| pickup_year | NUMBER | Année |
| is_weekend | BOOLEAN | TRUE si Samedi ou Dimanche |
| is_rush_hour | BOOLEAN | TRUE si 7h-9h ou 17h-19h, lundi-vendredi |
| is_valid_trip | BOOLEAN | Voir formule ci-dessus |
| is_anomaly | BOOLEAN | TRUE si anomalie détectée |
| anomaly_reason | VARCHAR | Description de l'anomalie |
| _source_file | VARCHAR | Fichier source Bronze |
| _bronze_loaded_at | TIMESTAMP_NTZ | Date chargement Bronze |
| _silver_loaded_at | TIMESTAMP_NTZ | Date chargement Silver |

### `silver.green_trips_clean`
Structure identique à `yellow_trips_clean` avec deux colonnes supplémentaires :

| Colonne | Type | Description |
|---|---|---|
| trip_type | NUMBER | Type de course (1=Street-hail, 2=Dispatch) |
| ehail_fee | NUMBER(10,2) | Frais e-hail (spécifique Green) |

### `silver.fhv_trips_clean`

| Colonne | Type | Description |
|---|---|---|
| dispatching_base_num | VARCHAR | Numéro de base de dispatch |
| affiliated_base_number | VARCHAR | Numéro de base affiliée |
| pickup_datetime | TIMESTAMP_NTZ | Timestamp converti depuis Unix µs |
| dropoff_datetime | TIMESTAMP_NTZ | Timestamp converti depuis Unix µs |
| pickup_location_id | NUMBER | Zone TLC pickup (optionnel, souvent NULL) |
| dropoff_location_id | NUMBER | Zone TLC dropoff (optionnel, souvent NULL) |
| shared_ride_flag | BOOLEAN | TRUE si course partagée |
| trip_duration_minutes | NUMBER(10,2) | Durée calculée en minutes |
| trip_duration_hours | NUMBER(10,2) | Durée calculée en heures |
| pickup_hour | NUMBER | Heure de prise en charge |
| pickup_day_of_week | VARCHAR | Jour de la semaine |
| pickup_date | DATE | Date de prise en charge |
| pickup_month | NUMBER | Mois |
| pickup_year | NUMBER | Année |
| is_valid_trip | BOOLEAN | `has_valid_timestamps AND NOT is_anomaly` |
| is_anomaly | BOOLEAN | TRUE si anomalie détectée |
| anomaly_reason | VARCHAR | Description de l'anomalie |
| _source_file | VARCHAR | Fichier source Bronze |
| _bronze_loaded_at | TIMESTAMP_NTZ | Date chargement Bronze |
| _silver_loaded_at | TIMESTAMP_NTZ | Date chargement Silver |

---

## Gold Layer

### `gold.daily_revenue_stats`
Revenus journaliers agrégés par type de taxi.

> **Note :** FHV exclu car les données publiques TLC ne contiennent pas d'informations tarifaires pour les FHV (Uber/Lyft gèrent leur propre tarification).

| Colonne | Type | Description |
|---|---|---|
| report_date | DATE | Date du rapport |
| taxi_type | VARCHAR | Type de taxi (Yellow, Green) |
| total_trips | NUMBER | Nombre de trajets valides |
| total_revenue | NUMBER(12,2) | Somme des total_amount |
| avg_fare | NUMBER(10,2) | Tarif moyen |
| avg_tip_pct | NUMBER(5,2) | Pourboire moyen en % |
| avg_trip_distance | NUMBER(10,2) | Distance moyenne en miles |
| avg_duration_minutes | NUMBER(10,2) | Durée moyenne en minutes |
| _gold_loaded_at | TIMESTAMP_NTZ | Date de chargement Gold |

### `gold.daily_passenger_stats`
Statistiques passagers journalières par type de taxi.

| Colonne | Type | Description |
|---|---|---|
| report_date | DATE | Date du rapport |
| taxi_type | VARCHAR | Type de taxi (Yellow, Green, FHV) |
| total_trips | NUMBER | Nombre de trajets valides |
| total_passengers | NUMBER | Somme des passagers (NULL pour FHV) |
| avg_passengers_per_trip | NUMBER(5,2) | Moyenne passagers/trajet (NULL pour FHV) |
| _gold_loaded_at | TIMESTAMP_NTZ | Date de chargement Gold |

> **Note FHV :** `total_passengers` et `avg_passengers_per_trip` sont NULL pour FHV car cette donnée n'est pas collectée dans les fichiers publics TLC.

### `gold.daily_fleet_stats`
Activité de la flotte journalière par type de taxi.

| Colonne | Type | Description |
|---|---|---|
| report_date | DATE | Date du rapport |
| taxi_type | VARCHAR | Type de taxi (Yellow, Green, FHV) |
| active_vehicles | NUMBER | Véhicules actifs (NULL pour Yellow/Green) |
| total_trips | NUMBER | Nombre total de trajets |
| avg_trips_per_vehicle | NUMBER(10,2) | Moyenne trajets/véhicule (NULL pour Yellow/Green) |
| _gold_loaded_at | TIMESTAMP_NTZ | Date de chargement Gold |

> **Note Yellow/Green :** `active_vehicles` est NULL car les données publiques TLC n'exposent pas d'identifiant unique par véhicule pour ces types. Seul `vendor_id` est disponible, qui représente le fournisseur de technologie (2-3 entreprises seulement) et non les véhicules individuels.

---

## Monitoring

Scripts de surveillance dans `sql/04_monitoring/` :

| Fichier | Check | Seuil d'alerte |
|---|---|---|
| `01_check_freshness.sql` | Fraîcheur des données | > 2 jours sans nouvelles données |
| `02_check_volume.sql` | Volume des tables | Table vide |
| `03_check_quality.sql` | Taux de validité Silver | < 85% de trajets valides |
| `04_check_metric_drift.sql` | Dérive du tarif moyen Gold | > 50% de variation jour/jour (min. 100 trajets) |
| `05_check_bronze_silver_consistency.sql` | Cohérence Bronze→Silver | > 20% de perte de lignes |

---

## Statistiques globales du pipeline

| Table | Lignes | Taux de validité |
|---|---|---|
| silver.yellow_trips_clean | 18,148,478 | 92.80% |
| silver.green_trips_clean | 146,486 | 92.62% |
| silver.fhv_trips_clean | 5,659,822 | 99.52% |
| **Total Silver** | **~24M** | |
| gold.daily_revenue_stats | 187 | — |
| gold.daily_passenger_stats | 277 | — |
| gold.daily_fleet_stats | 277 | — |