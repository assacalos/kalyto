#!/bin/bash

# Script pour vérifier et démarrer le worker Laravel Queue
# À exécuter toutes les 5 minutes via Cron Job

APP_DIR="/home/amyv4492/kalyto.smil-app.com/kalyto_prod"
cd $APP_DIR || exit 1

LOG_FILE="$APP_DIR/storage/logs/worker-check.log"
PID_FILE="$APP_DIR/storage/logs/queue-worker.pid"

# Fonction pour vérifier si le worker tourne (utilise le PID file)
is_worker_running() {
    # Méthode 1: Vérifier le PID file (le plus fiable)
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
            # Vérifier que c'est bien un processus queue:work
            if ps -p "$PID" -o args= | grep -q "queue:work"; then
                return 0  # Le worker tourne
            else
                # PID file existe mais ce n'est pas le bon processus
                rm -f "$PID_FILE"
            fi
        else
            # PID file existe mais le processus est mort
            rm -f "$PID_FILE"
        fi
    fi
    
    # Méthode 2: Vérifier avec pgrep (fallback)
    if pgrep -f "queue:work" > /dev/null 2>&1; then
        return 0
    fi
    
    return 1  # Le worker ne tourne pas
}

# Vérifier si le worker tourne
if ! is_worker_running; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Worker arrêté détecté, redémarrage..." >> "$LOG_FILE"
    
    # Tuer les anciens processus s'ils existent
    pkill -f "start_queue_worker" 2>/dev/null
    sleep 2
    
    # Démarrer le worker
    nohup ./start_queue_worker.sh > /dev/null 2>&1 &
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Worker redémarré" >> "$LOG_FILE"
else
    # Log seulement une fois par heure (à la minute 0) pour confirmer que tout va bien
    if [ $(date +%M) -eq 0 ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null || echo "N/A")
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Worker actif (PID: $PID)" >> "$LOG_FILE"
    fi
fi

