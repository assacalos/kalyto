<?php

/**
 * Script de test rapide pour les notifications
 * Usage: php test_notification.php
 */

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "🧪 Test des Notifications\n";
echo str_repeat("=", 50) . "\n\n";

// 1. Vérifier la configuration Firebase
echo "1️⃣  Vérification de la configuration Firebase...\n";
$fcmPath = config('services.fcm.service_account_json');
if (file_exists($fcmPath)) {
    echo "   ✅ Fichier Firebase trouvé : $fcmPath\n";
} else {
    echo "   ❌ Fichier Firebase introuvable : $fcmPath\n";
    echo "   💡 Solution : Placez le fichier service-account.json dans storage/app/firebase/\n";
    exit(1);
}

// 2. Vérifier qu'un utilisateur existe
echo "\n2️⃣  Vérification des utilisateurs...\n";
$user = \App\Models\User::first();
if (!$user) {
    echo "   ❌ Aucun utilisateur trouvé dans la base de données\n";
    exit(1);
}
echo "   ✅ Utilisateur trouvé : {$user->email} (ID: {$user->id})\n";

// 3. Vérifier les tokens FCM
echo "\n3️⃣  Vérification des tokens FCM...\n";
$tokens = $user->activeDeviceTokens;
echo "   Tokens actifs pour {$user->email} : {$tokens->count()}\n";

if ($tokens->count() === 0) {
    echo "   ⚠️  Aucun token actif. L'app Flutter doit enregistrer un token.\n";
    echo "   💡 Pour tester quand même, la notification sera créée mais pas envoyée.\n";
} else {
    echo "   ✅ {$tokens->count()} token(s) actif(s) trouvé(s)\n";
}

// 4. Vérifier la queue
echo "\n4️⃣  Vérification de la queue...\n";
$jobCount = \DB::table('jobs')->count();
echo "   Jobs en attente : $jobCount\n";

// 5. Créer une notification de test
echo "\n5️⃣  Création d'une notification de test...\n";
try {
    $service = app(\App\Services\NotificationService::class);
    $notification = $service->createAndBroadcast(
        $user->id,
        'test',
        '🧪 Test Automatisé',
        'Ceci est un test automatique des notifications. Si vous recevez ce message, tout fonctionne !',
        [
            'entity_type' => 'test',
            'entity_id' => '1',
            'action_route' => '/test'
        ],
        'normale'
    );
    
    echo "   ✅ Notification créée avec succès !\n";
    echo "   📝 ID de la notification : {$notification->id}\n";
    echo "   👤 Destinataire : {$user->email}\n";
    echo "   📋 Titre : {$notification->titre}\n";
    echo "   💬 Message : {$notification->message}\n";
    
} catch (\Exception $e) {
    echo "   ❌ Erreur lors de la création : " . $e->getMessage() . "\n";
    exit(1);
}

// 6. Vérifier que le job est en queue
echo "\n6️⃣  Vérification du job en queue...\n";
$newJobCount = \DB::table('jobs')->count();
if ($newJobCount > $jobCount) {
    echo "   ✅ Job dispatché avec succès ! (Jobs en attente : $newJobCount)\n";
} else {
    echo "   ⚠️  Aucun nouveau job détecté\n";
}

// 7. Traiter le job
echo "\n7️⃣  Traitement du job...\n";
try {
    \Artisan::call('queue:work', ['--once' => true, '--timeout' => 10]);
    echo "   ✅ Job traité\n";
} catch (\Exception $e) {
    echo "   ⚠️  Erreur lors du traitement : " . $e->getMessage() . "\n";
    echo "   💡 Assurez-vous que le worker est démarré : php artisan queue:work\n";
}

// 8. Vérifier les logs récents
echo "\n8️⃣  Vérification des logs...\n";
$logFile = storage_path('logs/laravel.log');
if (file_exists($logFile)) {
    $logs = file_get_contents($logFile);
    $lastLines = array_slice(explode("\n", $logs), -20);
    $recentLogs = implode("\n", $lastLines);
    
    if (strpos($recentLogs, 'Notification FCM v1 envoyée') !== false) {
        echo "   ✅ Notification envoyée avec succès !\n";
    } elseif (strpos($recentLogs, 'Aucun token actif') !== false) {
        echo "   ⚠️  Aucun token actif pour cet utilisateur\n";
        echo "   💡 L'app Flutter doit enregistrer un token FCM\n";
    } elseif (strpos($recentLogs, 'FCM non initialisé') !== false) {
        echo "   ❌ FCM non initialisé\n";
        echo "   💡 Vérifiez le fichier Firebase JSON\n";
    } elseif (strpos($recentLogs, 'Erreur FCM') !== false || strpos($recentLogs, 'Exception') !== false) {
        echo "   ❌ Erreur détectée dans les logs\n";
        echo "   💡 Consultez storage/logs/laravel.log pour plus de détails\n";
    } else {
        echo "   ℹ️  Consultez storage/logs/laravel.log pour voir les détails\n";
    }
} else {
    echo "   ⚠️  Fichier de log introuvable\n";
}

// 9. Résumé
echo "\n" . str_repeat("=", 50) . "\n";
echo "📊 RÉSUMÉ\n";
echo str_repeat("=", 50) . "\n\n";

$notificationCount = \App\Models\Notification::where('user_id', $user->id)->count();
$unreadCount = \App\Models\Notification::where('user_id', $user->id)->where('statut', 'non_lue')->count();

echo "📬 Notifications totales pour {$user->email} : $notificationCount\n";
echo "📭 Notifications non lues : $unreadCount\n";
echo "📋 Jobs en attente : " . \DB::table('jobs')->count() . "\n";
echo "❌ Jobs en échec : " . \DB::table('failed_jobs')->count() . "\n";

echo "\n✅ Test terminé !\n\n";

if ($tokens->count() > 0) {
    echo "💡 Si vous avez l'app Flutter ouverte, vous devriez recevoir la notification.\n";
} else {
    echo "💡 Pour recevoir la notification, l'app Flutter doit enregistrer un token FCM.\n";
}

echo "\n📖 Pour plus de détails, consultez :\n";
echo "   - storage/logs/laravel.log\n";
echo "   - GUIDE_TEST_NOTIFICATIONS.md\n";


