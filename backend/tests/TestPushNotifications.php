<?php

namespace Tests;

use App\Models\User;
use App\Models\DeviceToken;
use App\Services\PushNotificationService;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

/**
 * Script de test pour les notifications push
 * 
 * Utilisation :
 * php artisan tinker
 * >>> (new Tests\TestPushNotifications())->runAllTests()
 */
class TestPushNotifications
{
    protected $pushService;

    public function __construct()
    {
        $this->pushService = app(PushNotificationService::class);
    }

    /**
     * Exécuter tous les tests
     */
    public function runAllTests()
    {
        echo "\n=== TESTS DES NOTIFICATIONS PUSH ===\n\n";

        $this->test1_CheckMigration();
        $this->test2_CheckFCMConfig();
        $this->test3_CheckServiceExists();
        $this->test4_CheckDeviceTokensTable();
        $this->test5_CheckAPIEndpoints();
        $this->test6_TestTokenRegistration();
        $this->test7_TestPushNotification();

        echo "\n=== FIN DES TESTS ===\n";
    }

    /**
     * Test 1 : Vérifier que la migration a été exécutée
     */
    public function test1_CheckMigration()
    {
        echo "Test 1 : Vérification de la migration...\n";
        
        try {
            $exists = \Schema::hasTable('device_tokens');
            if ($exists) {
                echo "✅ Table 'device_tokens' existe\n\n";
            } else {
                echo "❌ Table 'device_tokens' n'existe pas\n";
                echo "   → Exécutez: php artisan migrate\n\n";
            }
        } catch (\Exception $e) {
            echo "❌ Erreur: " . $e->getMessage() . "\n\n";
        }
    }

    /**
     * Test 2 : Vérifier la configuration FCM
     */
    public function test2_CheckFCMConfig()
    {
        echo "Test 2 : Vérification de la configuration FCM...\n";
        
        $serverKey = config('services.fcm.server_key');
        
        if (empty($serverKey)) {
            echo "❌ FCM_SERVER_KEY n'est pas configuré\n";
            echo "   → Ajoutez dans .env: FCM_SERVER_KEY=votre_cle_ici\n";
            echo "   → Puis exécutez: php artisan config:clear\n\n";
        } else {
            $keyLength = strlen($serverKey);
            $maskedKey = substr($serverKey, 0, 10) . '...' . substr($serverKey, -10);
            echo "✅ FCM_SERVER_KEY est configuré (longueur: {$keyLength} caractères)\n";
            echo "   Clé: {$maskedKey}\n\n";
        }
    }

    /**
     * Test 3 : Vérifier que le service existe
     */
    public function test3_CheckServiceExists()
    {
        echo "Test 3 : Vérification du service PushNotificationService...\n";
        
        try {
            $service = app(PushNotificationService::class);
            if ($service) {
                echo "✅ Service PushNotificationService disponible\n\n";
            } else {
                echo "❌ Service PushNotificationService introuvable\n\n";
            }
        } catch (\Exception $e) {
            echo "❌ Erreur: " . $e->getMessage() . "\n\n";
        }
    }

    /**
     * Test 4 : Vérifier la structure de la table device_tokens
     */
    public function test4_CheckDeviceTokensTable()
    {
        echo "Test 4 : Vérification de la structure de la table...\n";
        
        try {
            $columns = \Schema::getColumnListing('device_tokens');
            $requiredColumns = ['id', 'user_id', 'token', 'device_type', 'is_active', 'created_at'];
            
            $missing = array_diff($requiredColumns, $columns);
            
            if (empty($missing)) {
                echo "✅ Toutes les colonnes requises sont présentes\n";
                echo "   Colonnes: " . implode(', ', $columns) . "\n\n";
            } else {
                echo "❌ Colonnes manquantes: " . implode(', ', $missing) . "\n\n";
            }
        } catch (\Exception $e) {
            echo "❌ Erreur: " . $e->getMessage() . "\n\n";
        }
    }

