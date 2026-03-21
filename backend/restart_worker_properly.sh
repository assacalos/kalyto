#!/bin/bash

# Script pour redémarrer le worker proprement et créer le PID file

APP_DIR="/home/amyv4492/kalyto.smil-app.com/kalyto_prod"
cd $APP_DIR || exit 1

echo "=========================================="
echo "REDÉMARRAGE DU WORKER"
echo "=========================================="
echo ""

# 1. Arrêter tous les workers existants
echo "1. Arrêt des workers existants..."
pkill -f "queue:work" 2>/dev/null
pkill -f "start_queue_worker" 2>/dev/null
sleep 3
echo "✅ Workers arrêtés"
echo ""

# 2. Vérifier qu'il n'y a plus de workers
echo "2. Vérification qu'il n'y a plus de workers..."
if pgrep -f "queue:work" > /dev/null; then
    echo "⚠️  Des workers sont encore actifs, forçons l'arrêt..."
    pkill -9 -f "queue:work" 2>/dev/null
    sleep 2
else
    echo "✅ Aucun worker actif"
fi
echo ""

# 3. Nettoyer l'ancien PID file s'il existe
echo "3. Nettoyage de l'ancien PID file..."
rm -f storage/logs/queue-worker.pid
echo "✅ PID file nettoyé"
echo ""

# 4. Démarrer le worker avec le script
echo "4. Démarrage du worker avec start_queue_worker.sh..."
nohup ./start_queue_worker.sh > /dev/null 2>&1 &
sleep 3
echo "✅ Worker démarré"
echo ""

# 5. Vérifier que le worker tourne et que le PID file existe
echo "5. Vérification..."
sleep 2

if [ -f "storage/logs/queue-worker.pid" ]; then
    PID=$(cat storage/logs/queue-worker.pid)
    echo "✅ PID file créé: $PID"
    
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ Worker actif avec PID: $PID"
        echo ""
        echo "=========================================="
        echo "✅ REDÉMARRAGE RÉUSSI"
        echo "=========================================="
        echo ""
        echo "Le worker tourne maintenant avec le PID file."
        echo "Le script check_and_start_worker.sh pourra maintenant"
        echo "détecter correctement que le worker est actif."
    else
        echo "❌ Le PID dans le fichier ne correspond pas à un processus actif"
    fi
else
    echo "❌ Le PID file n'a pas été créé"
    echo "Vérifiez les logs: tail -f storage/logs/queue-worker.log"
fi

echo ""
echo "Pour vérifier que le worker tourne:"
echo "  ps aux | grep 'queue:work'"
echo ""
echo "Pour voir les logs:"
echo "  tail -f storage/logs/queue-worker.log"
echo ""

