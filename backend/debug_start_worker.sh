#!/bin/bash

# Script de debug pour tester start_queue_worker.sh

APP_DIR="/home/amyv4492/kalyto.smil-app.com/kalyto_prod"
cd $APP_DIR || exit 1

echo "Test du script start_queue_worker.sh..."
echo ""

# Exécuter le script directement (sans nohup) pour voir les erreurs
bash -x ./start_queue_worker.sh 2>&1 | head -50

