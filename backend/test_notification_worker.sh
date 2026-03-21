#!/bin/bash

# Script de test rapide pour vérifier que le worker traite les notifications

echo "=========================================="
echo "TEST DU SYSTÈME DE NOTIFICATIONS"
echo "=========================================="
echo ""

# 1. Vérifier que le worker tourne
echo "1. Vérification du worker..."
if pgrep -f "queue:work" > /dev/null; then
    echo "✅ Worker actif (PID: $(pgrep -f 'queue:work' | head -1))"
else
    echo "❌ Worker non actif - Démarrez-le avec: nohup ./start_queue_worker.sh > /dev/null 2>&1 &"
    exit 1
fi
echo ""

# 2. Créer une notification de test
echo "2. Création d'une notification de test..."
php artisan tinker --execute="
\$service = app(\App\Services\NotificationService::class);
\$notification = \$service->createAndBroadcast(
    14, // user_id
    'test',
    'Test Worker - ' . date('H:i:s'),
    'Cette notification devrait être traitée immédiatement par le worker actif !',
    [
        'entity_type' => 'test',
        'entity_id' => '1',
        'action_route' => '/test'
    ],
    'normale'
);
echo 'Notification créée avec ID: ' . \$notification->id . PHP_EOL;
echo 'Attendez 5 secondes pour que le worker traite le job...' . PHP_EOL;
" 2>/dev/null

echo ""
echo "3. Attente de 5 secondes..."
sleep 5
echo ""

# 3. Vérifier les logs récents
echo "4. Vérification des logs récents..."
if [ -f "storage/logs/laravel.log" ]; then
    echo "Dernières lignes du log Laravel (notifications/FCM):"
    tail -n 30 storage/logs/laravel.log | grep -i "notification\|fcm\|ProcessNotificationActionsJob\|Tentative d'envoi\|Notification FCM" | tail -n 5
else
    echo "⚠️  Fichier de log non trouvé"
fi
echo ""

# 4. Vérifier les jobs en attente
echo "5. Vérification des jobs en attente..."
PENDING=$(php artisan tinker --execute="echo \DB::table('jobs')->count();" 2>/dev/null | tail -1)
if [ "$PENDING" -gt 0 ]; then
    echo "⚠️  Il y a $PENDING job(s) en attente"
    echo "   Le worker devrait les traiter automatiquement"
else
    echo "✅ Aucun job en attente (tous traités)"
fi
echo ""

# 5. Vérifier les jobs échoués
echo "6. Vérification des jobs échoués..."
FAILED=$(php artisan queue:failed 2>&1 | grep -c "No failed jobs" || echo "0")
if [ "$FAILED" -eq 0 ]; then
    echo "⚠️  Il y a des jobs échoués:"
    php artisan queue:failed | head -n 5
else
    echo "✅ Aucun job échoué"
fi
echo ""

echo "=========================================="
echo "RÉSUMÉ"
echo "=========================================="
echo ""
echo "Si vous avez reçu la notification sur votre téléphone:"
echo "  ✅ Le système fonctionne correctement !"
echo ""
echo "Si vous n'avez pas reçu la notification:"
echo "  1. Vérifiez que vous avez un token d'appareil actif:"
echo "     php artisan tinker"
echo "     \$tokens = \App\Models\DeviceToken::where('user_id', 14)->where('is_active', true)->get();"
echo "     echo \$tokens->count();"
echo ""
echo "  2. Vérifiez les logs du worker:"
echo "     tail -f storage/logs/queue-worker.log"
echo ""
echo "  3. Vérifiez les logs Laravel:"
echo "     tail -f storage/logs/laravel.log | grep -i notification"
echo ""

