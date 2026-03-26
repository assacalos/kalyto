import 'dart:convert';
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/Models/task_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/storage_service.dart';

class TaskService {
  static final TaskService _instance = TaskService._();
  static TaskService get to => _instance;
  factory TaskService() => _instance;
  TaskService._();

  /// Liste des tâches en attente (ou tous si status null). Même approche que getBordereaux : liste puis comptage.
  Future<List<TaskModel>> getTasksList({String? status}) async {
    final result = await getTasks(
      status: status,
      page: 1,
      perPage: 500,
    );
    if (result['success'] != true) return [];
    final data = result['data'] as List?;
    if (data == null) return [];
    return List<TaskModel>.from(data);
  }

  /// Point d'entrée paginé : tâches (Patron/Admin voient tout, les autres les leurs).
  Future<PaginationResponse<TaskModel>> getTasksPaginated({
    int page = 1,
    int perPage = 20,
    int? assignedTo,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (assignedTo != null) queryParams['assigned_to'] = assignedTo.toString();
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/tasks-list').replace(
      queryParameters: queryParams,
    );

    final response = await RetryHelper.retryNetwork(
      operation: () => HttpInterceptor.get(uri, headers: ApiService.headers()).timeout(
            AppConfig.extraLongTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          ),
      maxRetries: AppConfig.defaultMaxRetries,
    );

    await AuthErrorHandler.handleHttpResponse(response);

    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(err?['message'] ?? 'Erreur chargement des tâches');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Erreur chargement des tâches (${response.statusCode})');
      }
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Réponse serveur invalide');
    }

    final res = PaginationHelper.parseResponseSafe<TaskModel>(
      json: data,
      fromJsonT: (json) {
        try {
          return TaskModel.fromJson(json);
        } catch (_) {
          return null;
        }
      },
    );
    if (res.data.isNotEmpty) _saveTachesToHive(res.data);
    return res;
  }

  /// Liste des tâches (format Map pour compatibilité). Délègue à getTasksPaginated.
  Future<Map<String, dynamic>> getTasks({
    int page = 1,
    int perPage = 20,
    int? assignedTo,
    String? status,
  }) async {
    final res = await getTasksPaginated(
      page: page,
      perPage: perPage,
      assignedTo: assignedTo,
      status: status,
    );
    return {
      'success': true,
      'data': res.data,
      'pagination': _normalizePagination(res.meta.toJson(), page),
    };
  }

  static int _toInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  static Map<String, dynamic> _normalizePagination(
    Map<String, dynamic> raw,
    int defaultPage,
  ) {
    return {
      'current_page': _toInt(raw['current_page'], defaultPage),
      'last_page': _toInt(raw['last_page'], 1),
      'per_page': _toInt(raw['per_page'], 20),
      'total': _toInt(raw['total'], 0),
    };
  }

  /// Détail d'une tâche
  Future<TaskModel> getTask(int id) async {
    final response = await HttpInterceptor.get(
      Uri.parse('$baseUrl/tasks-show/$id'),
      headers: ApiService.headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final taskData = data['data'] as Map<String, dynamic>?;
      if (taskData == null) throw Exception('Tâche non trouvée');
      return TaskModel.fromJson(taskData);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Erreur chargement de la tâche');
  }

  /// Créer / assigner une tâche (Patron ou Admin)
  Future<TaskModel> createTask({
    required String titre,
    String? description,
    required int assignedTo,
    String priority = 'medium',
    String? dueDate,
  }) async {
    final body = {
      'titre': titre,
      'description': description,
      'assigned_to': assignedTo,
      'priority': priority,
      if (dueDate != null && dueDate.isNotEmpty) 'due_date': dueDate,
    };
    final response = await HttpInterceptor.post(
      Uri.parse('$baseUrl/tasks-create'),
      headers: ApiService.headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final taskData = data['data'] as Map<String, dynamic>?;
      if (taskData == null) throw Exception('Réponse invalide');
      return TaskModel.fromJson(taskData);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? err['errors']?.toString() ?? 'Erreur création tâche');
  }

  /// Mettre à jour une tâche (Patron/Admin: tous champs; assigné: statut seulement)
  Future<TaskModel> updateTask(
    int id, {
    String? titre,
    String? description,
    int? assignedTo,
    String? status,
    String? priority,
    String? dueDate,
  }) async {
    final body = <String, dynamic>{};
    if (titre != null) body['titre'] = titre;
    if (description != null) body['description'] = description;
    if (assignedTo != null) body['assigned_to'] = assignedTo;
    if (status != null) body['status'] = status;
    if (priority != null) body['priority'] = priority;
    if (dueDate != null) body['due_date'] = dueDate;

    final response = await HttpInterceptor.put(
      Uri.parse('$baseUrl/tasks-update/$id'),
      headers: ApiService.headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final taskData = data['data'] as Map<String, dynamic>?;
      if (taskData == null) throw Exception('Réponse invalide');
      return TaskModel.fromJson(taskData);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? err['errors']?.toString() ?? 'Erreur mise à jour');
  }

  /// Mettre à jour uniquement le statut (pour l'assigné)
  Future<TaskModel> updateTaskStatus(int id, String status) async {
    return updateTask(id, status: status);
  }

  /// Supprimer une tâche (Patron ou Admin)
  Future<void> deleteTask(int id) async {
    final response = await HttpInterceptor.delete(
      Uri.parse('$baseUrl/tasks-destroy/$id'),
      headers: ApiService.headers(),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Erreur suppression');
    }
  }

  static void _saveTachesToHive(List<TaskModel> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyTaches,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des tâches pour affichage instantané.
  static List<TaskModel> getCachedTaches() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyTaches);
      return raw.map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}
