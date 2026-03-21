#!/bin/bash

# Script pour vérifier que le worker est correctement configuré

APP_DIR="/home/amyv4492/kalyto.smil-app.com/kalyto_prod"
cd $APP_DIR || exit 1

echo "=========================================="
echo "VÉRIFICATION DU WORKER"
echo "=========================================="
echo ""

# 1. Vérifier que le worker tourne
echo "1. Vérification du worker..."
if pgrep -f "queue:work" > /dev/null; then
    PID=$(pgrep -f "queue:work" | head -1)
    echo "✅ Worker actif (PID: $PID)"
    ps aux | grep "[q]ueue:work" | grep -v grep
else
    echo "❌ Worker non actif"
fi
echo ""

# 2. Vérifier le PID file
echo "2. Vérification du PID file..."
if [ -f "storage/logs/queue-worker.pid" ]; then
    PID_FROM_FILE=$(cat storage/logs/queue-worker.pid)
    echo "✅ PID file existe: $PID_FROM_FILE"
    
    if ps -p $PID_FROM_FILE > /dev/null 2>&1; then
        echo "✅ Le PID dans le fichier correspond à un processus actif"
    else
        echo "❌ Le PID dans le fichier ne correspond pas à un processus actif"
    fi
else
    echo "❌ PID file n'existe pas"
fi
echo ""

# 3. Vérifier les logs récents
echo "3. Dernières lignes du log..."
if [ -f "storage/logs/queue-worker.log" ]; then
    tail -5 storage/logs/queue-worker.log
else
    echo "⚠️  Fichier de log non trouvé"
fi
echo ""

# 4. Test de notification
echo "4. Test de notification..."
echo "   Pour tester, exécutez dans tinker:"
echo "   \$service = app(\App\Services\NotificationService::class);"
echo "   \$service->createAndBroadcast(14, 'test', 'Test', 'Message test', [], 'normale');"
echo ""

echo "=========================================="
echo "RÉSUMÉ"
echo "=========================================="
echo ""
if [ -f "storage/logs/queue-worker.pid" ] && pgrep -f "queue:work" > /dev/null; then
    echo "✅ Le worker est correctement configuré et actif"
    echo ""
    echo "Le système de notifications devrait fonctionner en continu."
    echo "Le Cron Job check_and_start_worker.sh vérifiera toutes les 5 minutes"
    echo "que le worker tourne et le redémarrera si nécessaire."
else
    echo "⚠️  Il y a un problème avec la configuration du worker"
fi
echo ""

