import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/storage_service.dart';

class SupplierService {
  static final SupplierService _instance = SupplierService._();
  static SupplierService get to => _instance;
  factory SupplierService() => _instance;
  SupplierService._();

  final storage = GetStorage();

  // Récupérer tous les fournisseurs
  Future<List<Supplier>> getSuppliers({String? status, String? search}) async {
    try {
      final token = storage.read('token');
      var queryParams = <String, String>{};
      if (status != null && status != 'all') {
        // Normaliser le statut vers le format backend
        String backendStatus = status;
        if (status == 'pending') backendStatus = 'en_attente';
        if (status == 'approved' || status == 'validated')
          backendStatus = 'valide';
        if (status == 'rejected') backendStatus = 'rejete';
        queryParams['statut'] = backendStatus;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '$baseUrl/fournisseurs-list$queryString';
      
      // Si le status code est 200 ou 201, traiter directement
      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          
          // Essayer différents formats de réponse
          List<dynamic> data = [];

          if (responseData['data'] != null) {
            if (responseData['data'] is List) {
              data = responseData['data'];
            } else if (responseData['data'] is Map && responseData['data']['data'] != null) {
              data = responseData['data']['data'];
            }
          } else if (responseData['fournisseurs'] != null) {
            if (responseData['fournisseurs'] is List) {
              data = responseData['fournisseurs'];
            }
          } else if (responseData is List) {
            data = responseData;
          } else {
            return [];
          }

          if (data.isEmpty) {
            return [];
          }

          try {
            final suppliers =
                data.map((json) => Supplier.fromJson(json)).toList();
            _saveFournisseursToHive(suppliers);
            return suppliers;
          } catch (e) {
            return [];
          }
        } catch (e) {
          return [];
        }
      }
      
      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);
      
