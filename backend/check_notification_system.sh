#!/bin/bash

# Script de vérification du système de notifications
# À exécuter quotidiennement via Cron Job

APP_DIR="/home/amyv4492/kalyto.smil-app.com/kalyto_prod"
cd $APP_DIR || exit 1

LOG_FILE="$APP_DIR/storage/logs/system-check.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] === Vérification du système de notifications ===" >> "$LOG_FILE"

# 1. Vérifier que le worker tourne
if pgrep -f "queue:work" > /dev/null; then
    echo "[$DATE] ✅ Worker actif" >> "$LOG_FILE"
else
    echo "[$DATE] ❌ Worker arrêté - Redémarrage..." >> "$LOG_FILE"
    nohup ./start_queue_worker.sh > /dev/null 2>&1 &
fi

# 2. Vérifier le fichier Firebase
FIREBASE_FILE=$(php artisan tinker --execute="echo config('services.fcm.service_account_json');" 2>/dev/null | tail -1)
if [ -f "$FIREBASE_FILE" ]; then
    echo "[$DATE] ✅ Fichier Firebase présent" >> "$LOG_FILE"
else
    echo "[$DATE] ❌ Fichier Firebase manquant: $FIREBASE_FILE" >> "$LOG_FILE"
fi

# 3. Compter les jobs en échec
FAILED_JOBS=$(php artisan queue:failed --json 2>/dev/null | grep -o '"id"' | wc -l)
if [ "$FAILED_JOBS" -gt 10 ]; then
    echo "[$DATE] ⚠️  $FAILED_JOBS jobs en échec" >> "$LOG_FILE"
else
    echo "[$DATE] ✅ Jobs en échec: $FAILED_JOBS" >> "$LOG_FILE"
fi

# 4. Compter les jobs en attente
PENDING_JOBS=$(php artisan tinker --execute="echo \DB::table('jobs')->count();" 2>/dev/null | tail -1)
if [ "$PENDING_JOBS" -gt 100 ]; then
    echo "[$DATE] ⚠️  $PENDING_JOBS jobs en attente" >> "$LOG_FILE"
else
    echo "[$DATE] ✅ Jobs en attente: $PENDING_JOBS" >> "$LOG_FILE"
fi

# 5. Vérifier l'espace disque des logs
LOG_SIZE=$(du -sh storage/logs 2>/dev/null | cut -f1)
echo "[$DATE] 📊 Taille des logs: $LOG_SIZE" >> "$LOG_FILE"

# 6. Nettoyer les logs anciens (plus de 7 jours)
find storage/logs -name "*.log" -mtime +7 -delete 2>/dev/null
echo "[$DATE] 🧹 Nettoyage des logs anciens effectué" >> "$LOG_FILE"

echo "[$DATE] === Fin de la vérification ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

