#!/bin/bash

# Script de vérification complète du système de notifications
# À exécuter sur le serveur pour vérifier que tout fonctionne

APP_DIR="/home/amyv4492/kalyto.smil-app.com/kalyto_prod"
cd $APP_DIR || exit 1

echo "=========================================="
echo "VÉRIFICATION COMPLÈTE DU SYSTÈME"
echo "DE NOTIFICATIONS"
echo "=========================================="
echo ""

# 1. Vérifier que le worker tourne
echo "1. VÉRIFICATION DU WORKER"
echo "-------------------------"
if pgrep -f "queue:work" > /dev/null; then
    PID=$(pgrep -f "queue:work" | head -1)
    echo "✅ Worker actif (PID: $PID)"
    ps aux | grep "[q]ueue:work" | grep -v grep | awk '{print "   PID:", $2, "| CPU:", $3"%", "| MEM:", $4"%", "| CMD:", substr($0, index($0,$11))}'
else
    echo "❌ Worker NON ACTIF"
    echo "   → Démarrez-le avec: nohup ./start_queue_worker.sh > /dev/null 2>&1 &"
fi
echo ""

# 2. Vérifier le PID file
echo "2. VÉRIFICATION DU PID FILE"
echo "---------------------------"
if [ -f "storage/logs/queue-worker.pid" ]; then
    PID_FROM_FILE=$(cat storage/logs/queue-worker.pid 2>/dev/null)
    echo "✅ PID file existe: $PID_FROM_FILE"
    
    if [ -n "$PID_FROM_FILE" ] && ps -p $PID_FROM_FILE > /dev/null 2>&1; then
        echo "✅ Le PID correspond à un processus actif"
    else
        echo "⚠️  Le PID dans le fichier ne correspond pas à un processus actif"
    fi
else
    echo "❌ PID file n'existe pas"
    echo "   → Le worker n'a pas été démarré avec start_queue_worker.sh"
fi
echo ""

# 3. Vérifier les jobs en attente
echo "3. JOBS EN ATTENTE"
echo "------------------"
PENDING_JOBS=$(php artisan tinker --execute="echo \DB::table('jobs')->count();" 2>/dev/null | tail -1)
if [ -n "$PENDING_JOBS" ] && [ "$PENDING_JOBS" -gt 0 ]; then
    echo "⚠️  Il y a $PENDING_JOBS job(s) en attente"
    echo "   → Le worker devrait les traiter automatiquement"
else
    echo "✅ Aucun job en attente (tous traités)"
fi
echo ""

# 4. Vérifier les jobs échoués
echo "4. JOBS ÉCHOUÉS"
echo "----------------"
FAILED_COUNT=$(php artisan queue:failed 2>&1 | grep -c "No failed jobs" || echo "0")
if [ "$FAILED_COUNT" -eq 0 ]; then
    FAILED_JOBS=$(php artisan queue:failed 2>&1 | grep -c "^\s*[0-9]" || echo "0")
    if [ "$FAILED_JOBS" -gt 0 ]; then
        echo "⚠️  Il y a $FAILED_JOBS job(s) échoué(s)"
        echo "   → Voir les détails: php artisan queue:failed"
    else
        echo "✅ Aucun job échoué"
    fi
else
    echo "✅ Aucun job échoué"
fi
echo ""

# 5. Vérifier le fichier Firebase
echo "5. FICHIER FIREBASE"
echo "-------------------"
FIREBASE_FILE="storage/app/firebase/service-account.json"
if [ -f "$FIREBASE_FILE" ]; then
    FILE_SIZE=$(stat -c%s "$FIREBASE_FILE" 2>/dev/null || stat -f%z "$FIREBASE_FILE" 2>/dev/null || echo "0")
    if [ "$FILE_SIZE" -gt 100 ]; then
        echo "✅ Fichier Firebase trouvé (Taille: $FILE_SIZE octets)"
    else
        echo "⚠️  Fichier Firebase trouvé mais semble vide ou corrompu"
    fi
else
    echo "❌ Fichier Firebase NON TROUVÉ"
    echo "   → Chemin attendu: $FIREBASE_FILE"
fi
echo ""

