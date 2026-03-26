import 'dart:convert';
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/services/company_service.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._();
  static InvoiceService get to => _instance;
  factory InvoiceService() => _instance;
  InvoiceService._();

  // Créer une facture
  Future<Map<String, dynamic>> createInvoice({
    required int clientId,
    required String clientName,
    required String clientEmail,
    required String clientAddress,
    required int commercialId,
    required String commercialName,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<InvoiceItem> items,
    required double taxRate,
    String? notes,
    String? terms,
  }) async {
    try {
      // Calculer les montants
      final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      final taxAmount = subtotal * (taxRate / 100);
      final totalAmount = subtotal + taxAmount;

      final url = '${AppConfig.baseUrl}/factures-create';
      // Préparer les données à envoyer
      final requestData = {
        'client_id': clientId,
        'nom': clientName,
        'email': clientEmail,
        'adresse': clientAddress,
        'user_id': commercialId,
        'commercial_name': commercialName,
        'invoice_date': invoiceDate.toIso8601String(),
        'due_date': dueDate.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'tax_rate': taxRate,
        'tax_amount': taxAmount,
        'total_amount': totalAmount,
      };

      // Ajouter les champs optionnels seulement s'ils ne sont pas null
      if (notes != null && notes.isNotEmpty) {
        requestData['notes'] = notes;
      }
      if (terms != null && terms.isNotEmpty) {
        requestData['terms'] = terms;
      }

      AppLogger.httpRequest('POST', url, tag: 'INVOICE_SERVICE');
      AppLogger.debug(
        'Données de la facture à envoyer: $requestData',
        tag: 'INVOICE_SERVICE',
      );

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.post(
                  Uri.parse(url),
                  headers: ApiService.headers(),
                  body: jsonEncode(requestData),
                )
                .timeout(
                  AppConfig.defaultTimeout,
                  onTimeout: () =>
                      throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'INVOICE_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      // Gérer l'erreur 422 (Erreur de validation)
      if (response.statusCode == 422) {
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
            tag: 'INVOICE_SERVICE',
          );
          throw Exception(errorMessage);
        } catch (e) {
          // Si le parsing de l'erreur échoue, utiliser le message par défaut
          AppLogger.error(
            'Erreur 422 - Impossible de parser: ${response.body}',
            tag: 'INVOICE_SERVICE',
          );
          throw Exception(
            'Erreur de validation. Veuillez vérifier les données saisies.',
          );
        }
      }

      // Gérer différents formats de réponse
      try {
        final responseBody = json.decode(response.body);
        AppLogger.debug(
          'Réponse de création de facture: $responseBody',
          tag: 'INVOICE_SERVICE',
        );

        // Si la réponse contient directement les données de la facture
        if (responseBody is Map && responseBody.containsKey('id')) {
          return Map<String, dynamic>.from({
            'success': true,
            'data': responseBody,
            'message': 'Facture créée avec succès',
          });
        }

        // Si la réponse est au format standardisé
        if (responseBody is Map && responseBody.containsKey('success')) {
          return Map<String, dynamic>.from(responseBody);
        }

        // Si la réponse contient 'data'
        if (responseBody is Map && responseBody.containsKey('data')) {
          return Map<String, dynamic>.from({
            'success': true,
            'data': responseBody['data'],
            'message': responseBody['message'] ?? 'Facture créée avec succès',
          });
        }

        // Si la réponse contient 'facture' ou 'invoice'
        if (responseBody is Map &&
            (responseBody.containsKey('facture') ||
                responseBody.containsKey('invoice'))) {
          return Map<String, dynamic>.from({
            'success': true,
            'data': responseBody['facture'] ?? responseBody['invoice'],
            'message': 'Facture créée avec succès',
          });
        }

        // Format inattendu, retourner la réponse complète
        AppLogger.warning(
          'Format de réponse inattendu pour la création de facture: $responseBody',
          tag: 'INVOICE_SERVICE',
        );
        return Map<String, dynamic>.from({
          'success': true,
          'data': responseBody,
          'message': 'Facture créée avec succès',
        });
      } catch (e) {
        // Si le parsing échoue, essayer avec parseResponse
        final result = ApiService.parseResponse(response);

        if (result['success'] == true) {
          return result;
        } else {
          // Pour les autres erreurs, essayer d'extraire un message
          try {
            final errorData = json.decode(response.body);
            final message =
                errorData['message'] ??
                'Erreur lors de la création de la facture (${response.statusCode})';
            throw Exception(message);
          } catch (e2) {
            throw Exception(
              result['message'] ?? 'Erreur lors de la création de la facture',
            );
          }
        }
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Récupérer les factures d'un comptable
  Future<List<InvoiceModel>> getCommercialInvoices({
    required int commercialId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      String url = '${AppConfig.baseUrl}/factures-list';
      List<String> params = [];

      params.add('commercial_id=$commercialId');
      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (status != null) {
        params.add('status=$status');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'INVOICE_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'INVOICE_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        final List<dynamic> invoiceList =
            data is List ? data : (data['data'] ?? []);
        if (invoiceList.isEmpty) {
          return [];
        }

        final invoices = <InvoiceModel>[];
        for (var json in invoiceList) {
          try {
            final invoice = InvoiceModel.fromJson(json);
            invoices.add(invoice);
          } catch (e) {
            // Ignorer les erreurs de parsing individuelles
          }
        }
        return invoices;
      } else {
        throw Exception(
          result['message'] ??
              'Erreur lors de la récupération des factures commerciales',
        );
      }
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des factures commerciales: $e',
      );
    }
  }

  /// Point d'entrée unique pour la lecture : factures avec pagination.
  Future<PaginationResponse<InvoiceModel>> getInvoicesPaginated({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? commercialId,
    int? clientId,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (status != null) queryParams['status'] = status;
      if (commercialId != null) queryParams['commercial_id'] = commercialId.toString();
      if (clientId != null) queryParams['client_id'] = clientId.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      queryParams.addAll(CompanyService.companyQueryParam());

      final uri = Uri.parse('${AppConfig.baseUrl}/factures-list').replace(
        queryParameters: queryParams,
      );
      AppLogger.httpRequest('GET', uri.toString(), tag: 'INVOICE_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(uri, headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'INVOICE_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PaginationHelper.parseResponseSafe<InvoiceModel>(
          json: data,
          fromJsonT: (json) {
            try {
              return InvoiceModel.fromJson(json);
            } catch (_) {
              return null;
            }
          },
        );
        if (page == 1) _saveFacturesToHive(result.data, status, commercialId);
        return result;
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des factures: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getInvoicesPaginated: $e',
        tag: 'INVOICE_SERVICE',
      );
      rethrow;
    }
  }

  /// Récupère la première page (délégation vers getInvoicesPaginated pour compatibilité).
  Future<List<InvoiceModel>> getAllInvoices({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? commercialId,
    int? clientId,
  }) async {
    final res = await getInvoicesPaginated(
      startDate: startDate,
      endDate: endDate,
      status: status,
      commercialId: commercialId,
      clientId: clientId,
      page: 1,
      perPage: 500,
      search: null,
    );
    return res.data;
  }

  // Récupérer une facture par ID
  Future<InvoiceModel> getInvoiceById(int invoiceId) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/factures-show/$invoiceId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        final data = result['success'] == true ? result['data'] : null;
        return InvoiceModel.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération de la facture: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Mettre à jour une facture
  Future<Map<String, dynamic>> updateInvoice({
    required int invoiceId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await HttpInterceptor.put(
        Uri.parse('${AppConfig.baseUrl}/factures-update/$invoiceId'),
        headers: ApiService.headers(),
        body: jsonEncode(data),
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        return result['success'] == true ? (result['data'] ?? {}) : {};
      } else {
        throw Exception(
          'Erreur lors de la mise à jour de la facture: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Soumettre une facture au patron
  Future<Map<String, dynamic>> submitInvoiceToPatron(int invoiceId) async {
    try {
      // Route non disponible dans Laravel - utiliser factures-create à la place
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/factures-create'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        return result['success'] == true ? (result['data'] ?? {}) : {};
      } else {
        throw Exception(
          'Erreur lors de la soumission de la facture: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Approuver une facture (pour le patron)
  Future<Map<String, dynamic>> approveInvoice({
    required int invoiceId,
    String? comments,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/factures-validate/$invoiceId'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      // Si le status code est 200 ou 201, considérer comme succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = ApiService.parseResponse(response);
        // Si le parseResponse retourne success:false mais le status code est 200/201,
        // forcer success:true car le backend a validé
        if (result['success'] != true) {
          return {
            'success': true,
            'message': result['message'] ?? 'Facture approuvée avec succès',
            'data': result['data'],
          };
        }
        // Retourner le résultat complet avec la clé 'success'
        return result;
      } else {
        // Si le statut n'est pas 200/201, parser la réponse pour obtenir le message d'erreur
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message':
                errorData['message'] ??
                'Erreur lors de l\'approbation de la facture',
          };
        } catch (e) {
          throw Exception(
            'Erreur lors de l\'approbation de la facture: ${response.statusCode}',
          );
        }
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Rejeter une facture (pour le patron)
  Future<Map<String, dynamic>> rejectInvoice({
    required int invoiceId,
    required String reason,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/factures-reject/$invoiceId'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        // Retourner le résultat complet avec la clé 'success'
        return result;
      } else {
        // Si le statut n'est pas 200, parser la réponse pour obtenir le message d'erreur
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message':
                errorData['message'] ?? 'Erreur lors du rejet de la facture',
          };
        } catch (e) {
          throw Exception(
            'Erreur lors du rejet de la facture: ${response.statusCode}',
          );
        }
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Envoyer une facture par email
  Future<Map<String, dynamic>> sendInvoiceByEmail({
    required int invoiceId,
    required String email,
    String? message,
  }) async {
    try {
      // Route non disponible dans Laravel - utiliser factures-create à la place
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/factures-create'),
        headers: ApiService.headers(),
        body: jsonEncode({'email': email, 'message': message}),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        return result['success'] == true ? (result['data'] ?? {}) : {};
      } else {
        throw Exception(
          'Erreur lors de l\'envoi de la facture: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Marquer une facture comme payée
  Future<Map<String, dynamic>> markInvoiceAsPaid({
    required int invoiceId,
    required PaymentInfo paymentInfo,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/factures/$invoiceId/mark-paid'),
        headers: ApiService.headers(),
        body: jsonEncode(paymentInfo.toJson()),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        return result['success'] == true ? (result['data'] ?? {}) : {};
      } else {
        throw Exception(
          'Erreur lors du paiement de la facture: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Supprimer une facture
  Future<Map<String, dynamic>> deleteInvoice(int invoiceId) async {
    try {
      // Route de suppression non disponible dans Laravel
      final response = await HttpInterceptor.delete(
        Uri.parse('${AppConfig.baseUrl}/factures-update/$invoiceId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        return result['success'] == true ? (result['data'] ?? {}) : {};
      } else {
        throw Exception(
          'Erreur lors de la suppression de la facture: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Récupérer les statistiques de facturation
  Future<InvoiceStats> getInvoiceStats({
    DateTime? startDate,
    DateTime? endDate,
    int? commercialId,
  }) async {
    try {
      String url = '${AppConfig.baseUrl}/factures-reports';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (commercialId != null) {
        params.add('commercial_id=$commercialId');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'INVOICE_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'INVOICE_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        final data = result['success'] == true ? result['data'] : null;
        return InvoiceStats.fromJson(data);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Récupérer les factures en attente d'approbation (pour le patron)
  Future<List<InvoiceModel>> getPendingInvoices() async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/factures-list?status=pending'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        final data = result['success'] == true ? result['data'] : null;
        final List<dynamic> invoiceList = data['data'] ?? [];
        return invoiceList.map((json) => InvoiceModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des factures en attente: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Générer un numéro de facture
  Future<String> generateInvoiceNumber() async {
    try {
      // Route non disponible dans Laravel - générer côté client
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/factures-list'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        final data = result['success'] == true ? result['data'] : null;
        return data['invoice_number'];
      } else {
        throw Exception(
          'Erreur lors de la génération du numéro: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Récupérer les modèles de facture
  Future<List<InvoiceTemplate>> getInvoiceTemplates() async {
    try {
      // Route non disponible dans Laravel - utiliser factures-reports
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/factures-reports'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final result = ApiService.parseResponse(response);
        final data = result['success'] == true ? result['data'] : null;
        final List<dynamic> templateList = data['data'] ?? [];
        return templateList
            .map((json) => InvoiceTemplate.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des modèles: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      AppLogger.error(
        'Erreur lors de la création de la facture: $e',
        tag: 'INVOICE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Helper pour formater les noms de champs de manière lisible
  String _formatFieldName(String field) {
    // Traduire les noms de champs courants
    final translations = {
      'client_id': 'Client',
      'nom': 'Nom',
      'email': 'Email',
      'adresse': 'Adresse',
      'user_id': 'Utilisateur',
      'commercial_name': 'Commercial',
      'invoice_date': 'Date de facture',
      'due_date': 'Date d\'échéance',
      'items': 'Articles',
      'subtotal': 'Sous-total',
      'tax_rate': 'Taux de TVA',
      'tax_amount': 'Montant TVA',
      'total_amount': 'Montant total',
      'notes': 'Notes',
      'terms': 'Conditions',
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

  static void _saveFacturesToHive(List<InvoiceModel> list, [String? status, int? commercialId]) {
    try {
      final key = '${HiveStorageService.keyFactures}_${status ?? 'all'}_${commercialId ?? 'all'}';
      HiveStorageService.saveEntityList(
        key,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive (sync) : affichage instantané Cache-First.
  static List<InvoiceModel> getCachedFactures([String? status, int? commercialId]) {
    try {
      final key = '${HiveStorageService.keyFactures}_${status ?? 'all'}_${commercialId ?? 'all'}';
      final raw = HiveStorageService.getEntityList(key);
      if (raw.isNotEmpty) {
        return raw.map((e) => InvoiceModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      final fallback = HiveStorageService.getEntityList(HiveStorageService.keyFactures);
      return fallback.map((e) => InvoiceModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}
