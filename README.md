Voici le README complet :
markdown# NYC Taxi Data Pipeline

Pipeline de données end-to-end construit sur les données publiques des taxis
de New York City (TLC), utilisant une architecture Medallion sur Snowflake
avec ingestion automatique via AWS.

---

## Objectif

Construire un pipeline de données complet qui transforme des données brutes
de trajets de taxi en métriques analytiques exploitables, tout en appliquant
les bonnes pratiques de data engineering : qualité des données, traçabilité,
monitoring et documentation.

---

## Source des données

**NYC Taxi & Limousine Commission (TLC)**  
Données publiques disponibles sur : https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

3 types de véhicules couverts :
- **Yellow Taxi** — taxis traditionnels, opèrent dans tout NYC
- **Green Taxi** — taxis de borough, opèrent hors Manhattan principalement
- **FHV** (For-Hire Vehicles) — plateformes comme Uber, Lyft, Via

Volume traité : **~24 millions de trajets**  
Format source : **Parquet**

---

## Architecture complète
Fichiers TLC (Parquet)
│
▼
┌───────────────────────┐
│     AWS S3 Bucket     │  elie-nyc-taxi-pipeline
│  landing/yellow/      │  Stockage des fichiers sources
│  landing/green/       │
│  landing/fhv/         │
└──────────┬────────────┘
│ S3 Event Notification
▼
┌───────────────────────┐
│     AWS SQS Queue     │  Détection automatique
│                       │  des nouveaux fichiers
└──────────┬────────────┘
│ Snowpipe (< 1 min latence)
▼
┌───────────────────────┐
│    BRONZE LAYER       │  Données brutes, aucune transformation
│  yellow_trips_raw     │  pipe_yellow / pipe_green / pipe_fhv
│  green_trips_raw      │
│  fhv_trips_raw        │
└──────────┬────────────┘
│ SnowSQL CLI (scripts SQL)
▼
┌───────────────────────┐
│    SILVER LAYER       │  Nettoyage, typage, validation
│  yellow_trips_clean   │  4 CTEs séquentiels par table
│  green_trips_clean    │
│  fhv_trips_clean      │
└──────────┬────────────┘
│
▼
┌───────────────────────┐
│     GOLD LAYER        │  Agrégations journalières
│  daily_revenue_stats  │
│  daily_passenger_stats│
│  daily_fleet_stats    │
└───────────────────────┘

---

## Ce qu'on a construit

### Ingestion automatique (AWS)
Les fichiers Parquet sont déposés dans un bucket S3 organisé par type de taxi.
Dès l'arrivée d'un fichier, une notification S3 déclenche une SQS Queue qui
active Snowpipe — le fichier est chargé automatiquement en Bronze en moins
d'une minute, sans intervention manuelle.

| Pipe | Table cible | Préfixe S3 |
|---|---|---|
| pipe_yellow | yellow_trips_raw | landing/yellow/ |
| pipe_green | green_trips_raw | landing/green/ |
| pipe_fhv | fhv_trips_raw | landing/fhv/ |

### Bronze Layer
Données brutes conservées telles quelles dans Snowflake.
Aucune transformation — garantit la traçabilité complète et permet de
rejouer les transformations Silver à tout moment.

### Silver Layer
Transformation en 4 CTEs séquentiels par table :

1. **`converted`** — conversion des types (timestamps Unix µs → TIMESTAMP_NTZ, cast des montants)
2. **`with_calculations`** — colonnes dérivées (durée, vitesse moyenne, pourboire %, coût/mile, catégories)
3. **`with_flags`** — flags qualité et détection d'anomalies
4. **`final`** — assemblage + `is_valid_trip` + métadonnées Silver

#### Règles de qualité appliquées

| Règle | Seuil | Raison |
|---|---|---|
| Durée minimale | 1 minute | Course annulée ou erreur système |
| Durée maximale | 24 heures | Erreur de saisie |
| Vitesse maximale | 65 mph | Limite légale autoroute NYC |
| Tarif (Yellow/Green) | > 0 $ | Tarif nul = données corrompues |
| Distance (Yellow/Green) | > 0 miles | Distance nulle impossible |

#### Traitement spécifique FHV
Les FHV (Uber/Lyft) ne sont pas obligés de reporter les zone IDs au TLC —
ces champs sont optionnels. La définition de `is_valid_trip` diffère donc :

| Type | Formule `is_valid_trip` |
|---|---|
| Yellow / Green | `has_valid_timestamps AND has_valid_locations AND NOT is_anomaly` |
| FHV | `has_valid_timestamps AND NOT is_anomaly` |

