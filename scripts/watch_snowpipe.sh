#!/bin/bash

# ============================================================================
# Script de surveillance Snowpipe en temps réel
# ============================================================================

echo "🔍 SURVEILLANCE SNOWPIPE EN TEMPS RÉEL"
echo "======================================"
echo "Appuie sur Ctrl+C pour arrêter"
echo ""

# Boucle infinie
while true; do
  clear
  echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"
  echo "======================================"
  echo ""
  
  # Compter les lignes récentes
  echo "📊 Lignes chargées dans les 5 dernières minutes :"
  snowsql -c nyc_pipeline -o output_format=plain -o friendly=false -o timing=false \
    -q "SELECT COUNT(*) FROM nyc_taxi_db.bronze.yellow_trips_raw WHERE _loaded_at > DATEADD('minute', -5, CURRENT_TIMESTAMP());"
  
  echo ""
  echo "📁 Fichiers chargés récemment :"
  snowsql -c nyc_pipeline -o output_format=tsv -o friendly=false -o timing=false \
    -q "SELECT _source_file, COUNT(*) as rows, MAX(_loaded_at) as loaded_at FROM nyc_taxi_db.bronze.yellow_trips_raw WHERE _loaded_at > DATEADD('minute', -10, CURRENT_TIMESTAMP()) GROUP BY _source_file ORDER BY loaded_at DESC LIMIT 5;"
  
  echo ""
  echo "⏳ Prochaine vérification dans 10 secondes..."
  sleep 10
done



# # Rendre exécutable
# chmod +x scripts/watch_snowpipe.sh

# # Lancer la surveillance
# ./scripts/watch_snowpipe.sh