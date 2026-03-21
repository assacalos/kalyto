import 'package:easyconnect/services/http_interceptor.dart';
import 'dart:convert';
import 'package:easyconnect/Models/besoin_model.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';

class BesoinService {
  String get _baseUrl => AppConfig.baseUrl;

  Future<List<Besoin>> getBesoins({String? status, int page = 1, int perPage = 50}) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse('$_baseUrl/besoins-list').replace(queryParameters: params);
    final response = await HttpInterceptor.get(uri, headers: ApiService.headers());
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    final list = data['data'] as List<dynamic>? ?? [];
    final besoins = list.map((e) => Besoin.fromJson(e as Map<String, dynamic>)).toList();
    if (besoins.isNotEmpty) _saveBesoinsToHive(besoins, status);
    return besoins;
  }

  static void _saveBesoinsToHive(List<Besoin> list, [String? status]) {
    try {
      final key = '${HiveStorageService.keyBesoins}_${status ?? 'all'}';
      HiveStorageService.saveEntityList(key, list.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  /// Cache Hive (sync) : affichage instantané Cache-First.
  static List<Besoin> getCachedBesoins([String? status]) {
    try {
      final key = '${HiveStorageService.keyBesoins}_${status ?? 'all'}';
      final raw = HiveStorageService.getEntityList(key);
      if (raw.isNotEmpty) {
        return raw.map((e) => Besoin.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (status != null) return [];
      final fallback = HiveStorageService.getEntityList(HiveStorageService.keyBesoins);
      return fallback.map((e) => Besoin.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Besoin> getBesoin(int id) async {
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl/besoins-show/$id'),
      headers: ApiService.headers(),
    );
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 200) throw Exception('Besoin introuvable');
    final data = jsonDecode(response.body);
    return Besoin.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Besoin> createBesoin({
    required String title,
    String? description,
    required String reminderFrequency,
  }) async {
    final response = await HttpInterceptor.post(
      Uri.parse('$_baseUrl/besoins-create'),
      headers: ApiService.headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'reminder_frequency': reminderFrequency,
      }),
    );
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 201) {
      final msg = (jsonDecode(response.body) as Map?)?['message'] ?? response.body;
      throw Exception(msg);
    }
    final data = jsonDecode(response.body);
    return Besoin.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Besoin> markTreated(int id, {String? treatedNote}) async {
    final body = <String, dynamic>{};
    if (treatedNote != null && treatedNote.isNotEmpty) body['treated_note'] = treatedNote;
    final response = await HttpInterceptor.post(
      Uri.parse('$_baseUrl/besoins-mark-treated/$id'),
      headers: ApiService.headers(),
      body: jsonEncode(body),
    );
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 200) throw Exception('Erreur lors du traitement');
    final data = jsonDecode(response.body);
    return Besoin.fromJson(data['data'] as Map<String, dynamic>);
  }
}