#### Limitations connues des données
- **FHV** : pas de données tarifaires disponibles publiquement
- **FHV** : `passenger_count` non collecté
- **Yellow / Green** : pas d'identifiant unique par véhicule — seul `vendor_id` est disponible, représentant le fournisseur de technologie (2-3 entreprises), pas les véhicules individuels

### Gold Layer
3 tables d'agrégation journalière par type de taxi :

| Table | Description | Types couverts |
|---|---|---|
| `daily_revenue_stats` | Revenus, tarifs, distances | Yellow, Green |
| `daily_passenger_stats` | Passagers et trajets | Yellow, Green, FHV |
| `daily_fleet_stats` | Véhicules actifs et trajets | Yellow, Green, FHV* |

*`active_vehicles` disponible uniquement pour FHV via `dispatching_base_num`

### Monitoring
5 checks de santé indépendants dans `sql/04_monitoring/` :

| Fichier | Check | Seuil d'alerte |
|---|---|---|
| `01_check_freshness.sql` | Fraîcheur des données | > 2 jours sans nouvelles données |
| `02_check_volume.sql` | Volume des tables | Table vide |
| `03_check_quality.sql` | Taux de validité Silver | < 85% de trajets valides |
| `04_check_metric_drift.sql` | Dérive du tarif moyen | > 50% de variation jour/jour (min. 100 trajets) |
| `05_check_bronze_silver_consistency.sql` | Cohérence Bronze→Silver | > 20% de perte de lignes |

---

## Résultats

| Table | Lignes | Taux de validité |
|---|---|---|
| silver.yellow_trips_clean | 18,148,478 | 92.80% |
| silver.green_trips_clean | 146,486 | 92.62% |
| silver.fhv_trips_clean | 5,659,822 | 99.52% |
| **Total Silver** | **~24M** | |

Exemple de métriques Gold (31 mars 2025) :

| Type | Trajets | Revenus | Tarif moyen | Passagers |
|---|---|---|---|---|
| Yellow | 105,753 | $3,098,422 | $20.00 | 110,194 |
| Green | 1,566 | $36,443 | $16.83 | 1,891 |
| FHV | 70,911 | — | — | — |

---

## Stack technique

| Outil | Usage |
|---|---|
| AWS S3 | Stockage des fichiers sources Parquet |
| AWS SQS | Queue de notifications pour Snowpipe |
| Snowpipe | Chargement automatique S3 → Bronze (< 1 min de latence) |
| Snowflake | Data warehouse (Bronze, Silver, Gold) |
| SnowSQL CLI | Exécution des scripts de transformation |
| SQL | Transformations, monitoring, agrégations |
| Architecture Medallion | Organisation des couches de données |

---

## Structure du projet
nyc-taxi-pipeline/
├── docs/
│   ├── data_dictionary.md     # Dictionnaire de données complet
│   └── snowpipe_setup.md      # Guide de configuration Snowpipe + AWS
├── sql/
│   ├── 00_setup/              # Création database, schemas, warehouses
│   ├── 01_bronze/             # Chargement et monitoring Bronze
│   ├── 02_silver/             # Transformations Silver
│   │   ├── 01_create_table_fhv_clean.sql
│   │   ├── 02_create_table_yellow_clean.sql
│   │   ├── 03_create_table_green_clean.sql
│   │   ├── 04_transform_fhv.sql
│   │   ├── 05_transform_yellow.sql
│   │   └── 06_transform_green.sql
│   ├── 03_gold/               # Agrégations Gold
│   │   ├── 01_create_tables_gold.sql
│   │   └── 02_transform_gold.sql
│   └── 04_monitoring/         # Scripts de surveillance
│       ├── 01_check_freshness.sql
│       ├── 02_check_volume.sql
│       ├── 03_check_quality.sql
│       ├── 04_check_metric_drift.sql
│       └── 05_check_bronze_silver_consistency.sql
└── scripts/
└── watch_snowpipe.sh      # Script de surveillance Snowpipe

---

## Documentation

- [`docs/data_dictionary.md`](docs/data_dictionary.md) — description complète de toutes les tables et colonnes, décisions de design, seuils de qualité
- [`docs/snowpipe_setup.md`](docs/snowpipe_setup.md) — guide de configuration AWS S3, SQS, et Snowpipe

---

## Auteur

**Elie NJINE TIENCHEU**

📞 +237 656 440 786  
📧 contact@elie-njine.online  
🔗 [LinkedIn](https://linkedin.com/in/elie-njine-736b04274)  
🌐 [Portfolio](https://www.elie-njine.online)  
💻 [GitHub](https://github.com/Elie-dev25)