# 6. Tokens d'appareil (TOUS les utilisateurs — la logique des notifications est par RÔLE)
echo "6. TOKENS D'APPAREIL (tous les utilisateurs)"
echo "--------------------------------------------"
TOKEN_COUNT=$(php artisan tinker --execute="
echo \App\Models\DeviceToken::where('is_active', true)->count();
" 2>/dev/null | tail -1)

USERS_WITH_TOKENS=$(php artisan tinker --execute="
\$userIds = \App\Models\DeviceToken::where('is_active', true)->distinct()->pluck('user_id');
\$users = \App\Models\User::whereIn('id', \$userIds)->get(['id','email','role']);
foreach (\$users as \$u) {
    \$role = \$u->role == 6 ? 'Patron' : (\$u->role == 2 ? 'Commercial' : 'Rôle '.\$u->role);
    echo \$u->id . ' | ' . \$u->email . ' | ' . \$role . PHP_EOL;
}
" 2>/dev/null | tail -n +1)

if [ -n "$TOKEN_COUNT" ] && [ "$TOKEN_COUNT" -gt 0 ]; then
    echo "✅ $TOKEN_COUNT token(s) actif(s) au total"
    echo "   Utilisateurs pouvant recevoir les notifications push:"
    echo "$USERS_WITH_TOKENS" | sed 's/^/   /'
    echo "   → Tous les utilisateurs avec le même rôle reçoivent la même notification (ex. tous les Patrons)."
else
    echo "⚠️  Aucun token actif"
    echo "   → Chaque utilisateur doit se connecter au moins une fois depuis l'application mobile"
    echo "   pour enregistrer son appareil. Ensuite il recevra les notifications selon son rôle."
fi
echo ""

# 7. Dernière notification (toutes, pas un utilisateur précis)
echo "7. DERNIÈRE NOTIFICATION (système)"
echo "-----------------------------------"
LAST_NOTIF=$(php artisan tinker --execute="
\$notif = \App\Models\Notification::latest()->first();
if (\$notif) {
    echo \$notif->id . '|' . \$notif->type . '|' . \$notif->titre . '|' . \$notif->created_at->format('Y-m-d H:i:s') . '|' . \$notif->user_id;
} else {
    echo 'AUCUNE';
}
" 2>/dev/null | tail -1)

if [ "$LAST_NOTIF" != "AUCUNE" ] && [ -n "$LAST_NOTIF" ]; then
    IFS='|' read -r ID TYPE TITRE DATE USER_ID <<< "$LAST_NOTIF"
    echo "✅ Dernière notification:"
    echo "   ID: $ID | Type: $TYPE | Titre: $TITRE | Date: $DATE | user_id: $USER_ID"
else
    echo "⚠️  Aucune notification en base"
fi
echo ""

# 8. Vérifier les logs récents
echo "8. LOGS RÉCENTS"
echo "---------------"
if [ -f "storage/logs/queue-worker.log" ]; then
    echo "Dernières lignes du log worker:"
    tail -5 storage/logs/queue-worker.log | sed 's/^/   /'
else
    echo "⚠️  Fichier de log worker non trouvé"
fi
echo ""

# 9. Vérifier les logs de vérification (Cron Job)
echo "9. LOGS DE VÉRIFICATION (Cron Job)"
echo "-----------------------------------"
if [ -f "storage/logs/worker-check.log" ]; then
    echo "Dernières vérifications:"
    tail -5 storage/logs/worker-check.log | sed 's/^/   /'
else
    echo "⚠️  Fichier de log de vérification non trouvé"
    echo "   → Le Cron Job n'a peut-être pas encore été exécuté"
fi
echo ""

# 10. Test de notification (optionnel)
echo "10. TEST DE NOTIFICATION"
echo "------------------------"
echo "Pour envoyer une notification de test à UN utilisateur (remplacez USER_ID par l'id voulu):"
echo ""
echo "   php artisan tinker"
echo ""
echo "Puis dans tinker:"
echo "   \$service = app(\App\Services\NotificationService::class);"
echo "   \$service->createAndBroadcast(USER_ID, 'test', 'Test Système', 'Message de test', [], 'normale');"
echo ""
echo "Pour notifier TOUS les patrons (rôle 6):"
echo "   \$service->broadcastToRole(6, 'test', 'Test Patrons', 'Message pour tous les patrons', [], 'normale');"
echo ""
echo "Attendez 5-10 secondes et vérifiez:"
echo "   1. Que le(s) destinataire(s) reçoivent la notification sur leur téléphone"
echo "   2. Que le job a été traité: tail -f storage/logs/queue-worker.log"
echo ""

echo "=========================================="
echo "RÉSUMÉ"
echo "=========================================="
echo ""

# Compter les problèmes
ISSUES=0

if ! pgrep -f "queue:work" > /dev/null; then
    echo "❌ Worker non actif"
    ISSUES=$((ISSUES + 1))
fi

if [ ! -f "storage/logs/queue-worker.pid" ]; then
    echo "❌ PID file manquant"
    ISSUES=$((ISSUES + 1))
fi

if [ ! -f "$FIREBASE_FILE" ]; then
    echo "❌ Fichier Firebase manquant"
    ISSUES=$((ISSUES + 1))
fi

if [ -z "$TOKEN_COUNT" ] || [ "$TOKEN_COUNT" -eq 0 ]; then
    echo "⚠️  Aucun token d'appareil actif (aucun utilisateur ne recevra de push pour l'instant)"
    ISSUES=$((ISSUES + 1))
fi

if [ "$ISSUES" -eq 0 ]; then
    echo "✅ TOUT FONCTIONNE CORRECTEMENT !"
    echo ""
    echo "Le système de notifications est opérationnel."
    echo "Les notifications seront envoyées automatiquement"
    echo "lors de la création/modification d'entités."
else
    echo "⚠️  $ISSUES problème(s) détecté(s)"
    echo ""
    echo "Corrigez les problèmes ci-dessus pour que"
    echo "le système fonctionne à 100%."
fi

echo ""

