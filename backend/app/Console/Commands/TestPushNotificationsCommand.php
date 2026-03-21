<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\DeviceToken;
use App\Services\PushNotificationService;
use App\Services\FcmV1Service;
use Illuminate\Support\Facades\Schema;

class TestPushNotificationsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'push:test {--user-id= : ID de l\'utilisateur à tester} {--all : Exécuter tous les tests}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Tester le système de notifications push';

    protected $pushService;

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->pushService = app(PushNotificationService::class);

        $this->info('=== TESTS DES NOTIFICATIONS PUSH ===');
        $this->newLine();

        // Test 1 : Migration
        $this->testMigration();

        // Test 2 : Configuration FCM
        $this->testFCMConfig();

        // Test 3 : Service
        $this->testService();

        // Test 4 : Structure de la table
        $this->testTableStructure();

        // Test 5 : Routes API
        $this->testAPIRoutes();

        // Test 6 : Tokens enregistrés
        $this->testTokens();

        // Test 7 : Envoi de notification (si --all ou si un user-id est fourni)
        if ($this->option('all') || $this->option('user-id')) {
            $this->testSendNotification();
        }

        $this->newLine();
        $this->info('=== FIN DES TESTS ===');
    }

    protected function testMigration()
    {
        $this->info('Test 1 : Vérification de la migration...');
        
        if (Schema::hasTable('device_tokens')) {
            $this->line('✅ Table \'device_tokens\' existe');
        } else {
            $this->error('❌ Table \'device_tokens\' n\'existe pas');
            $this->warn('   → Exécutez: php artisan migrate');
        }
        $this->newLine();
    }

    protected function testFCMConfig()
    {
        $this->info('Test 2 : Vérification de la configuration FCM (authentification v1 / fichier JSON)...');

        $pathConfig = config('services.fcm.service_account_json');
        if (empty($pathConfig)) {
            $this->error('❌ FCM : aucun chemin de fichier JSON configuré');
            $this->warn('   → Définissez dans .env: FCM_SERVICE_ACCOUNT_JSON=storage/app/firebase/service-account.json');
            $this->warn('   → Ou placez le fichier dans storage/app/firebase/service-account.json (valeur par défaut)');
            $this->warn('   → Puis exécutez: php artisan config:clear');
            $this->newLine();
            return;
        }

        // Résoudre le chemin (relatif ou absolu)
        $path = str_starts_with($pathConfig, '/') || preg_match('#^[A-Za-z]:\\\\#', $pathConfig)
            ? $pathConfig
            : base_path($pathConfig);

        if (!file_exists($path)) {
            $this->error('❌ Fichier JSON de compte de service Firebase introuvable');
            $this->line("   Chemin résolu: {$path}");
            $this->warn('   → Téléchargez le fichier depuis la console Firebase (Paramètres du projet > Comptes de service)');
            $this->warn('   → Placez-le dans storage/app/firebase/service-account.json ou définissez FCM_SERVICE_ACCOUNT_JSON dans .env');
            $this->newLine();
            return;
        }

        $size = filesize($path);
        if ($size < 100) {
            $this->error('❌ Fichier JSON trop petit ou vide');
            $this->newLine();
            return;
        }

        $json = @json_decode(file_get_contents($path), true);
        if (!$json || empty($json['type']) || empty($json['project_id']) || empty($json['private_key']) || empty($json['client_email'])) {
            $this->error('❌ Fichier JSON invalide (structure attendue: type, project_id, private_key, client_email)');
            $this->warn('   → Téléchargez un nouveau fichier "Clé de compte de service" depuis la console Firebase');
            $this->newLine();
            return;
        }

        $this->line('✅ Fichier JSON de compte de service Firebase trouvé et valide');
        $this->line("   Chemin: {$path}");
        $this->line("   Projet: {$json['project_id']}");
        $this->line("   Taille: {$size} octets");
        $this->newLine();
    }

    protected function testService()
    {
        $this->info('Test 3 : Vérification du service PushNotificationService...');
        
        try {
            $service = app(PushNotificationService::class);
            if ($service) {
                $this->line('✅ Service PushNotificationService disponible');
            }
        } catch (\Exception $e) {
            $this->error('❌ Erreur: ' . $e->getMessage());
        }
        $this->newLine();
    }

    protected function testTableStructure()
    {
        $this->info('Test 4 : Vérification de la structure de la table...');
        
        try {
            if (!Schema::hasTable('device_tokens')) {
                $this->warn('⚠️  Table non trouvée');
                $this->newLine();
                return;
            }

            $columns = Schema::getColumnListing('device_tokens');
            $requiredColumns = ['id', 'user_id', 'token', 'device_type', 'is_active', 'created_at'];
            
            $missing = array_diff($requiredColumns, $columns);
            
            if (empty($missing)) {
                $this->line('✅ Toutes les colonnes requises sont présentes');
                $this->line('   Colonnes: ' . implode(', ', $columns));
            } else {
                $this->error('❌ Colonnes manquantes: ' . implode(', ', $missing));
            }
        } catch (\Exception $e) {
            $this->error('❌ Erreur: ' . $e->getMessage());
        }
        $this->newLine();
    }

    protected function testAPIRoutes()
    {
        $this->info('Test 5 : Vérification des routes API...');
        
        $routes = \Route::getRoutes();
        $foundRoutes = [];
        
        foreach ($routes as $route) {
            if (str_contains($route->uri(), 'device-tokens')) {
                $foundRoutes[] = $route->methods()[0] . ' ' . $route->uri();
            }
        }
        
        if (!empty($foundRoutes)) {
            $this->line('✅ Routes API trouvées:');
            foreach ($foundRoutes as $route) {
                $this->line("   - {$route}");
            }
        } else {
            $this->error('❌ Aucune route API trouvée');
        }
        $this->newLine();
    }

    protected function testTokens()
    {
        $this->info('Test 6 : Vérification des tokens enregistrés...');
        
        try {
            $totalTokens = DeviceToken::count();
            $activeTokens = DeviceToken::where('is_active', true)->count();
            
            $this->line("   Total de tokens: {$totalTokens}");
            $this->line("   Tokens actifs: {$activeTokens}");
            
            if ($totalTokens > 0) {
                $usersWithTokens = DeviceToken::distinct('user_id')->count('user_id');
                $this->line("   Utilisateurs avec tokens: {$usersWithTokens}");
                
                // Afficher quelques exemples
                $sampleTokens = DeviceToken::with('user')
                    ->take(5)
                    ->get();
                
                if ($sampleTokens->count() > 0) {
                    $this->line('   Exemples:');
                    foreach ($sampleTokens as $token) {
                        $tokenPreview = substr($token->token, 0, 20) . '...';
                        $userEmail = $token->user ? $token->user->email : 'N/A';
                        $status = $token->is_active ? '✅ Actif' : '❌ Inactif';
                        $this->line("     - User: {$userEmail}, Type: {$token->device_type}, {$status}, Token: {$tokenPreview}");
                    }
                }
                $this->line('✅ Tokens trouvés');
            } else {
                $this->warn('⚠️  Aucun token enregistré');
                $this->warn('   → Connectez-vous depuis l\'app Flutter pour enregistrer un token');
            }
        } catch (\Exception $e) {
            $this->error('❌ Erreur: ' . $e->getMessage());
        }
        $this->newLine();
    }

    protected function testSendNotification()
    {
        $this->info('Test 7 : Test d\'envoi de notification push...');

        try {
            $fcmService = app(FcmV1Service::class);
            if (!$fcmService->isConfigured()) {
                $this->error('   ❌ FCM non initialisé : configurez le fichier JSON (FCM_SERVICE_ACCOUNT_JSON ou storage/app/firebase/service-account.json)');
                $this->newLine();
                return;
            }

            $userId = $this->option('user-id');

            if ($userId) {
                $user = User::find($userId);
                if (!$user) {
                    $this->error("❌ Utilisateur avec ID {$userId} introuvable");
                    $this->newLine();
                    return;
                }
            } else {
                $user = User::whereHas('activeDeviceTokens')->first();

                if (!$user) {
                    $this->warn('⚠️  Aucun utilisateur avec des tokens actifs trouvé');
                    $this->warn('   → Connectez-vous depuis l\'app Flutter pour enregistrer un token');
                    $this->newLine();
                    return;
                }
            }

            $tokens = DeviceToken::where('user_id', $user->id)
                ->where('is_active', true)
                ->get();

            if ($tokens->isEmpty()) {
                $this->warn("⚠️  Aucun token actif pour l'utilisateur {$user->email}");
                $this->newLine();
                return;
            }

            $this->line("   Utilisateur: {$user->email} (ID: {$user->id})");
            $this->line("   Tokens actifs: " . $tokens->count());

            if (!$this->confirm('   Voulez-vous envoyer une notification de test ?', true)) {
                $this->warn('   Test annulé');
                $this->newLine();
                return;
            }
            
            $this->line('   Envoi d\'une notification de test...');
            
            $result = $this->pushService->sendToUser(
                $user->id,
                '🔔 Test de notification',
                'Ceci est une notification de test depuis le backend Laravel',
                [
                    'test' => true,
                    'timestamp' => now()->toIso8601String(),
                    'entity_type' => 'test',
                    'entity_id' => 0,
                ]
            );
            
            if ($result['success']) {
                $this->line('   ✅ Notification envoyée avec succès!');
                $this->line("   → Vérifiez le téléphone de l'utilisateur {$user->email}");
                $this->line("   → Succès: {$result['success_count']}, Échecs: {$result['failure_count']}");
            } else {
                $this->error("   ❌ Échec de l'envoi: {$result['message']}");
            }
        } catch (\Exception $e) {
            $this->error('   ❌ Erreur: ' . $e->getMessage());
            if ($this->option('verbose')) {
                $this->error('   Trace: ' . $e->getTraceAsString());
            }
        }
        $this->newLine();
    }
}
