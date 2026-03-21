<?php

/**
 * Script de diagnostic pour les notifications push FCM
 * 
 * Utilisation :
 * php artisan tinker
 * include 'tests/DiagnosticPushNotifications.php';
 * DiagnosticPushNotifications::run();
 */

class DiagnosticPushNotifications
{
    public static function run()
    {
        echo "\n=== 🔍 DIAGNOSTIC NOTIFICATIONS PUSH FCM ===\n\n";
        
        // 1. Vérifier la configuration FCM
        self::checkFcmConfig();
        
        // 2. Vérifier les tokens du patron
        self::checkPatronTokens();
        
        // 3. Test d'envoi réel
        self::testSendPush();
        
        echo "\n=== ✅ DIAGNOSTIC TERMINÉ ===\n\n";
    }
    
    private static function checkFcmConfig()
    {
        echo "📋 1. CONFIGURATION FCM\n";
        echo str_repeat("-", 50) . "\n";
        
        $serverKey = config('services.fcm.server_key');
        
        if (empty($serverKey)) {
            echo "❌ FCM_SERVER_KEY n'est PAS configuré\n";
            echo "   Action: Ajoutez FCM_SERVER_KEY dans votre .env\n\n";
            return;
        }
        
        echo "✅ FCM_SERVER_KEY est configuré\n";
        echo "   Clé: " . substr($serverKey, 0, 20) . "...\n";
        
        // Vérifier le type de clé
        if (strpos($serverKey, 'AAAA') === 0 || strpos($serverKey, 'AAAAx') === 0) {
            echo "✅ Format: Server Key (Legacy) - CORRECT\n";
        } elseif (strpos($serverKey, 'BK') === 0 || strpos($serverKey, 'B') === 0) {
            echo "❌ Format: VAPID/Web Push Key - INCORRECT pour le backend!\n";
            echo "   Cette clé ne fonctionne QUE pour les navigateurs web.\n";
            echo "   Vous devez utiliser la Server Key (Legacy) de Firebase.\n";
            echo "\n";
            echo "   📝 Comment obtenir la bonne clé:\n";
            echo "   1. Allez sur https://console.firebase.google.com\n";
            echo "   2. Sélectionnez votre projet\n";
            echo "   3. ⚙️ Project Settings > Cloud Messaging\n";
            echo "   4. Copiez la 'Server key' (commence par AAAA)\n";
            echo "   5. Mettez à jour FCM_SERVER_KEY dans .env\n";
        } else {
            echo "⚠️  Format: Inconnu - Vérifiez que c'est la bonne clé\n";
        }
        
        echo "\n";
    }
    
    private static function checkPatronTokens()
    {
        echo "📋 2. TOKENS DU PATRON\n";
        echo str_repeat("-", 50) . "\n";
        
        $patron = \App\Models\User::where('role', 6)->first();
        
        if (!$patron) {
            echo "❌ Aucun utilisateur avec le rôle 'patron' (role = 6) trouvé\n\n";
            return;
        }
        
        echo "✅ Patron trouvé: {$patron->email} (ID: {$patron->id})\n";
        
        $tokens = \App\Models\DeviceToken::where('user_id', $patron->id)->get();
        
        if ($tokens->isEmpty()) {
            echo "❌ AUCUN token FCM enregistré pour le patron\n";
            echo "   Action: Le patron doit ouvrir l'app Flutter pour enregistrer son token\n\n";
            return;
        }
        
        echo "✅ {$tokens->count()} token(s) trouvé(s)\n\n";
        
        foreach ($tokens as $index => $token) {
            echo "   Token #" . ($index + 1) . ":\n";
            echo "   - ID: {$token->id}\n";
            echo "   - Token: " . substr($token->token, 0, 30) . "...\n";
            echo "   - Type: {$token->device_type}\n";
            echo "   - Actif: " . ($token->is_active ? '✅ OUI' : '❌ NON') . "\n";
            echo "   - Dernière utilisation: " . ($token->last_used_at ?? 'Jamais') . "\n";
            echo "   - Créé: {$token->created_at}\n";
            echo "\n";
        }
        
        $activeTokens = $tokens->where('is_active', true);
        if ($activeTokens->isEmpty()) {
            echo "❌ AUCUN token actif pour le patron\n";
            echo "   Action: Le patron doit se reconnecter à l'app\n";
        } else {
            echo "✅ {$activeTokens->count()} token(s) actif(s)\n";
        }
        
        echo "\n";
    }
    
    private static function testSendPush()
    {
        echo "📋 3. TEST D'ENVOI PUSH\n";
        echo str_repeat("-", 50) . "\n";
        
        $patron = \App\Models\User::where('role', 6)->first();
        
        if (!$patron) {
            echo "❌ Impossible de tester: Aucun patron trouvé\n\n";
            return;
        }
        
        $activeTokens = \App\Models\DeviceToken::where('user_id', $patron->id)
            ->where('is_active', true)
            ->count();
        
        if ($activeTokens === 0) {
            echo "❌ Impossible de tester: Aucun token actif\n\n";
            return;
        }
        
        echo "🚀 Envoi d'une notification de test au patron...\n";
        
        try {
            $pushService = app(\App\Services\PushNotificationService::class);
            
            $result = $pushService->sendToUser(
                $patron->id,
                '🔔 Test Notification',
                'Ceci est un test du système de notifications push',
                [
                    'test' => 'true',
                    'timestamp' => now()->toISOString(),
                ],
                [
                    'priority' => 'high',
                    'sound' => 'default',
                ]
            );
            
            if ($result['success']) {
                echo "✅ Notification envoyée avec succès!\n";
                echo "   Résultat: " . json_encode($result, JSON_PRETTY_PRINT) . "\n";
                echo "\n";
                echo "   👉 Vérifiez le téléphone du patron maintenant!\n";
                echo "   👉 Si aucune notification n'apparaît:\n";
                echo "      - Vérifiez que la FCM_SERVER_KEY est correcte\n";
                echo "      - Vérifiez les logs Laravel: tail -f storage/logs/laravel.log\n";
                echo "      - Vérifiez que l'app Flutter est configurée pour recevoir les notifications\n";
            } else {
                echo "❌ Échec de l'envoi: {$result['message']}\n";
                if (isset($result['response'])) {
                    echo "   Réponse FCM: " . json_encode($result['response'], JSON_PRETTY_PRINT) . "\n";
                }
            }
        } catch (\Exception $e) {
            echo "❌ ERREUR lors de l'envoi: {$e->getMessage()}\n";
            echo "   Trace: {$e->getTraceAsString()}\n";
        }
        
        echo "\n";
    }
}

