# Snowpipe Setup Guide

**Projet :** NYC Taxi Real-Time Pipeline  
**Date :** 2026-03-06  

---

## Vue d'ensemble

Snowpipe permet le chargement automatique des fichiers dès leur arrivée dans S3, avec une latence de moins de 1 minute.

---

## Architecture
```
S3 Bucket → Event Notification → SQS Queue → Snowpipe → Table
```

---

## Configuration réalisée

### 1. Snowpipes créés

| Pipe Name    | Table          | Stage        | Status |
|--------------|----------------|--------------|--------|
| pipe_fhv     | fhv_trips_raw  | stage_fhv    | ✅     |
| pipe_yellow  | yellow_trips_raw | stage_yellow | ✅     |
| pipe_green   | green_trips_raw | stage_green  | ✅     |

### 2. S3 Event Notifications

| Event Name                    | Prefix          | Suffix    | Destination SQS |
|-------------------------------|-----------------|-----------|-----------------|
| snowpipe-fhv-notification     | landing/fhv/    | .parquet  | sf-snowpipe-... |
| snowpipe-yellow-notification  | landing/yellow/ | .parquet  | sf-snowpipe-... |
| snowpipe-green-notification   | landing/green/  | .parquet  | sf-snowpipe-... |

---

## Commandes de monitoring

### Vérifier le statut des pipes
```sql
SHOW PIPES;
SELECT SYSTEM$PIPE_STATUS('pipe_fhv');
```

### Voir l'historique de chargement
```sql
SELECT * FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'YELLOW_TRIPS_RAW',
    START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())
));
```

### Voir l'activité Snowpipe
```sql
SELECT * FROM TABLE(INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(
    DATE_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP())
));
```

---

## Tester Snowpipe

### Upload un fichier de test
```bash
aws s3 cp test_file.parquet s3://elie-nyc-taxi-pipeline/landing/yellow/
```

### Surveiller

Exécuter `sql/01_bronze/16_monitor_snowpipe.sql` en boucle.

---

## Coûts

- ~0.06 crédits par 1000 fichiers chargés
- Pour 100 fichiers/mois : ~0.006 crédits ≈ 0.01€

---

## Troubleshooting

### Le pipe ne charge pas

1. Vérifier que le pipe est créé : `SHOW PIPES;`
2. Vérifier le statut : `SELECT SYSTEM$PIPE_STATUS('pipe_name');`
3. Vérifier les Event Notifications S3
4. Vérifier que le SQS ARN est correct

### Erreurs de chargement
```sql
SELECT * FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(...))
WHERE status != 'LOADED';
```

---

# **RÉCAPITULATIF ÉTAPE 6** ⚡

## **✅ CE QU'ON VIENT DE FAIRE**

**1. Créé 3 Snowpipes**
```
✅ pipe_fhv
✅ pipe_yellow
✅ pipe_green
```

**2. Configuré S3 Event Notifications**
```
✅ 3 événements créés dans AWS S3
✅ Pointent vers les SQS queues Snowflake
```

**3. Créé le monitoring**
```
✅ Script de surveillance temps réel
✅ Documentation complète