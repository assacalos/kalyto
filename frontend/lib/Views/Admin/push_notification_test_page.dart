import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easyconnect/services/push_notification_service.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/utils/error_helper.dart';
import 'dart:convert';
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class PushNotificationTestPage extends StatefulWidget {
  const PushNotificationTestPage({super.key});

  @override
  State<PushNotificationTestPage> createState() =>
      _PushNotificationTestPageState();
}

class _PushNotificationTestPageState extends State<PushNotificationTestPage> {
  final PushNotificationService _pushService = PushNotificationService();
  String? _fcmToken;
  bool _isLoading = false;
  String _testStatus = '';
  final List<String> _testLogs = [];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    setState(() {
      _fcmToken = _pushService.fcmToken;
    });
  }

  void _addLog(String message) {
    setState(() {
      _testLogs.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
      if (_testLogs.length > 20) {
        _testLogs.removeLast();
      }
    });
  }

  /// Test 1: Vérifier l'initialisation de Firebase
  Future<void> _testFirebaseInitialization() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Test en cours...';
      _testLogs.clear();
    });

    _addLog('🔍 Test 1: Vérification de Firebase...');

    try {
      final app = Firebase.app();
      _addLog('✅ Firebase initialisé: ${app.name}');
      _addLog('✅ Options: ${app.options.projectId}');
      setState(() {
        _testStatus = '✅ Firebase initialisé avec succès';
      });
    } catch (e) {
      _addLog('❌ Erreur Firebase: $e');
      setState(() {
        _testStatus = '❌ Firebase non initialisé';
      });
      ErrorHelper.showError(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test 2: Obtenir le token FCM
  Future<void> _testGetFCMToken() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Test en cours...';
    });

    _addLog('🔍 Test 2: Obtention du token FCM...');

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        setState(() {
          _fcmToken = token;
        });
        _addLog('✅ Token FCM obtenu: ${token.substring(0, 30)}...');
        _addLog('📋 Token complet: $token');
        setState(() {
          _testStatus = '✅ Token FCM obtenu avec succès';
        });
      } else {
        _addLog('❌ Token FCM null');
        setState(() {
          _testStatus = '❌ Impossible d\'obtenir le token';
        });
      }
    } catch (e) {
      _addLog('❌ Erreur lors de l\'obtention du token: $e');
      setState(() {
        _testStatus = '❌ Erreur: $e';
      });
      ErrorHelper.showError(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test 3: Vérifier les permissions
  Future<void> _testPermissions() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Test en cours...';
    });

    _addLog('🔍 Test 3: Vérification des permissions...');

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      String statusText;
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          statusText = '✅ Autorisé';
          break;
        case AuthorizationStatus.provisional:
          statusText = '⚠️ Provisoire';
          break;
        case AuthorizationStatus.denied:
          statusText = '❌ Refusé';
          break;
        case AuthorizationStatus.notDetermined:
          statusText = '❓ Non déterminé';
          break;
      }

      _addLog('📱 Statut: $statusText');
      _addLog('🔔 Alert: ${settings.alert}');
      _addLog('🔴 Badge: ${settings.badge}');
      _addLog('🔊 Sound: ${settings.sound}');

      setState(() {
        _testStatus = statusText;
      });
    } catch (e) {
      _addLog('❌ Erreur: $e');
      setState(() {
        _testStatus = '❌ Erreur: $e';
      });
      ErrorHelper.showError(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test 4: Enregistrer le token sur le backend
  Future<void> _testRegisterToken() async {
    if (_fcmToken == null) {
      ErrorHelper.showValidationError('Veuillez d\'abord obtenir le token FCM');
      return;
    }

    if (!(await SessionService.isAuthenticated())) {
      ErrorHelper.showValidationError(
        'Vous devez être connecté pour enregistrer le token',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _testStatus = 'Test en cours...';
    });

    _addLog('🔍 Test 4: Enregistrement du token sur le backend...');

    try {
      final authToken = await SessionService.getToken();
      if (authToken == null || authToken.isEmpty) {
        _addLog('❌ Token d\'authentification manquant');
        setState(() {
          _testStatus = '❌ Non authentifié';
        });
        return;
      }

      final deviceType = _getDeviceType();
      final deviceId = await _getDeviceId();
      final appVersion = await _getAppVersion();

      _addLog('📤 Envoi vers: ${AppConfig.baseUrl}/device-tokens');
      _addLog('📱 Device Type: $deviceType');
      _addLog('🆔 Device ID: $deviceId');
      _addLog('📦 App Version: $appVersion');

      final response = await HttpInterceptor.post(
        HttpInterceptor.apiUri('device-tokens'),
        body: jsonEncode({
          'token': _fcmToken,
          'device_type': deviceType,
          'device_id': deviceId,
          'app_version': appVersion,
        }),
      );

      _addLog('📥 Réponse: ${response.statusCode}');
      _addLog('📄 Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        _addLog('✅ Token enregistré avec succès');
        setState(() {
          _testStatus = '✅ Token enregistré (${response.statusCode})';
        });
        ErrorHelper.showSuccess('Token enregistré avec succès');
      } else {
        _addLog('❌ Erreur: ${response.statusCode}');
        _addLog('📄 Réponse: ${response.body}');
        setState(() {
          _testStatus = '❌ Erreur ${response.statusCode}';
        });
        ErrorHelper.showError(
          Exception('Erreur ${response.statusCode}: ${response.body}'),
          showToUser: true,
        );
      }
    } catch (e) {
      _addLog('❌ Erreur: $e');
      setState(() {
        _testStatus = '❌ Erreur: $e';
      });
      ErrorHelper.showError(e, showToUser: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test 5: Tester la réception de notifications
  Future<void> _testNotificationReception() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Test en cours...';
    });

    _addLog('🔍 Test 5: Configuration des listeners de notifications...');

    try {
      // Configurer les listeners
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _addLog('📨 Notification reçue (premier plan): ${message.messageId}');
        _addLog('📋 Titre: ${message.notification?.title}');
        _addLog('📋 Corps: ${message.notification?.body}');
        _addLog('📋 Données: ${message.data}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _addLog('📨 Notification ouverte (arrière-plan): ${message.messageId}');
        _addLog('📋 Données: ${message.data}');
      });

      FirebaseMessaging.instance.getInitialMessage().then((
        RemoteMessage? message,
      ) {
        if (message != null) {
          _addLog('📨 App ouverte depuis notification: ${message.messageId}');
          _addLog('📋 Données: ${message.data}');
        }
      });

      _addLog('✅ Listeners configurés');
      _addLog(
        '💡 Envoyez une notification depuis Firebase Console pour tester',
      );
      setState(() {
        _testStatus = '✅ Listeners configurés - En attente de notification...';
      });
    } catch (e) {
      _addLog('❌ Erreur: $e');
      setState(() {
        _testStatus = '❌ Erreur: $e';
      });
      ErrorHelper.showError(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test 6: Tous les tests
  Future<void> _runAllTests() async {
    _addLog('🚀 Démarrage de tous les tests...');
    await _testFirebaseInitialization();
    await Future.delayed(const Duration(seconds: 1));
    await _testPermissions();
    await Future.delayed(const Duration(seconds: 1));
    await _testGetFCMToken();
    await Future.delayed(const Duration(seconds: 1));
    if (await SessionService.isAuthenticated()) {
      await _testRegisterToken();
    } else {
      _addLog('⚠️ Non authentifié - Test d\'enregistrement ignoré');
    }
    await Future.delayed(const Duration(seconds: 1));
    await _testNotificationReception();
    _addLog('✅ Tous les tests terminés');
  }

  String _getDeviceType() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'web';
  }

  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      return 'error-$e';
    }
    return 'unknown';
  }

  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications Push'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statut actuel
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testStatus.isEmpty ? 'Aucun test effectué' : _testStatus,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_fcmToken != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Token FCM:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Boutons de test individuels
            const Text(
              'Tests individuels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildTestButton(
              '1. Tester Firebase',
              Icons.cloud,
              Colors.blue,
              _testFirebaseInitialization,
            ),
            const SizedBox(height: 8),
            _buildTestButton(
              '2. Obtenir Token FCM',
              Icons.vpn_key,
              Colors.green,
              _testGetFCMToken,
            ),
            const SizedBox(height: 8),
            _buildTestButton(
              '3. Vérifier Permissions',
              Icons.security,
              Colors.orange,
              _testPermissions,
            ),
            const SizedBox(height: 8),
            _buildTestButton(
              '4. Enregistrer Token',
              Icons.cloud_upload,
              Colors.purple,
              _testRegisterToken,
            ),
            const SizedBox(height: 8),
            _buildTestButton(
              '5. Tester Réception',
              Icons.notifications_active,
              Colors.red,
              _testNotificationReception,
            ),

            const SizedBox(height: 24),

            // Bouton test complet
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runAllTests,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lancer tous les tests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Logs
            const Text(
              'Logs de test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child:
                  _testLogs.isEmpty
                      ? const Center(
                        child: Text(
                          'Aucun log pour le moment',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        reverse: true,
                        itemCount: _testLogs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _testLogs[index],
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Lancez tous les tests pour vérifier la configuration\n'
                      '2. Copiez le token FCM pour l\'utiliser dans Firebase Console\n'
                      '3. Testez l\'envoi depuis Firebase Console > Cloud Messaging\n'
                      '4. Vérifiez les logs ci-dessous pour voir les notifications reçues',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
