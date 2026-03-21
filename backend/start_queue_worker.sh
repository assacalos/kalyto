#!/bin/bash

# Script de démarrage et surveillance du worker Laravel Queue
# Pour cPanel / Production

# Configuration
APP_DIR="/home/amyv4492/kalyto.smil-app.com/kalyto_prod"
LOG_FILE="$APP_DIR/storage/logs/queue-worker.log"
PID_FILE="$APP_DIR/storage/logs/queue-worker.pid"
SLEEP_TIME=60  # Vérifier toutes les 60 secondes

# Aller dans le répertoire de l'application d'abord
cd $APP_DIR || exit 1

# Détecter le chemin PHP (cPanel ou standard)
# Essayer d'abord les chemins cPanel courants
if [ -f "/opt/cpanel/ea-php81/root/usr/bin/php" ]; then
    PHP_CMD="/opt/cpanel/ea-php81/root/usr/bin/php"
elif [ -f "/opt/cpanel/ea-php82/root/usr/bin/php" ]; then
    PHP_CMD="/opt/cpanel/ea-php82/root/usr/bin/php"
elif [ -f "/opt/cpanel/ea-php83/root/usr/bin/php" ]; then
    PHP_CMD="/opt/cpanel/ea-php83/root/usr/bin/php"
elif [ -f "/usr/bin/php" ]; then
    PHP_CMD="/usr/bin/php"
elif [ -f "/usr/local/bin/php" ]; then
    PHP_CMD="/usr/local/bin/php"
elif which php > /dev/null 2>&1; then
    PHP_CMD=$(which php)
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Erreur: PHP non trouvé" >> "$LOG_FILE"
    exit 1
fi

# Vérifier que PHP fonctionne
if ! $PHP_CMD --version > /dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Erreur: PHP trouvé mais ne fonctionne pas: $PHP_CMD" >> "$LOG_FILE"
    exit 1
fi

# Fonction pour vérifier si le worker tourne (plus robuste)
is_worker_running() {
    # Vérifier d'abord avec le PID file
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            return 0  # Le worker tourne
        else
            # PID file existe mais le processus est mort
            rm -f "$PID_FILE"
        fi
    fi
    
    # Vérifier aussi avec pgrep (au cas où le PID file n'existe pas)
    if pgrep -f "queue:work" > /dev/null 2>&1; then
        return 0
    fi
    
    # Vérifier avec ps (plus fiable dans certains contextes)
    if ps aux | grep -v grep | grep "queue:work" > /dev/null 2>&1; then
        return 0
    fi
    
    return 1  # Le worker ne tourne pas
}

# Fonction pour démarrer le worker
start_worker() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Démarrage du worker..." >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PHP utilisé: $PHP_CMD" >> "$LOG_FILE"
    
    # Vérifier que artisan existe
    if [ ! -f "artisan" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Erreur: artisan non trouvé dans $APP_DIR" >> "$LOG_FILE"
        return 1
    fi
    
    # Tuer les anciens workers s'ils existent
    pkill -f "queue:work" 2>/dev/null
    sleep 2
    
    # Démarrer le nouveau worker en arrière-plan
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Exécution: $PHP_CMD artisan queue:work --sleep=3 --tries=3 --max-time=3600" >> "$LOG_FILE"
    $PHP_CMD artisan queue:work --sleep=3 --tries=3 --max-time=3600 >> "$LOG_FILE" 2>&1 &
    
    # Attendre un peu pour que le processus démarre
    sleep 3
    
    # Trouver le PID du processus queue:work (plus fiable que $!)
    PHP_PID=$(ps aux | grep "[q]ueue:work" | grep -v grep | awk '{print $2}' | head -1)
    
    if [ -n "$PHP_PID" ] && ps -p $PHP_PID > /dev/null 2>&1; then
        # Sauvegarder le PID
        echo $PHP_PID > "$PID_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Worker démarré avec PID: $PHP_PID" >> "$LOG_FILE"
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Erreur: Le worker n'a pas pu démarrer ou PID introuvable" >> "$LOG_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tentative de trouver le processus..." >> "$LOG_FILE"
        ps aux | grep "queue:work" >> "$LOG_FILE" 2>&1
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dernières lignes du log:" >> "$LOG_FILE"
        tail -5 "$LOG_FILE" >> "$LOG_FILE" 2>&1 || true
        rm -f "$PID_FILE"
        return 1
    fi
}

# Fonction pour arrêter le worker
stop_worker() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Arrêt du worker..." >> "$LOG_FILE"
    pkill -f "queue:work"
    rm -f "$PID_FILE"
    sleep 2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Worker arrêté" >> "$LOG_FILE"
}

# Fonction pour redémarrer le worker
restart_worker() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Redémarrage du worker..." >> "$LOG_FILE"
    stop_worker
    sleep 2
    start_worker
}

# Gestion des signaux pour arrêt propre
trap 'stop_worker; exit 0' SIGTERM SIGINT

# Démarrer le worker au début
start_worker

# Boucle de surveillance
while true; do
    sleep $SLEEP_TIME
    
    if ! is_worker_running; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Worker arrêté détecté, redémarrage..." >> "$LOG_FILE"
        start_worker
    fi
done