      return [];
    } catch (e) {
      return [];
    }
  }

  // Récupérer un fournisseur par ID
  Future<Supplier> getSupplierById(int id) async {
    final token = storage.read('token');
    final response = await HttpInterceptor.get(
      Uri.parse('$baseUrl/fournisseurs-show/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return Supplier.fromJson(responseData['data']);
    }

    throw Exception(
      'Erreur lors de la récupération du fournisseur: ${response.statusCode}',
    );
  }

  // Créer un fournisseur
  Future<Supplier> createSupplier(Supplier supplier) async {
    // Validation des champs requis
    if (supplier.nom.isEmpty) {
      throw Exception('Le nom du fournisseur est requis');
    }
    if (supplier.email.isEmpty) {
      throw Exception('L\'email est requis');
    }
    if (supplier.telephone.isEmpty) {
      throw Exception('Le téléphone est requis');
    }
    if (supplier.adresse.isEmpty) {
      throw Exception('L\'adresse est requise');
    }
    if (supplier.ville.isEmpty) {
      throw Exception('La ville est requise');
    }
    if (supplier.pays.isEmpty) {
      throw Exception('Le pays est requis');
    }

    final token = storage.read('token');
    final supplierData = supplier.toJson();
    final response = await http
        .post(
          Uri.parse('$baseUrl/fournisseurs-create'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(supplierData),
        )
        .timeout(
          AppConfig.defaultTimeout,
          onTimeout: () =>
              throw Exception('Timeout: le serveur ne répond pas'),
        );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return Supplier.fromJson(responseData['data'] ?? responseData);
    }

    // Afficher les détails de l'erreur
    final errorBody = response.body;
    throw Exception(
      'Erreur lors de la création du fournisseur: ${response.statusCode} - $errorBody',
    );
  }

  // Mettre à jour un fournisseur
  Future<Supplier> updateSupplier(Supplier supplier) async {
    final token = storage.read('token');
    final response = await http
        .put(
          Uri.parse('$baseUrl/fournisseurs-update/${supplier.id}'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(supplier.toJson()),
        )
        .timeout(
          AppConfig.defaultTimeout,
          onTimeout: () =>
              throw Exception('Timeout: le serveur ne répond pas'),
        );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return Supplier.fromJson(responseData['data']);
    }

    throw Exception(
      'Erreur lors de la mise à jour du fournisseur: ${response.statusCode}',
    );
  }

  // Supprimer un fournisseur (soft delete)
  Future<bool> deleteSupplier(int supplierId) async {
    final token = storage.read('token');
    final response = await HttpInterceptor.delete(
      Uri.parse('$baseUrl/fournisseurs-destroy/$supplierId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Récupérer les statistiques
  Future<SupplierStats> getSupplierStats() async {
    final token = storage.read('token');
    final response = await HttpInterceptor.get(
      Uri.parse('$baseUrl/fournisseurs-stats'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return SupplierStats.fromJson(responseData['data']);
    }

    throw Exception(
      'Erreur lors de la récupération des statistiques: ${response.statusCode}',
    );
  }

  // Récupérer les fournisseurs en attente
  Future<List<Supplier>> getPendingSuppliers() async {
    final token = storage.read('token');
    final response = await HttpInterceptor.get(
      Uri.parse('$baseUrl/fournisseurs-list?statut=pending'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'] ?? [];
      return data.map((json) => Supplier.fromJson(json)).toList();
    }

    throw Exception(
      'Erreur lors de la récupération des fournisseurs en attente: ${response.statusCode}',
    );
  }

  // Valider un fournisseur
  Future<bool> approveSupplier(
    int supplierId, {
    String? validationComment,
  }) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/fournisseurs-validate/$supplierId';
      final body = {
        if (validationComment != null && validationComment.isNotEmpty)
          'validation_comment': validationComment,
      };

      AppLogger.httpRequest('POST', url, tag: 'SUPPLIER_SERVICE');
      AppLogger.debug(
        'Validation du fournisseur $supplierId avec commentaire: ${validationComment ?? 'aucun'}',
        tag: 'SUPPLIER_SERVICE',
      );

      final response = await HttpInterceptor.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'SUPPLIER_SERVICE');

      // Si le status code est 200 ou 201, considérer comme succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Invalider le cache après validation
        CacheHelper.clearByPrefix('suppliers_');
        AppLogger.info(
          'Fournisseur $supplierId validé avec succès (status: ${response.statusCode})',
          tag: 'SUPPLIER_SERVICE',
        );
        return true;
      }
      
      // Gérer les erreurs d'authentification seulement si ce n'est pas un succès
      // (mais ne pas bloquer pour les erreurs 500 qui peuvent indiquer un succès)
      if (response.statusCode != 500) {
        await AuthErrorHandler.handleHttpResponse(response);
      }
      
      if (response.statusCode == 500) {
        // Erreur 500 : vérifier si le fournisseur a quand même été validé
        AppLogger.warning(
          'Erreur 500 lors de la validation du fournisseur $supplierId. Vérification si la validation a réussi...',
          tag: 'SUPPLIER_SERVICE',
        );
        try {
          final responseData = json.decode(response.body);
          AppLogger.debug(
            'Réponse 500: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
            tag: 'SUPPLIER_SERVICE',
          );
          
          // Si le message contient "validé" ou "approuvé", considérer comme succès
          final message = (responseData['message'] ?? '').toString().toLowerCase();
          if (message.contains('validé') || message.contains('approuvé') || 
              message.contains('validated') || message.contains('approved')) {
            CacheHelper.clearByPrefix('suppliers_');
            AppLogger.warning(
              'Fournisseur $supplierId validé malgré l\'erreur 500 (message contient "validé")',
              tag: 'SUPPLIER_SERVICE',
            );
            return true;
          }
          // Vérifier si le body contient un ID de fournisseur validé
          if (responseData['data'] != null) {
            final data = responseData['data'];
            if (data is Map && (data['id'] != null || data['supplier_id'] != null)) {
              CacheHelper.clearByPrefix('suppliers_');
              AppLogger.warning(
                'Fournisseur $supplierId validé malgré l\'erreur 500 (ID trouvé dans la réponse)',
                tag: 'SUPPLIER_SERVICE',
              );
              return true;
            }
          }
          
          // Vérifier si le fournisseur a été validé en le récupérant depuis le serveur
          try {
            await Future.delayed(const Duration(milliseconds: 500));
            final suppliers = await getSuppliers();
            final updatedSupplier = suppliers.firstWhere(
              (s) => s.id == supplierId,
              orElse: () => throw Exception('Fournisseur non trouvé'),
            );
            
            // Si le statut a changé (plus en attente), considérer comme succès
            if (!updatedSupplier.isPending && updatedSupplier.isValidated) {
              CacheHelper.clearByPrefix('suppliers_');
              AppLogger.warning(
                'Fournisseur $supplierId validé malgré l\'erreur 500 (statut changé à validé)',
                tag: 'SUPPLIER_SERVICE',
              );
              return true;
            } else if (updatedSupplier.statusText.toLowerCase().contains('validé') || 
                       updatedSupplier.statusText.toLowerCase().contains('validated') ||
                       updatedSupplier.statusText.toLowerCase().contains('approved')) {
              // Si status_text indique "Validé", considérer comme succès même si statut est null ou vide
              CacheHelper.clearByPrefix('suppliers_');
              AppLogger.warning(
                'Fournisseur $supplierId validé malgré l\'erreur 500 (status_text="Validé")',
                tag: 'SUPPLIER_SERVICE',
              );
              return true;
            }
          } catch (e) {
            // Erreur silencieuse lors de la vérification
          }
        } catch (e) {
          AppLogger.error(
            'Erreur lors du parsing de la réponse 500: $e',
            tag: 'SUPPLIER_SERVICE',
          );
        }
        // Si pas de succès détecté, lancer une exception
        try {
          final responseData = json.decode(response.body);
          final message =
              responseData['message'] ?? 'Erreur serveur lors de la validation';
          AppLogger.error(
            'Erreur serveur lors de la validation du fournisseur $supplierId: $message',
            tag: 'SUPPLIER_SERVICE',
          );
          throw Exception('Erreur serveur: $message');
        } catch (e) {
          AppLogger.error(
            'Erreur serveur lors de la validation du fournisseur $supplierId',
            tag: 'SUPPLIER_SERVICE',
          );
          throw Exception('Erreur serveur lors de la validation');
        }
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        try {
          final responseData = json.decode(response.body);
          final message =
              responseData['message'] ?? 'Ce fournisseur ne peut pas être validé';
          AppLogger.error(
            'Erreur 400 lors de la validation du fournisseur $supplierId: $message',
            tag: 'SUPPLIER_SERVICE',
          );
          throw Exception(message);
        } catch (e) {
          AppLogger.error(
            'Erreur 400 lors de la validation du fournisseur $supplierId',
            tag: 'SUPPLIER_SERVICE',
          );
          throw Exception('Ce fournisseur ne peut pas être validé');
        }
      }
      AppLogger.warning(
        'Status code inattendu lors de la validation du fournisseur $supplierId: ${response.statusCode}',
        tag: 'SUPPLIER_SERVICE',
      );
      return false;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la validation du fournisseur $supplierId: $e',
        tag: 'SUPPLIER_SERVICE',
      );
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Rejeter un fournisseur
  Future<bool> rejectSupplier(
    int supplierId, {
    required String rejectionReason,
    String? rejectionComment,
  }) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/fournisseurs-reject/$supplierId';
      final body = {
        'rejection_reason': rejectionReason,
        if (rejectionComment != null && rejectionComment.isNotEmpty)
          'rejection_comment': rejectionComment,
      };

      final response = await HttpInterceptor.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Vérifier si la réponse contient success == true
        if (responseData is Map && responseData['success'] == true) {
          return true;
        }
        // Si pas de champ success, considérer 200 comme succès
        return true;
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Ce fournisseur ne peut pas être rejeté';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors du rejet';
        throw Exception('Erreur serveur: $message');
      }
      return false;
    } catch (e) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Évaluer un fournisseur
  Future<bool> rateSupplier(
    int supplierId,
    double rating, {
    String? comments,
  }) async {
    final token = storage.read('token');
    final response = await HttpInterceptor.post(
      Uri.parse('$baseUrl/fournisseurs-rate/$supplierId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'rating': rating, 'comments': comments}),
    );

    return response.statusCode == 200;
  }

  // Soumettre un fournisseur
  Future<bool> submitSupplier(int supplierId) async {
    final token = storage.read('token');
    final response = await HttpInterceptor.post(
      Uri.parse('$baseUrl/fournisseurs-submit/$supplierId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static void _saveFournisseursToHive(List<Supplier> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyFournisseurs,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des fournisseurs pour affichage instantané.
  static List<Supplier> getCachedFournisseurs() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyFournisseurs);
      return raw.map((e) => Supplier.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}
