import 'dart:convert';
import 'dart:io';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/company_service.dart';

class ApiService {
  // -------------------- HEADERS --------------------
  /// Génère les headers HTTP standardisés pour toutes les requêtes API
  /// Utilise SessionService pour récupérer le token de manière centralisée
  /// Version synchrone pour compatibilité avec le code existant
  static Map<String, String> headers({bool jsonContent = true}) {
    final token = SessionService.getTokenSync();
    final map = <String, String>{
      'Accept': 'application/json',
      // ⚠️ User-Agent minimal pour contourner Tiger Protect
      // On garde seulement l'essentiel comme curl
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    if (jsonContent) map['Content-Type'] = 'application/json';
    return map;
  }

  /// Version asynchrone avec rafraîchissement automatique du token
  /// À utiliser pour les nouvelles requêtes qui nécessitent un token valide
  static Future<Map<String, String>> headersAsync({
    bool jsonContent = true,
  }) async {
    // S'assurer que le token est valide avant la requête
    await SessionService.ensureValidToken();

    final token = await SessionService.getToken();
    final map = <String, String>{
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    if (jsonContent) map['Content-Type'] = 'application/json';
    return map;
  }

  // -------------------- AUTH --------------------
  /// Sur le web, récupère le cookie CSRF auprès de Laravel Sanctum avant toute requête stateful (login, etc.).
  /// Sans cet appel, le navigateur n'a pas le cookie XSRF-TOKEN et Laravel renvoie "CSRF token mismatch".
  static Future<void> _ensureCsrfCookieIfWeb() async {
    if (!kIsWeb) return;
    try {
      final csrfUrl = '${AppConfig.baseUrlWithoutApi}/sanctum/csrf-cookie';
      await http.get(Uri.parse(csrfUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('CSRF cookie timeout'),
      );
    } catch (_) {
      // En cas d'échec, le login échouera avec une erreur explicite
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      await _ensureCsrfCookieIfWeb();

      final url = "$baseUrl/login";
      final requestHeaders = headers();
      final requestBody = jsonEncode({"email": email, "password": password});

      final response = await http
          .post(Uri.parse(url), headers: requestHeaders, body: requestBody)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Timeout: Le serveur ne répond pas dans les 30 secondes',
              );
            },
          );

      return parseResponse(response);
    } on SocketException {
      return {
        "success": false,
        "message":
            "Impossible de se connecter au serveur. Vérifiez votre connexion internet.",
        "errorType": "network",
        "statusCode": null,
      };
    } on HttpException catch (e) {
      return {
        "success": false,
        "message": "Erreur HTTP: ${e.message}",
        "errorType": "http",
        "statusCode": null,
      };
    } on FormatException {
      return {
        "success": false,
        "message": "Erreur de format de réponse du serveur",
        "errorType": "format",
        "statusCode": null,
      };
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('certificate') ||
          errorString.contains('ssl') ||
          errorString.contains('tls') ||
          errorString.contains('handshake')) {
        return {
          "success": false,
          "message":
              "Erreur de certificat SSL. Le serveur peut avoir un problème de certificat.",
          "errorType": "ssl",
          "statusCode": null,
        };
      }

      return {
        "success": false,
        "message": e.toString(),
        "errorType": "unknown",
        "statusCode": null,
      };
    }
  }

  /// Inscription publique (sans token). Compte créé en attente de validation par le patron.
  /// Si [photo] est fourni, la requête est envoyée en multipart pour inclure le fichier.
  static Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String passwordConfirmation,
    File? photo,
  }) async {
    try {
      await _ensureCsrfCookieIfWeb();

      final url = '$baseUrl/register';

      if (photo != null) {
        final request = http.MultipartRequest('POST', Uri.parse(url));
        final h = headers();
        h.remove('Content-Type');
        request.headers.addAll(h);
        request.fields['nom'] = nom;
        request.fields['prenom'] = prenom;
        request.fields['email'] = email;
        request.fields['password'] = password;
        request.fields['password_confirmation'] = passwordConfirmation;
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () =>
              throw Exception('Le serveur ne répond pas. Réessayez.'),
        );
        final response = await http.Response.fromStream(streamedResponse);
        return parseResponse(response);
      }

      final body = jsonEncode({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      final response = await http
          .post(Uri.parse(url), headers: headers(), body: body)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Le serveur ne répond pas. Réessayez.'),
          );
      return parseResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: headers(),
      );
      final result = parseResponse(response);
      return result;
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // -------------------- USERS --------------------
  static Future<Map<String, dynamic>> getUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/users'), headers: headers());
    return parseResponse(res);
  }

  /// Récupère les données de l'utilisateur connecté
  static Future<Map<String, dynamic>> getUser() async {
    final res = await http.get(Uri.parse('$baseUrl/user'), headers: headers());
    return parseResponse(res);
  }

  /// Met à jour le profil de l'utilisateur connecté (nom, prénom, email).
  /// Retourne les données utilisateur mises à jour dans [data].
  static Future<Map<String, dynamic>> updateUserProfile({
    required String nom,
    required String prenom,
    required String email,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/user-profile'),
        headers: headers(),
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'email': email,
        }),
      );
      return parseResponse(res);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Met à jour la photo de profil (avatar) de l'utilisateur connecté.
  /// Retourne les données utilisateur mises à jour dans [data].
  static Future<Map<String, dynamic>> updateProfilePhoto(File photo) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user-profile-photo'),
      );
      final h = headers();
      h.remove('Content-Type');
      request.headers.addAll(h);
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Le serveur ne répond pas. Réessayez.'),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return parseResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserRole(int id, int role) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: headers(),
      body: jsonEncode({'role': role}),
    );
    return parseResponse(res);
  }

  /// Liste des inscriptions en attente (patron/admin)
  static Future<Map<String, dynamic>> getPendingRegistrations() async {
    final h = await headersAsync();
    final res = await http.get(
      Uri.parse('$baseUrl/users-pending-registrations'),
      headers: h,
    );
    return parseResponse(res);
  }

  /// Valider une inscription : attribuer le rôle, optionnellement la société, et activer le compte.
  /// Si l'appelant est le Patron, le backend utilise sa société ; companyId est ignoré.
  /// Si l'appelant est l'Admin, companyId (optionnel) assigne l'utilisateur à cette société.
  static Future<Map<String, dynamic>> approveRegistration(int id, int role, {int? companyId}) async {
    final h = await headersAsync();
    final body = <String, dynamic>{'role': role};
    if (companyId != null) body['company_id'] = companyId;
    final res = await http.post(
      Uri.parse('$baseUrl/users-approve-registration/$id'),
      headers: h,
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  /// Rejeter une inscription (supprime le compte en attente)
  static Future<Map<String, dynamic>> rejectRegistration(int id) async {
    final h = await headersAsync();
    final res = await http.post(
      Uri.parse('$baseUrl/users-reject-registration/$id'),
      headers: h,
    );
    return parseResponse(res);
  }

  // -------------------- CLIENTS --------------------
  static Future<Map<String, dynamic>> getClients() async {
    final q = CompanyService.companyQueryParam();
    final uri = Uri.parse('$baseUrl/clients').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> createClient(Map data) async {
    final body = Map<String, dynamic>.from(data);
    CompanyService.addCompanyIdToBody(body);
    final res = await http.post(
      Uri.parse('$baseUrl/clients'),
      headers: headers(),
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> updateClient(int id, Map data) async {
    final body = Map<String, dynamic>.from(data);
    CompanyService.addCompanyIdToBody(body);
    final res = await http.put(
      Uri.parse('$baseUrl/clients/$id'),
      headers: headers(),
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> deleteClient(int id) async {
    final q = CompanyService.companyQueryParam();
    final uri = Uri.parse('$baseUrl/clients/$id').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.delete(uri, headers: headers());
    return parseResponse(res);
  }

  // -------------------- QUOTES --------------------
  static Future<Map<String, dynamic>> getQuotes() async {
    final q = CompanyService.companyQueryParam();
    final uri = Uri.parse('$baseUrl/quotes').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> createQuote(Map data) async {
    final body = Map<String, dynamic>.from(data);
    CompanyService.addCompanyIdToBody(body);
    final res = await http.post(
      Uri.parse('$baseUrl/quotes'),
      headers: headers(),
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  // -------------------- INVOICES --------------------
  static Future<Map<String, dynamic>> getInvoices() async {
    final q = CompanyService.companyQueryParam();
    final uri = Uri.parse('$baseUrl/invoices').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  // -------------------- JOURNAL (entrées / sorties) --------------------
  /// Journal avec solde initial, lignes, solde final. Query: mois, annee ou date_debut, date_fin.
  static Future<Map<String, dynamic>> getJournal({int? mois, int? annee, String? dateDebut, String? dateFin}) async {
    final q = <String, String>{}..addAll(CompanyService.companyQueryParam());
    if (mois != null && annee != null) {
      q['mois'] = '$mois';
      q['annee'] = '$annee';
    } else if (dateDebut != null && dateFin != null) {
      q['date_debut'] = dateDebut;
      q['date_fin'] = dateFin;
    }
    final uri = Uri.parse('$baseUrl/journal').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  /// Balance comptable par compte (plan de comptes).
  /// Query: date_debut, date_fin ou mois, annee.
  static Future<Map<String, dynamic>> getBalance({
    int? mois,
    int? annee,
    String? dateDebut,
    String? dateFin,
  }) async {
    final q = <String, String>{}..addAll(CompanyService.companyQueryParam());
    if (mois != null && annee != null) {
      q['mois'] = '$mois';
      q['annee'] = '$annee';
    } else if (dateDebut != null && dateFin != null) {
      q['date_debut'] = dateDebut;
      q['date_fin'] = dateFin;
    }
    final uri = Uri.parse('$baseUrl/balance').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  /// Liste paginée des écritures (pour édition / suppression).
  static Future<Map<String, dynamic>> getJournalList({int? mois, int? annee, String? dateDebut, String? dateFin, int page = 1, int perPage = 50}) async {
    final q = <String, String>{}..addAll(CompanyService.companyQueryParam());
    q['page'] = '$page';
    q['per_page'] = '$perPage';
    if (mois != null && annee != null) {
      q['mois'] = '$mois';
      q['annee'] = '$annee';
    } else if (dateDebut != null && dateFin != null) {
      q['date_debut'] = dateDebut;
      q['date_fin'] = dateFin;
    }
    final uri = Uri.parse('$baseUrl/journal-list').replace(queryParameters: q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> getJournalShow(int id) async {
    final q = CompanyService.companyQueryParam();
    final uri = Uri.parse('$baseUrl/journal-show/$id').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> journalCreate(Map<String, dynamic> data) async {
    final body = Map<String, dynamic>.from(data);
    CompanyService.addCompanyIdToBody(body);
    final res = await http.post(
      Uri.parse('$baseUrl/journal-create'),
      headers: headers(),
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> journalUpdate(int id, Map<String, dynamic> data) async {
    final body = Map<String, dynamic>.from(data);
    CompanyService.addCompanyIdToBody(body);
    final res = await http.put(
      Uri.parse('$baseUrl/journal-update/$id'),
      headers: headers(),
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> journalDestroy(int id) async {
    final q = CompanyService.companyQueryParam();
    final uri = Uri.parse('$baseUrl/journal-destroy/$id').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.delete(uri, headers: headers());
    return parseResponse(res);
  }

  // -------------------- INVENTAIRE PHYSIQUE --------------------
  /// GET /api/inventory-sessions — Liste des sessions d'inventaire
  static Future<Map<String, dynamic>> getInventorySessions({int? page, int? perPage}) async {
    final q = <String, String>{}..addAll(CompanyService.companyQueryParam());
    if (page != null) q['page'] = '$page';
    if (perPage != null) q['per_page'] = '$perPage';
    final uri = Uri.parse('$baseUrl/inventory-sessions').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  /// POST /api/inventory-sessions — Créer une session
  static Future<Map<String, dynamic>> createInventorySession({String? date, String? depot}) async {
    final body = <String, dynamic>{};
    if (date != null) body['date'] = date;
    if (depot != null) body['depot'] = depot;
    CompanyService.addCompanyIdToBody(body);
    final res = await http.post(
      Uri.parse('$baseUrl/inventory-sessions'),
      headers: headers(),
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  /// GET /api/inventory-sessions/:id — Détail d'une session
  static Future<Map<String, dynamic>> getInventorySession(int id) async {
    final q = CompanyService.companyQueryParam();
    final uri = Uri.parse('$baseUrl/inventory-sessions/$id').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  /// GET /api/inventory-sessions/:id/lines — Lignes d'une session
  static Future<Map<String, dynamic>> getInventoryLines(int sessionId) async {
    final q = CompanyService.companyQueryParam();
    final uri = Uri.parse('$baseUrl/inventory-sessions/$sessionId/lines').replace(queryParameters: q.isEmpty ? null : q);
    final res = await http.get(uri, headers: headers());
    return parseResponse(res);
  }

  /// POST /api/inventory-sessions/:id/lines — Ajouter des lignes (à partir du référentiel stock)
  static Future<Map<String, dynamic>> addInventoryLines(int sessionId, {List<int>? stockIds}) async {
    final body = <String, dynamic>{};
    if (stockIds != null) body['stock_ids'] = stockIds;
    CompanyService.addCompanyIdToBody(body);
    final res = await http.post(
      Uri.parse('$baseUrl/inventory-sessions/$sessionId/lines'),
      headers: headers(),
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  /// PATCH /api/inventory-sessions/:id/lines/:lineId — Mettre à jour la quantité comptée
  static Future<Map<String, dynamic>> updateInventoryLineCounted(
    int sessionId,
    int lineId,
    double countedQty,
  ) async {
    final body = <String, dynamic>{'counted_qty': countedQty};
    CompanyService.addCompanyIdToBody(body);
    final res = await http.patch(
      Uri.parse('$baseUrl/inventory-sessions/$sessionId/lines/$lineId'),
      headers: headers(),
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  /// POST /api/inventory-sessions/:id/close — Clôturer l'inventaire
  static Future<Map<String, dynamic>> closeInventorySession(int sessionId) async {
    final body = <String, dynamic>{};
    CompanyService.addCompanyIdToBody(body);
    final res = await http.post(
      Uri.parse('$baseUrl/inventory-sessions/$sessionId/close'),
      headers: headers(),
      body: jsonEncode(body),
    );
    return parseResponse(res);
  }

  // -------------------- PARSE --------------------
  /// Parse la réponse HTTP selon le format standardisé de l'API
  /// Format standardisé:
  /// - Succès: {"success": true, "message": "...", "data": {...}}
  /// - Erreur: {"success": false, "message": "...", "errors": {...}}
  ///
  /// IMPORTANT: Vérifie les erreurs HTTP (4xx, 5xx) AVANT de décoder le JSON
  /// pour éviter les exceptions lors du décodage de réponses d'erreur non-JSON
  static Map<String, dynamic> parseResponse(http.Response res) {
    try {
      // 1. Vérifier le status code AVANT tout décodage
      final statusCode = res.statusCode;

      // 2. Gérer le rate limiting (429) avant le parsing
      if (statusCode == 429) {
        return {
          "success": false,
          "message": "Trop de requêtes. Veuillez réessayer plus tard.",
          "statusCode": 429,
        };
      }

      // 3. Gérer les erreurs HTTP (4xx, 5xx) AVANT le décodage JSON
      if (statusCode >= 400) {
        return _handleHttpError(res, statusCode);
      }

      // 3.5. Mettre à jour l'activité utilisateur pour les requêtes réussies (2xx)
      // Cela évite la déconnexion automatique pendant l'utilisation normale de l'app
      if (statusCode >= 200 && statusCode < 300) {
        SessionService.updateLastActivity();
      }

      // 4. Pour les succès (2xx), décoder le JSON en UTF-8 (évite Ã© au lieu de é)
      Map<String, dynamic> body = {};

      if (res.bodyBytes.isNotEmpty) {
        try {
          body = jsonDecode(utf8.decode(res.bodyBytes));
        } catch (e) {
          // Si le décodage échoue même pour un succès, retourner une erreur
          return {
            "success": false,
            "message": "Format de réponse invalide du serveur (JSON invalide)",
            "statusCode": statusCode,
            "rawBody":
                res.bodyBytes.length > 200
                    ? "${utf8.decode(res.bodyBytes).substring(0, 200)}..."
                    : utf8.decode(res.bodyBytes),
          };
        }
      }

      // 5. Vérifier si la réponse suit le format standardisé
      final hasStandardFormat = body.containsKey('success');

      // 6. Traiter les réponses de succès (2xx)
      if (hasStandardFormat) {
        if (body['success'] == true) {
          // Succès: extraire les données de 'data'
          return {
            "success": true,
            "data": body['data'],
            "message": body['message'] ?? "Opération réussie",
          };
        } else {
          // Erreur dans une réponse 2xx (ne devrait pas arriver mais géré)
          return {
            "success": false,
            "message": body['message'] ?? "Erreur inconnue",
            "errors": body['errors'],
          };
        }
      } else {
        // Format non standardisé (rétrocompatibilité)
        if (body.containsKey('data')) {
          return {"success": true, "data": body['data']};
        } else if (body.containsKey('user') && body.containsKey('token')) {
          // Format direct avec user et token (ancien format login)
          return {
            "success": true,
            "data": {"user": body['user'], "token": body['token']},
          };
        } else {
          // Retourner le body tel quel
          return {"success": true, "data": body};
        }
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Erreur de traitement de la réponse: $e",
      };
    }
  }

  /// Gère les erreurs HTTP (4xx, 5xx) en essayant de décoder le JSON
  /// seulement si le body semble être du JSON valide
  static Map<String, dynamic> _handleHttpError(
    http.Response res,
    int statusCode,
  ) {
    String errorMessage = _getDefaultErrorMessage(statusCode);
    Map<String, dynamic>? errors;

    if (res.bodyBytes.isEmpty) {
      return {
        "success": false,
        "message": errorMessage,
        "errors": errors,
        "statusCode": statusCode,
      };
    }

    final bodyStr = utf8.decode(res.bodyBytes);
    final trimmedBody = bodyStr.trim();
    final isLikelyJson =
        trimmedBody.startsWith('{') ||
        trimmedBody.startsWith('[') ||
        trimmedBody.startsWith('"');

    if (isLikelyJson) {
      try {
        final body = jsonDecode(bodyStr);

          // Format standardisé
          if (body is Map && body.containsKey('success')) {
            errorMessage = body['message']?.toString() ?? errorMessage;
            errors = body['errors'];
          } else if (body is Map) {
            // Format non standardisé (rétrocompatibilité)
            if (body.containsKey('message')) {
              errorMessage = body['message'].toString();
            } else if (body.containsKey('error')) {
              errorMessage = body['error'].toString();
            } else if (body.containsKey('errors')) {
              // Erreurs de validation Laravel
              final validationErrors = body['errors'];
              if (validationErrors is Map) {
                errors = Map<String, dynamic>.from(validationErrors);
                final firstError = validationErrors.values.first;
                if (firstError is List && firstError.isNotEmpty) {
                  errorMessage = firstError.first.toString();
                } else if (firstError is String) {
                  errorMessage = firstError;
                }
              }
            }
          }
        } catch (e) {
          // Si le décodage échoue, utiliser le message d'erreur par défaut
          // Ne pas propager l'erreur de décodage
          errorMessage = _getDefaultErrorMessage(statusCode);
        }
      } else {
        // Le body n'est pas du JSON (peut être du HTML, du texte, etc.)
        // Utiliser le message d'erreur par défaut basé sur le status code
        errorMessage = _getDefaultErrorMessage(statusCode);
      }

    return {
      "success": false,
      "message": errorMessage,
      "errors": errors,
      "statusCode": statusCode,
    };
  }

  /// Retourne un message d'erreur par défaut basé sur le code de statut HTTP
  static String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return "Requête invalide";
      case 401:
        return "Non autorisé. Veuillez vous reconnecter.";
      case 403:
        return "Accès refusé. Vous n'avez pas les permissions nécessaires.";
      case 404:
        return "Ressource non trouvée";
      case 405:
        return "Méthode non autorisée";
      case 422:
        return "Erreur de validation des données";
      case 429:
        return "Trop de requêtes. Veuillez réessayer plus tard.";
      case 500:
        return "Erreur interne du serveur Laravel. Vérifiez les logs du serveur (storage/logs/laravel.log) pour plus de détails.";
      case 502:
        return "Erreur de passerelle. Le serveur est temporairement indisponible.";
      case 503:
        return "Service indisponible. Le serveur est en maintenance ou temporairement inaccessible.";
      case 504:
        return "Timeout de la passerelle. Le serveur ne répond pas.";
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return "Erreur client ($statusCode)";
        } else if (statusCode >= 500) {
          return "Erreur serveur ($statusCode)";
        } else {
          return "Erreur HTTP ($statusCode)";
        }
    }
  }
}
