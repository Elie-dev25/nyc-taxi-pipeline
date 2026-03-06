# NYC Taxi Pipeline - Data Dictionary

**Projet :** NYC Taxi Real-Time Pipeline  
**Auteur :** Elie  
**Date :** 2026-03-06  
**Dernière mise à jour :** 2026-03-06  

---

## Table des matières

- [FHV (For-Hire Vehicles)](#fhv-for-hire-vehicles)
- [Yellow Taxi](#yellow-taxi)
- [Green Taxi](#green-taxi)
- [Codes de référence](#codes-de-référence)

---

## FHV (For-Hire Vehicles)

**Source :** NYC TLC FHV Trip Records  
**Format :** Parquet  
**Fréquence :** Mensuelle  
**Volume estimé :** ~500K-1M lignes/mois  

### Colonnes (7 total)

| Nom de colonne            | Type Parquet | Type Snowflake | Nullable | Description |
|---------------------------|--------------|----------------|----------|-------------|
| `dispatching_base_num`    | STRING       | TEXT           | ✅       | Code de la compagnie de dispatch (ex: B02512 = Uber) |
| `pickup_datetime`         | INT64        | NUMBER(38,0)   | ✅       | Date/heure début trajet (Unix timestamp microsecondes) |
| `dropOff_datetime`        | INT64        | NUMBER(38,0)   | ✅       | Date/heure fin trajet (Unix timestamp microsecondes) |
| `PUlocationID`            | INT32        | NUMBER(38,0)   | ✅       | Zone de pickup (ID géographique NYC) |
| `DOlocationID`            | INT32        | NUMBER(38,0)   | ✅       | Zone de dropoff (ID géographique NYC) |
| `SR_Flag`                 | INT32        | NUMBER(38,0)   | ✅       | Shared Ride flag (NULL ou 1) |
| `Affiliated_base_number`  | STRING       | TEXT           | ✅       | Numéro de base affiliée |

### Notes importantes

⚠️ **Pas de données de prix/paiement pour FHV** (réglementation NYC)  
⚠️ **Dates en Unix timestamp** → Nécessite conversion avec `TO_TIMESTAMP_NTZ(col / 1000000)`  

---

## Yellow Taxi

**Source :** NYC TLC Yellow Taxi Trip Records  
**Format :** Parquet  
**Fréquence :** Mensuelle  
**Volume estimé :** ~2M-3M lignes/mois  

### Colonnes (20 total)

| Nom de colonne            | Type Parquet | Type Snowflake | Nullable | Description |
|---------------------------|--------------|----------------|----------|-------------|
| `VendorID`                | INT32        | NUMBER(38,0)   | ✅       | Fournisseur (1=Creative Mobile, 2=VeriFone) |
| `tpep_pickup_datetime`    | INT64        | NUMBER(38,0)   | ✅       | Date/heure début (Unix timestamp microsecondes) |
| `tpep_dropoff_datetime`   | INT64        | NUMBER(38,0)   | ✅       | Date/heure fin (Unix timestamp microsecondes) |
| `passenger_count`         | INT32        | NUMBER(38,0)   | ✅       | Nombre de passagers |
| `trip_distance`           | DOUBLE       | REAL           | ✅       | Distance trajet (miles) |
| `RatecodeID`              | INT32        | NUMBER(38,0)   | ✅       | Code tarif (voir [Codes](#rate-codes)) |
| `store_and_fwd_flag`      | STRING       | TEXT           | ✅       | Y=Stocké puis envoyé, N=Normal |
| `PULocationID`            | INT32        | NUMBER(38,0)   | ✅       | Zone pickup |
| `DOLocationID`            | INT32        | NUMBER(38,0)   | ✅       | Zone dropoff |
| `payment_type`            | INT32        | NUMBER(38,0)   | ✅       | Type paiement (voir [Codes](#payment-types)) |
| `fare_amount`             | DOUBLE       | REAL           | ✅       | Tarif de base ($) |
| `extra`                   | DOUBLE       | REAL           | ✅       | Suppléments ($) |
| `mta_tax`                 | DOUBLE       | REAL           | ✅       | Taxe MTA ($0.50) |
| `tip_amount`              | DOUBLE       | REAL           | ✅       | Pourboire ($) |
| `tolls_amount`            | DOUBLE       | REAL           | ✅       | Péages ($) |
| `improvement_surcharge`   | DOUBLE       | REAL           | ✅       | Surtaxe amélioration ($0.30) |
| `total_amount`            | DOUBLE       | REAL           | ✅       | Montant total payé ($) |
| `congestion_surcharge`    | DOUBLE       | REAL           | ✅       | Surtaxe congestion Manhattan ($2.50) |
| `Airport_fee`             | DOUBLE       | REAL           | ✅       | Frais aéroport JFK/LaGuardia ($1.75) |
| `cbd_congestion_fee`      | DOUBLE       | REAL           | ✅       | Frais congestion CBD (nouveau 2025) |

### Notes importantes

💰 **Calcul total :**  
```
total_amount = fare_amount + extra + mta_tax + tip_amount + tolls_amount 
               + improvement_surcharge + congestion_surcharge + Airport_fee 
               + cbd_congestion_fee
```

⚠️ **Dates en Unix timestamp** → Conversion nécessaire  

---

## Green Taxi

**Source :** NYC TLC Green Taxi Trip Records  
**Format :** Parquet  
**Fréquence :** Mensuelle  
**Volume estimé :** ~300K-500K lignes/mois  

### Colonnes (21 total)

| Nom de colonne            | Type Parquet | Type Snowflake | Nullable | Description |
|---------------------------|--------------|----------------|----------|-------------|
| `VendorID`                | INT32        | NUMBER(38,0)   | ✅       | Fournisseur (1=Creative Mobile, 2=VeriFone) |
| `lpep_pickup_datetime`    | INT64        | NUMBER(38,0)   | ✅       | Date/heure début (Unix timestamp microsecondes) |
| `lpep_dropoff_datetime`   | INT64        | NUMBER(38,0)   | ✅       | Date/heure fin (Unix timestamp microsecondes) |
| `store_and_fwd_flag`      | STRING       | TEXT           | ✅       | Y=Stocké puis envoyé, N=Normal |
| `RatecodeID`              | INT32        | NUMBER(38,0)   | ✅       | Code tarif |
| `PULocationID`            | INT32        | NUMBER(38,0)   | ✅       | Zone pickup |
| `DOLocationID`            | INT32        | NUMBER(38,0)   | ✅       | Zone dropoff |
| `passenger_count`         | INT32        | NUMBER(38,0)   | ✅       | Nombre de passagers |
| `trip_distance`           | DOUBLE       | REAL           | ✅       | Distance (miles) |
| `fare_amount`             | DOUBLE       | REAL           | ✅       | Tarif de base ($) |
| `extra`                   | DOUBLE       | REAL           | ✅       | Suppléments ($) |
| `mta_tax`                 | DOUBLE       | REAL           | ✅       | Taxe MTA ($) |
| `tip_amount`              | DOUBLE       | REAL           | ✅       | Pourboire ($) |
| `tolls_amount`            | DOUBLE       | REAL           | ✅       | Péages ($) |
| `ehail_fee`               | DOUBLE       | REAL           | ✅       | Frais e-hail (application) |
| `improvement_surcharge`   | DOUBLE       | REAL           | ✅       | Surtaxe amélioration ($) |
| `total_amount`            | DOUBLE       | REAL           | ✅       | Montant total ($) |
| `payment_type`            | INT32        | NUMBER(38,0)   | ✅       | Type paiement |
| `trip_type`               | INT32        | NUMBER(38,0)   | ✅       | Type trajet (1=Street-hail, 2=Dispatch) |
| `congestion_surcharge`    | DOUBLE       | REAL           | ✅       | Surtaxe congestion ($) |
| `cbd_congestion_fee`      | DOUBLE       | REAL           | ✅       | Frais congestion CBD |

### Différences avec Yellow Taxi

- ✅ Colonne `ehail_fee` (spécifique Green)
- ✅ Colonne `trip_type` (spécifique Green)
- ✅ Préfixe `lpep_` au lieu de `tpep_` pour les dates
- ⚠️ Pas de colonne `Airport_fee` (Green ne dessert pas directement aéroports)

---

## Codes de référence

### Rate Codes

| RatecodeID | Description |
|------------|-------------|
| 1 | Standard rate |
| 2 | JFK |
| 3 | Newark |
| 4 | Nassau or Westchester |
| 5 | Negotiated fare |
| 6 | Group ride |

### Payment Types

| payment_type | Description |
|--------------|-------------|
| 1 | Credit card |
| 2 | Cash |
| 3 | No charge |
| 4 | Dispute |
| 5 | Unknown |
| 6 | Voided trip |

### Vendor IDs

| VendorID | Nom |
|----------|-----|
| 1 | Creative Mobile Technologies, LLC |
| 2 | VeriFone Inc. |

---

## Anomalies connues à surveiller

### Données invalides fréquentes

⚠️ **Coordonnées GPS**
- Pickup/Dropoff hors limites NYC (lat/long invalides)
- Solution : Filtrer avec bounding box NYC

⚠️ **Distances**
- Distances négatives ou nulles
- Distances > 100 miles (probablement erreur)
- Solution : Filtrer `trip_distance BETWEEN 0.1 AND 100`

⚠️ **Tarifs**
- `total_amount` < 0 (remboursements/erreurs)
- `fare_amount` < 2.50 (minimum légal NYC)
- Solution : Filtrer valeurs aberrantes

⚠️ **Durées**
- Trajets < 60 secondes (probablement annulés)
- Trajets > 24 heures (erreur de système)
- Solution : Calculer durée et filtrer

⚠️ **Passagers**
- `passenger_count` = 0 ou NULL (fréquent)
- `passenger_count` > 6 (capacité max taxi)
- Solution : Remplacer NULL par 1, filtrer > 6

---

## Sources

- [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
- [Data Dictionary NYC TLC](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf)

---

**Dernière révision :** 2026-03-06  
**Version :** 1.0