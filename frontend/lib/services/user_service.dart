import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';

class UserService {
  final storage = GetStorage();

  /// Récupérer les utilisateurs avec pagination côté serveur
  Future<PaginationResponse<UserModel>> getUsersPaginated({
    int page = 1,
    int perPage = 15,
    String? search,
    int? role,
  }) async {
    try {
      String url = '${AppConfig.baseUrl}/users';
      List<String> params = [];

      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      if (role != null) {
        params.add('role=$role');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'USER_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'USER_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginationHelper.parseResponse<UserModel>(
          json: data,
          fromJsonT: (json) => UserModel.fromJson(json),
        );
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des utilisateurs: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Erreur dans getUsersPaginated: $e', tag: 'USER_SERVICE');
      rethrow;
    }
  }

  /// Récupérer tous les utilisateurs
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/users-list'),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          return data.map((json) => UserModel.fromJson(json)).toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => UserModel.fromJson(json))
              .toList();
        }
        return [];
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération des utilisateurs',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  /// Récupérer un utilisateur par ID
  Future<UserModel> getUserById(int id) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/users-show/$id'),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        return UserModel.fromJson(data);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération de l\'utilisateur',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  /// Créer un nouvel utilisateur
  Future<UserModel> createUser(UserModel user, [String? password]) async {
    try {
      // Préparer les données à envoyer
      final userData = user.toJson();
      if (password != null) {
        userData['password'] = password;
      }
      // S'assurer que is_active est inclus
      userData['is_active'] = user.isActive;

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/users-create'),
        headers: ApiService.headers(),
        body: json.encode(userData),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        return UserModel.fromJson(data);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la création de l\'utilisateur',
      );
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  /// Mettre à jour un utilisateur
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/users-update/${user.id}'),
        headers: ApiService.headers(),
        body: json.encode(user.toJson()),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        return UserModel.fromJson(data);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la mise à jour de l\'utilisateur',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }

  /// Supprimer un utilisateur
  Future<bool> deleteUser(int id) async {
    try {
      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/users-delete/$id'),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Activer/Désactiver un utilisateur
  Future<bool> toggleUserStatus(int id, bool isActive) async {
    try {
      final response = await HttpInterceptor.patch(
        Uri.parse('$baseUrl/users-status/$id'),
        headers: ApiService.headers(),
        body: json.encode({'is_active': isActive}),
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les statistiques des utilisateurs
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/users-stats'),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération des statistiques',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}
