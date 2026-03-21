import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';

class BonDeCommandeFournisseurService {
  final storage = GetStorage();

  Future<List<BonDeCommande>> getBonDeCommandes({
    int? status,
    int? clientId,
    int? fournisseurId,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString();
      if (clientId != null) queryParams['client_id'] = clientId.toString();
      if (fournisseurId != null)
        queryParams['fournisseur_id'] = fournisseurId.toString();
      if (userRole == 2) queryParams['user_id'] = userId.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';
      final url = '$baseUrl/bons-de-commande-list$queryString';
      AppLogger.httpRequest('GET', url, tag: 'BON_COMMANDE_FOURNISSEUR_SERVICE');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            AppConfig.extraLongTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'BON_COMMANDE_FOURNISSEUR_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      // Utiliser ApiService.parseResponse pour gérer le format standardisé
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        try {
          final responseData = result['data'];

          // Gérer différents formats de réponse
          List<dynamic> data;
          if (responseData is List) {
            data = responseData;
          } else if (responseData is Map<String, dynamic>) {
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data'] is Map &&
                  responseData['data']['data'] != null &&
                  responseData['data']['data'] is List) {
                data = responseData['data']['data'];
              } else {
                data = [responseData['data']];
              }
            } else if (responseData['bon_de_commandes'] != null) {
              if (responseData['bon_de_commandes'] is List) {
                data = responseData['bon_de_commandes'];
              } else {
                data = [responseData['bon_de_commandes']];
              }
            } else if (responseData['bon_de_commande'] != null) {
              data = [responseData['bon_de_commande']];
            } else {
              return [];
            }
          } else {
            return [];
          }

          final List<BonDeCommande> bonDeCommandeList =
              data
                  .map((json) {
                    try {
                      return BonDeCommande.fromJson(json);
                    } catch (e) {
                      return null;
                    }
                  })
                  .where((bonDeCommande) => bonDeCommande != null)
                  .cast<BonDeCommande>()
                  .toList();

          // Filtrer pour ne garder que les bons de commande fournisseur
          // (ceux qui ont un fournisseur_id et pas de client_id)
          final List<BonDeCommande> filteredList =
              bonDeCommandeList
                  .where(
                    (bonDeCommande) =>
                        bonDeCommande.fournisseurId != null &&
                        bonDeCommande.clientId == null,
                  )
                  .toList();

          return filteredList;
        } catch (e) {
          throw Exception('Erreur lors du parsing des bons de commande: $e');
        }
      }

      throw Exception(
        result['message'] ??
            'Erreur lors de la récupération des bons de commande',
      );
    } catch (e) {
      AppLogger.error(
        'getBonDeCommandes: $e',
        tag: 'BON_COMMANDE_FOURNISSEUR_SERVICE',
      );
      rethrow;
    }
  }

  Future<BonDeCommande> createBonDeCommande(BonDeCommande bonDeCommande) async {
    try {
      final token = storage.read('token');

      final bonDeCommandeJson = bonDeCommande.toJsonForCreate();

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/bons-de-commande-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bonDeCommandeJson),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Gérer différents formats de réponse
          Map<String, dynamic> bonDeCommandeData;
          if (responseData is Map) {
            if (responseData['bon_de_commande'] != null) {
              bonDeCommandeData =
                  responseData['bon_de_commande'] is Map<String, dynamic>
                      ? responseData['bon_de_commande']
                      : Map<String, dynamic>.from(
                        responseData['bon_de_commande'],
                      );
            } else if (responseData['data'] != null) {
              bonDeCommandeData =
                  responseData['data'] is Map<String, dynamic>
                      ? responseData['data']
                      : Map<String, dynamic>.from(responseData['data']);
            } else {
              bonDeCommandeData =
                  responseData is Map<String, dynamic>
                      ? responseData
                      : Map<String, dynamic>.from(responseData);
            }
          } else {
            throw Exception(
              'Format de réponse inattendu: ${responseData.runtimeType}',
            );
          }

          return BonDeCommande.fromJson(bonDeCommandeData);
        } catch (parseError) {
          throw Exception('Erreur lors du parsing de la réponse: $parseError');
        }
      } else if (response.statusCode == 403) {
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message'] ?? 'Accès refusé';
          throw Exception(message);
        } catch (e) {
          throw Exception(
            'Accès refusé (403). Vous n\'avez pas les permissions pour créer un bon de commande.',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception(
          'Non autorisé (401). Votre session a peut-être expiré. Veuillez vous reconnecter.',
        );
      } else if (response.statusCode == 422) {
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Erreur de validation';

          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorMessages = <String>[];

            errors.forEach((field, messages) {
              if (messages is List) {
                errorMessages.addAll(messages.map((m) => '$field: $m'));
              } else {
                errorMessages.add('$field: $messages');
              }
            });

            errorMessage = errorMessages.join('\n');
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }

          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && e.toString().contains('Erreur de validation')) {
            rethrow;
          }
          throw Exception(
            'Erreur de validation (422). Veuillez vérifier les données saisies.',
          );
        }
      } else if (response.statusCode == 500) {
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Erreur serveur (500)';

          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          } else if (errorData['errors'] != null) {
            if (errorData['errors'] is Map) {
              final errors = errorData['errors'] as Map<String, dynamic>;
              errorMessage = errors.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n');
            } else {
              errorMessage = errorData['errors'].toString();
            }
          }

          throw Exception('Erreur serveur: $errorMessage');
        } catch (e) {
          if (e is Exception && e.toString().contains('Erreur serveur')) {
            rethrow;
          }
          throw Exception('Erreur serveur (500). Détails: ${response.body}');
        }
      } else {
        throw Exception(
          'Erreur lors de la création du bon de commande: ${response.statusCode}\nRéponse: ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<BonDeCommande> updateBonDeCommande(
    int id,
    BonDeCommande bonDeCommande,
  ) async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/bons-de-commande-update/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bonDeCommande.toJsonForCreate()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Map<String, dynamic> bonDeCommandeData;

        if (responseData['bon_de_commande'] != null) {
          bonDeCommandeData =
              responseData['bon_de_commande'] is Map<String, dynamic>
                  ? responseData['bon_de_commande']
                  : Map<String, dynamic>.from(responseData['bon_de_commande']);
        } else if (responseData['data'] != null) {
          bonDeCommandeData =
              responseData['data'] is Map<String, dynamic>
                  ? responseData['data']
                  : Map<String, dynamic>.from(responseData['data']);
        } else {
          bonDeCommandeData =
              responseData is Map<String, dynamic>
                  ? responseData
                  : Map<String, dynamic>.from(responseData);
        }

        return BonDeCommande.fromJson(bonDeCommandeData);
      }
      throw Exception('Erreur lors de la mise à jour du bon de commande');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du bon de commande');
    }
  }

  Future<bool> deleteBonDeCommande(int bonDeCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/bons-de-commande-destroy/$bonDeCommandeId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<BonDeCommande> getBonDeCommande(int id) async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/bons-de-commande-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Map<String, dynamic> bonDeCommandeData;

        if (responseData['bon_de_commande'] != null) {
          bonDeCommandeData =
              responseData['bon_de_commande'] is Map<String, dynamic>
                  ? responseData['bon_de_commande']
                  : Map<String, dynamic>.from(responseData['bon_de_commande']);
        } else if (responseData['data'] != null) {
          bonDeCommandeData =
              responseData['data'] is Map<String, dynamic>
                  ? responseData['data']
                  : Map<String, dynamic>.from(responseData['data']);
        } else {
          bonDeCommandeData =
              responseData is Map<String, dynamic>
                  ? responseData
                  : Map<String, dynamic>.from(responseData);
        }

        return BonDeCommande.fromJson(bonDeCommandeData);
      }
      throw Exception('Erreur lors de la récupération du bon de commande');
    } catch (e) {
      throw Exception('Erreur lors de la récupération du bon de commande: $e');
    }
  }

  // Valider/Approuver un bon de commande
  Future<bool> validateBonDeCommande(int bonDeCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/bons-de-commande-validate/$bonDeCommandeId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Si le status code est 200 ou 201, considérer comme succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      // Vérifier le body même si le status code n'est pas 200/201
      try {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return true;
        }
      } catch (e) {
        // Ignorer l'erreur de parsing
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Rejeter un bon de commande
  Future<bool> rejectBonDeCommande(
    int bonDeCommandeId,
    String commentaire,
  ) async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/bons-de-commande-reject/$bonDeCommandeId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'commentaire': commentaire}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