    /**
     * Test 5 : Vérifier les endpoints API
     */
    public function test5_CheckAPIEndpoints()
    {
        echo "Test 5 : Vérification des routes API...\n";
        
        $routes = [
            'POST /api/device-tokens' => 'DeviceTokenController@store',
            'GET /api/device-tokens' => 'DeviceTokenController@index',
            'DELETE /api/device-tokens/{id}' => 'DeviceTokenController@destroy',
        ];
        
        $allRoutes = \Route::getRoutes();
        $found = 0;
        
        foreach ($routes as $route => $action) {
            $exists = false;
            foreach ($allRoutes as $r) {
                if (str_contains($r->uri(), 'device-tokens') && 
                    str_contains($r->getActionName(), 'DeviceTokenController')) {
                    $exists = true;
                    $found++;
                    break;
                }
            }
            if ($exists) {
                echo "✅ Route trouvée: {$route}\n";
            } else {
                echo "❌ Route manquante: {$route}\n";
            }
        }
        
        if ($found === count($routes)) {
            echo "\n✅ Toutes les routes API sont configurées\n\n";
        } else {
            echo "\n⚠️  Certaines routes sont manquantes\n\n";
        }
    }

    /**
     * Test 6 : Tester l'enregistrement d'un token (simulation)
     */
    public function test6_TestTokenRegistration()
    {
        echo "Test 6 : Test d'enregistrement de token (simulation)...\n";
        
        try {
            $user = User::first();
            if (!$user) {
                echo "⚠️  Aucun utilisateur trouvé dans la base de données\n";
                echo "   → Créez un utilisateur pour tester\n\n";
                return;
            }
            
            $tokenCount = DeviceToken::where('user_id', $user->id)->count();
            echo "   Utilisateur test: {$user->email} (ID: {$user->id})\n";
            echo "   Tokens enregistrés pour cet utilisateur: {$tokenCount}\n";
            
            if ($tokenCount > 0) {
                $tokens = DeviceToken::where('user_id', $user->id)->get();
                echo "   Détails des tokens:\n";
                foreach ($tokens as $token) {
                    $tokenPreview = substr($token->token, 0, 20) . '...';
                    echo "     - ID: {$token->id}, Type: {$token->device_type}, Actif: " . ($token->is_active ? 'Oui' : 'Non') . ", Token: {$tokenPreview}\n";
                }
                echo "\n✅ Tokens trouvés\n\n";
            } else {
                echo "   ⚠️  Aucun token enregistré pour cet utilisateur\n";
                echo "   → Connectez-vous depuis l'app Flutter pour enregistrer un token\n\n";
            }
        } catch (\Exception $e) {
            echo "❌ Erreur: " . $e->getMessage() . "\n\n";
        }
    }

    /**
     * Test 7 : Tester l'envoi d'une notification push
     */
    public function test7_TestPushNotification()
    {
        echo "Test 7 : Test d'envoi de notification push...\n";
        
        try {
            $user = User::first();
            if (!$user) {
                echo "⚠️  Aucun utilisateur trouvé\n\n";
                return;
            }
            
            $tokens = DeviceToken::where('user_id', $user->id)
                ->where('is_active', true)
                ->get();
            
            if ($tokens->isEmpty()) {
                echo "⚠️  Aucun token actif pour l'utilisateur {$user->email}\n";
                echo "   → Connectez-vous depuis l'app Flutter pour enregistrer un token\n\n";
                return;
            }
            
            echo "   Utilisateur: {$user->email}\n";
            echo "   Tokens actifs: " . $tokens->count() . "\n";
            
            $serverKey = config('services.fcm.server_key');
            if (empty($serverKey)) {
                echo "   ❌ Impossible de tester: FCM_SERVER_KEY non configuré\n\n";
                return;
            }
            
            echo "   Envoi d'une notification de test...\n";
            
            $result = $this->pushService->sendToUser(
                $user->id,
                'Test de notification',
                'Ceci est une notification de test depuis le backend',
                [
                    'test' => true,
                    'timestamp' => now()->toIso8601String(),
                ]
            );
            
            if ($result['success']) {
                echo "   ✅ Notification envoyée avec succès!\n";
                echo "   → Vérifiez le téléphone de l'utilisateur {$user->email}\n";
                echo "   → Succès: {$result['success_count']}, Échecs: {$result['failure_count']}\n\n";
            } else {
                echo "   ❌ Échec de l'envoi: {$result['message']}\n\n";
            }
        } catch (\Exception $e) {
            echo "   ❌ Erreur: " . $e->getMessage() . "\n";
            echo "   Trace: " . $e->getTraceAsString() . "\n\n";
        }
    }

    /**
     * Test rapide : Vérifier seulement la configuration
     */
    public function quickCheck()
    {
        echo "\n=== VÉRIFICATION RAPIDE ===\n\n";
        
        $this->test1_CheckMigration();
        $this->test2_CheckFCMConfig();
        $this->test3_CheckServiceExists();
        
        echo "\n=== FIN ===\n";
    }
}

