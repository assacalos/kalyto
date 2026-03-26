import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/services/api_service.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/services/company_service.dart';

class BordereauService {
  final storage = GetStorage();

  /// Récupérer les bordereaux avec pagination côté serveur
  Future<PaginationResponse<Bordereau>> getBordereauxPaginated({
    int? status,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (status != null) queryParams['status'] = status.toString();
      if (userRole == 2 && userId != null) queryParams['user_id'] = userId.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      queryParams.addAll(CompanyService.companyQueryParam());

      final uri = HttpInterceptor.apiUri('bordereaux').replace(
        queryParameters: queryParams,
      );
      AppLogger.httpRequest('GET', uri.toString(), tag: 'BORDEREAU_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(uri).timeout(
                  AppConfig.extraLongTimeout,
                  onTimeout: () =>
                      throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        uri.toString(),
        tag: 'BORDEREAU_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paginatedResponse = PaginationHelper.parseResponseSafe<Bordereau>(
          json: data,
          fromJsonT: (json) {
            try {
              return Bordereau.fromJson(json);
            } catch (_) {
              return null;
            }
          },
        );
        if (page == 1) _saveBordereauxToHive(paginatedResponse.data, status);
        return paginatedResponse;
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des bordereaux: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getBordereauxPaginated: $e',
        tag: 'BORDEREAU_SERVICE',
      );
      rethrow;
    }
  }

  Future<List<Bordereau>> getBordereaux({int? status}) async {
    try {
      // OPTIMISATION : Vérifier le cache d'abord
      final cacheKey = 'bordereaux_${status ?? 'all'}';
      final cached = CacheHelper.get<List<Bordereau>>(cacheKey);
      if (cached != null) {
        AppLogger.debug('Using cached bordereaux', tag: 'BORDEREAU_SERVICE');
        return cached;
      }

      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString();
      if (userRole == 2) queryParams['user_id'] = userId.toString();
      queryParams.addAll(CompanyService.companyQueryParam());

      var uri = HttpInterceptor.apiUri('bordereaux-list');
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final url = uri.toString();
      AppLogger.httpRequest('GET', url, tag: 'BORDEREAU_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(uri).timeout(
                  AppConfig.extraLongTimeout,
                  onTimeout: () =>
                      throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'BORDEREAU_SERVICE',
      );

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Gérer le cas où les données sont directement dans un tableau
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData['data'] != null) {
          data = responseData['data'];
        } else {
          return [];
        }

        final List<Bordereau> bordereauList =
            data
                .map((json) {
                  try {
                    return Bordereau.fromJson(json);
                  } catch (e) {
                    return null;
                  }
                })
                .where((bordereau) => bordereau != null)
                .cast<Bordereau>()
                .toList();

        // Mettre en cache pour 5 minutes
        CacheHelper.set(
          cacheKey,
          bordereauList,
          duration: AppConfig.defaultCacheDuration,
        );
        _saveBordereauxToHive(bordereauList, null);

        return bordereauList;
      }

      throw Exception(
        'Erreur lors de la récupération des bordereaux: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des bordereaux: $e');
    }
  }

  Future<Bordereau> createBordereau(Bordereau bordereau) async {
    try {
      final bordereauJson = bordereau.toJson();

      CompanyService.addCompanyIdToBody(bordereauJson);
      // Logger les données envoyées pour le débogage
      AppLogger.debug(
        'Données du bordereau à envoyer: $bordereauJson',
        tag: 'BORDEREAU_SERVICE',
      );

      final uri = HttpInterceptor.apiUri('bordereaux-create');
      AppLogger.httpRequest('POST', uri.toString(), tag: 'BORDEREAU_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.post(
                  uri,
                  headers: ApiService.headers(),
                  body: json.encode(bordereauJson),
                )
                .timeout(
                  AppConfig.defaultTimeout,
                  onTimeout: () =>
                      throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        uri.toString(),
        tag: 'BORDEREAU_SERVICE',
      );

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          AppLogger.debug(
            'Bordereau créé, réponse: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}',
            tag: 'BORDEREAU_SERVICE',
          );

          // Gérer différents formats de réponse
          Map<String, dynamic> bordereauData;
          if (responseData is Map) {
            // Vérifier si la réponse contient une erreur mais aussi des données
            if (responseData['error'] != null && responseData['data'] != null) {
              // Le serveur a créé l'entité mais a rencontré une erreur secondaire
              // On considère quand même que la création a réussi
              AppLogger.warning(
                'Création réussie mais erreur secondaire détectée: ${responseData['error']}',
                tag: 'BORDEREAU_SERVICE',
              );
            }

            if (responseData['data'] != null) {
              bordereauData =
                  responseData['data'] is Map<String, dynamic>
                      ? responseData['data']
                      : Map<String, dynamic>.from(responseData['data']);
            } else if (responseData['bordereau'] != null) {
              bordereauData =
                  responseData['bordereau'] is Map<String, dynamic>
                      ? responseData['bordereau']
                      : Map<String, dynamic>.from(responseData['bordereau']);
            } else {
              bordereauData =
                  responseData is Map<String, dynamic>
                      ? responseData
                      : Map<String, dynamic>.from(responseData);
            }
          } else {
            throw Exception(
              'Format de réponse inattendu: ${responseData.runtimeType}',
            );
          }

          final createdBordereau = Bordereau.fromJson(bordereauData);

          if (createdBordereau.id == null) {
            AppLogger.error(
              'Bordereau créé mais sans ID',
              tag: 'BORDEREAU_SERVICE',
            );
            throw Exception(
              'Le bordereau a été créé mais sans ID. Veuillez réessayer.',
            );
          }

          AppLogger.info(
            'Bordereau créé: ID ${createdBordereau.id}',
            tag: 'BORDEREAU_SERVICE',
          );
          return createdBordereau;
        } catch (parseError) {
          // Si le parsing échoue mais que le status code est 201/200,
          // vérifier si on peut extraire un ID depuis la réponse brute
          try {
            final responseData = json.decode(response.body);
            if (responseData is Map && responseData['id'] != null) {
              AppLogger.warning(
                'Parsing partiel réussi, ID trouvé: ${responseData['id']}',
                tag: 'BORDEREAU_SERVICE',
              );
              // Essayer de construire un bordereau minimal avec l'ID
              final minimalBordereau = Bordereau.fromJson({
                'id': responseData['id'],
                ...bordereau.toJson(),
              });
              return minimalBordereau;
            }
          } catch (e) {
            // Ignorer
          }
          throw Exception('Erreur lors du parsing de la réponse: $parseError');
        }
      } else if (response.statusCode == 422) {
        // Gestion spécifique de l'erreur 422 (Erreur de validation)
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Erreur de validation';

          // Extraire le message principal
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }

          // Extraire les erreurs de validation par champ
          if (errorData['errors'] != null && errorData['errors'] is Map) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final List<String> validationErrors = [];

            errors.forEach((field, messages) {
              if (messages is List) {
                for (var msg in messages) {
                  validationErrors.add('${_formatFieldName(field)}: $msg');
                }
              } else {
                validationErrors.add('${_formatFieldName(field)}: $messages');
              }
            });

            if (validationErrors.isNotEmpty) {
              errorMessage = validationErrors.join('\n');
            }
          }

          AppLogger.error(
            'Erreur 422 - Validation: $errorMessage',
            tag: 'BORDEREAU_SERVICE',
          );
          throw Exception(errorMessage);
        } catch (e) {
          // Si le parsing de l'erreur échoue, utiliser le message par défaut
          AppLogger.error(
            'Erreur 422 - Impossible de parser: ${response.body}',
            tag: 'BORDEREAU_SERVICE',
          );
          throw Exception(
            'Erreur de validation. Veuillez vérifier les données saisies.',
          );
        }
      } else if (response.statusCode == 403) {
        // Gestion spécifique de l'erreur 403 (Accès refusé)
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message'] ?? 'Accès refusé';
          final requiredRoles = errorData['required_roles'] as List<dynamic>?;
          final userRole = errorData['user_role'];

          String errorMessage = message;
          if (requiredRoles != null && userRole != null) {
            final rolesNames = requiredRoles
                .map(
                  (r) => Roles.getRoleName(
                    r is int ? r : int.tryParse(r.toString()),
                  ),
                )
                .join(', ');

            final userRoleName = Roles.getRoleName(
              userRole is int ? userRole : int.tryParse(userRole.toString()),
            );

            errorMessage =
                '$message\n\nRôles requis: $rolesNames\nVotre rôle: $userRoleName';
          }

          throw Exception(errorMessage);
        } catch (e) {
          // Si le parsing de l'erreur échoue, utiliser le message par défaut
          throw Exception(
            'Accès refusé (403). Vous n\'avez pas les permissions pour créer un bordereau. Vérifiez vos droits d\'accès avec l\'administrateur.',
          );
        }
      }

      // Si c'est une erreur 401, elle a déjà été gérée
      if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else if (response.statusCode == 500) {
        AppLogger.warning(
          'Erreur 500 reçue: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}',
          tag: 'BORDEREAU_SERVICE',
        );
        try {
          final errorData = json.decode(response.body);
          AppLogger.debug(
            'Données parsées erreur 500: $errorData',
            tag: 'BORDEREAU_SERVICE',
          );

          // Chercher un ID dans différents emplacements possibles
          int? bordereauId;
          Map<String, dynamic>? bordereauData;

          if (errorData is Map) {
            // Chercher dans data.bordereau.id ou data.id
            if (errorData['data'] != null && errorData['data'] is Map) {
              final data = errorData['data'] as Map;
              if (data['bordereau'] != null && data['bordereau'] is Map) {
                final bordereauObj = data['bordereau'] as Map;
                if (bordereauObj['id'] != null) {
                  bordereauId =
                      bordereauObj['id'] is int
                          ? bordereauObj['id']
                          : int.tryParse(bordereauObj['id'].toString());
                  bordereauData = Map<String, dynamic>.from(bordereauObj);
                }
              } else if (data['id'] != null) {
                bordereauId =
                    data['id'] is int
                        ? data['id']
                        : int.tryParse(data['id'].toString());
                bordereauData = Map<String, dynamic>.from(data);
              }
            }
            // Chercher directement dans la racine
            else if (errorData['bordereau'] != null &&
                errorData['bordereau'] is Map) {
              final bordereauObj = errorData['bordereau'] as Map;
              if (bordereauObj['id'] != null) {
                bordereauId =
                    bordereauObj['id'] is int
                        ? bordereauObj['id']
                        : int.tryParse(bordereauObj['id'].toString());
                bordereauData = Map<String, dynamic>.from(bordereauObj);
              }
            }
            // Chercher directement l'ID à la racine
            else if (errorData['id'] != null) {
              bordereauId =
                  errorData['id'] is int
                      ? errorData['id']
                      : int.tryParse(errorData['id'].toString());
              bordereauData = Map<String, dynamic>.from(errorData);
            }
          }

          if (bordereauId != null) {
            AppLogger.warning(
              'Erreur 500 mais bordereau créé avec ID: $bordereauId',
              tag: 'BORDEREAU_SERVICE',
            );

            // Construire un bordereau avec les données disponibles ou minimal
            if (bordereauData != null) {
              try {
                final bordereau = Bordereau.fromJson(bordereauData);
                return bordereau;
              } catch (e) {
                AppLogger.warning(
                  'Parsing partiel échoué, construction minimale: $e',
                  tag: 'BORDEREAU_SERVICE',
                );
              }
            }

            final minimalBordereau = Bordereau.fromJson({
              'id': bordereauId,
              ...bordereau.toJson(),
            });
            return minimalBordereau;
          } else {
            AppLogger.debug(
              'Aucun ID trouvé dans l\'erreur 500',
              tag: 'BORDEREAU_SERVICE',
            );
          }
        } catch (e) {
          AppLogger.warning(
            'Erreur lors de la vérification de l\'ID dans l\'erreur 500: $e',
            tag: 'BORDEREAU_SERVICE',
          );
        }

        try {
          await Future.delayed(const Duration(milliseconds: 500));
          final reference = bordereau.reference;
          AppLogger.debug(
            'Recherche du bordereau par référence: $reference',
            tag: 'BORDEREAU_SERVICE',
          );

          try {
            // Invalider le cache pour forcer un rafraîchissement
            CacheHelper.clearByPrefix('bordereaux_');

            // Chercher dans les bordereaux récents (sans cache)
            final userRole = storage.read('userRole');
            final userId = storage.read('userId');

            var queryParams = <String, String>{};
            if (userRole == 2) queryParams['user_id'] = userId.toString();
            queryParams['search'] = reference; // Rechercher par référence

            Uri searchUri = HttpInterceptor.apiUri('bordereaux-list');
            if (queryParams.isNotEmpty) {
              searchUri = searchUri.replace(queryParameters: queryParams);
            }
            final searchUrl = searchUri.toString();

            AppLogger.debug(
              'Recherche via: $searchUrl',
              tag: 'BORDEREAU_SERVICE',
            );

            final searchResponse = await HttpInterceptor.get(searchUri);

            if (searchResponse.statusCode == 200) {
              final searchData = json.decode(searchResponse.body);
              List<dynamic> data;
              if (searchData is List) {
                data = searchData;
              } else if (searchData['data'] != null) {
                data =
                    searchData['data'] is List
                        ? searchData['data']
                        : [searchData['data']];
              } else {
                data = [];
              }

              // Chercher le bordereau avec la référence exacte
              for (var jsonItem in data) {
                try {
                  final b = Bordereau.fromJson(jsonItem);
                  if (b.reference == reference) {
                    AppLogger.info(
                      'Bordereau trouvé après erreur 500: ID ${b.id}',
                      tag: 'BORDEREAU_SERVICE',
                    );
                    return b;
                  }
                } catch (e) {
                  // Ignorer les erreurs de parsing
                }
              }

              AppLogger.debug(
                'Bordereau non trouvé dans les résultats de recherche',
                tag: 'BORDEREAU_SERVICE',
              );
            } else {
              AppLogger.warning(
                'Erreur lors de la recherche: ${searchResponse.statusCode}',
                tag: 'BORDEREAU_SERVICE',
              );
            }
          } catch (e) {
            AppLogger.warning(
              'Erreur lors de la recherche: $e',
              tag: 'BORDEREAU_SERVICE',
            );
          }
        } catch (e) {
          AppLogger.warning(
            'Erreur lors de la vérification: $e',
            tag: 'BORDEREAU_SERVICE',
          );
        }

        try {
          final errorData = json.decode(response.body);
          final message =
              errorData['message'] ??
              'Erreur serveur lors de la création du bordereau (500)';
          AppLogger.error(
            'Message d\'erreur 500: $message',
            tag: 'BORDEREAU_SERVICE',
          );
          throw Exception(message);
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
            'Erreur serveur lors de la création du bordereau (500)',
          );
        }
      } else {
        // Pour les autres erreurs, essayer d'extraire un message
        try {
          final errorData = json.decode(response.body);
          final message =
              errorData['message'] ??
              'Erreur lors de la création du bordereau (${response.statusCode})';
          throw Exception(message);
        } catch (e) {
          throw Exception(
            'Erreur lors de la création du bordereau: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      rethrow;
    }
  }

  Future<Bordereau> updateBordereau(Bordereau bordereau) async {
    try {
      final response = await HttpInterceptor.put(
        HttpInterceptor.apiUri('bordereaux-update/${bordereau.id}'),
        headers: ApiService.headers(),
        body: json.encode(bordereau.toJson()),
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        return Bordereau.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la mise à jour du bordereau');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du bordereau');
    }
  }

  Future<bool> deleteBordereau(int bordereauId) async {
    try {
      final response = await HttpInterceptor.delete(
        HttpInterceptor.apiUri('bordereaux-delete/$bordereauId'),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitBordereau(int bordereauId) async {
    try {
      final response = await HttpInterceptor.post(
        HttpInterceptor.apiUri('bordereaux/$bordereauId/submit'),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> approveBordereau(int bordereauId) async {
    try {
      final response = await HttpInterceptor.post(
        HttpInterceptor.apiUri('bordereaux-validate/$bordereauId'),
      );

      // Si le status code est 200 ou 201, considérer comme succès
      // (même si le body dit success:false, le backend a peut-être validé quand même)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 500) {
        // Erreur 500 : vérifier si le bordereau a quand même été validé
        try {
          final responseData = json.decode(response.body);
          // Si le message contient "validé" ou "approuvé", considérer comme succès
          final message =
              (responseData['message'] ?? '').toString().toLowerCase();
          if (message.contains('validé') ||
              message.contains('approuvé') ||
              message.contains('validated') ||
              message.contains('approved')) {
            return true;
          }
        } catch (e) {
          // Ignorer l'erreur de parsing
        }
        throw Exception('Erreur serveur lors de la validation');
      } else {
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur lors de la validation';
        throw Exception('Erreur ${response.statusCode}: $message');
      }
    } catch (e) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  Future<bool> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      // Essayer d'abord la route avec le format /bordereaux/{id}/reject
      final body = {'commentaire': commentaire};
      final bodyJson = json.encode(body);

      dynamic response;
      try {
        response = await HttpInterceptor.post(
          HttpInterceptor.apiUri('bordereaux/$bordereauId/reject'),
          headers: ApiService.headers(),
          body: bodyJson,
        );
      } catch (e) {
        // Si la première route échoue, essayer l'ancienne route
        response = await HttpInterceptor.post(
          HttpInterceptor.apiUri('bordereaux-reject/$bordereauId'),
          headers: ApiService.headers(),
          body: bodyJson,
        );
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return true;
        } else {
          return false;
        }
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors du rejet';
        throw Exception('Erreur serveur: $message');
      } else {
        final responseData = json.decode(response.body);
        final message = responseData['message'] ?? 'Erreur lors du rejet';
        throw Exception('Erreur ${response.statusCode}: $message');
      }
    } catch (e) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  Future<Map<String, dynamic>> getBordereauStats() async {
    try {
      final response = await HttpInterceptor.get(
        HttpInterceptor.apiUri('bordereaux/stats'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception('Erreur lors de la récupération des statistiques');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }

  // Helper pour formater les noms de champs de manière lisible
  String _formatFieldName(String field) {
    // Traduire les noms de champs courants
    final translations = {
      'client_id': 'Client',
      'devis_id': 'Devis',
      'reference': 'Référence',
      'items': 'Articles',
      'date_creation': 'Date de création',
      'notes': 'Notes',
      'status': 'Statut',
      'user_id': 'Utilisateur',
      'commercial_id': 'Commercial',
    };

    // Si on a une traduction, l'utiliser
    if (translations.containsKey(field)) {
      return translations[field]!;
    }

    // Sinon, formater le nom du champ (remplacer _ par des espaces et capitaliser)
    return field
        .split('_')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  static void _saveBordereauxToHive(List<Bordereau> list, int? status) {
    try {
      final key = '${HiveStorageService.keyBordereaux}_${status ?? 'all'}';
      HiveStorageService.saveEntityList(
        key,
        list.map((e) => e.toJson()).toList(),
      );
      AppLogger.debug(
        'Hive: Mise à jour cache bordereaux (statut ${status ?? 'all'}), ${list.length} élément(s)',
        tag: 'BORDEREAU_SERVICE',
      );
    } catch (e) {
      AppLogger.warning('Hive: Erreur sauvegarde bordereaux: $e', tag: 'BORDEREAU_SERVICE');
    }
  }

  /// Expose pour le contrôleur : sauvegarder la liste en Hive (après création locale).
  static void saveBordereauxToHive(List<Bordereau> list, int? status) {
    _saveBordereauxToHive(list, status);
  }

  /// Invalide le cache Hive des bordereaux (tous les statuts) après création/validation/rejet.
  static Future<void> clearBordereauxHiveCache() async {
    try {
      final keys = [
        '${HiveStorageService.keyBordereaux}_all',
        '${HiveStorageService.keyBordereaux}_1',
        '${HiveStorageService.keyBordereaux}_2',
        '${HiveStorageService.keyBordereaux}_3',
      ];
      for (final key in keys) {
        await HiveStorageService.clearEntity(key);
      }
      AppLogger.debug('Hive: cache bordereaux invalidé', tag: 'BORDEREAU_SERVICE');
    } catch (e) {
      AppLogger.warning('Hive: erreur invalidation cache bordereaux: $e', tag: 'BORDEREAU_SERVICE');
    }
  }

  /// Cache Hive (sync) : affichage instantané Cache-First.
  static List<Bordereau> getCachedBordereaux([int? status]) {
    try {
      final key = '${HiveStorageService.keyBordereaux}_${status ?? 'all'}';
      final raw = HiveStorageService.getEntityList(key);
      if (raw.isNotEmpty) {
        return raw.map((e) => Bordereau.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (status != null) return [];
      final fallback = HiveStorageService.getEntityList(HiveStorageService.keyBordereaux);
      return fallback.map((e) => Bordereau.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}
