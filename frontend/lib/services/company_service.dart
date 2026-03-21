import 'dart:typed_data';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easyconnect/Models/company_model.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/services/api_service.dart';

/// Service pour la société courante (multi-société).
/// La société sélectionnée est persistée localement et envoyée aux APIs quand disponible.
/// Logo et signature (PDF) : chargés depuis l'API par société.
class CompanyService {
  static final _storage = GetStorage();
  static const String _currentCompanyIdKey = 'current_company_id';

  static final Map<int, Uint8List> _logoBytesCache = {};
  static final Map<int, Uint8List> _signatureBytesCache = {};

  /// ID de la société courante (null = non défini ou mode mono-société).
  static int? getCurrentCompanyId() {
    final v = _storage.read<dynamic>(_currentCompanyIdKey);
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Définit la société courante (persistée).
  static Future<void> setCurrentCompanyId(int? id) async {
    if (id == null) {
      await _storage.remove(_currentCompanyIdKey);
    } else {
      await _storage.write(_currentCompanyIdKey, id);
    }
  }

  /// Paramètre de requête à merger : company_id si une société est sélectionnée.
  static Map<String, String> companyQueryParam() {
    final id = getCurrentCompanyId();
    if (id == null) return {};
    return {'company_id': id.toString()};
  }

  /// Clé à inclure dans un body JSON : company_id si une société est sélectionnée.
  static void addCompanyIdToBody(Map<String, dynamic> body) {
    final id = getCurrentCompanyId();
    if (id != null) body['company_id'] = id;
  }

  /// Liste des sociétés (depuis l'API GET /api/companies). Retourne une liste vide en cas d'erreur.
  static Future<List<Company>> getCompanies() async {
    try {
      final res = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/companies'),
        headers: ApiService.headers(),
      );
      final data = ApiService.parseResponse(res);
      if (data['success'] == true && data['data'] != null) {
        final list = data['data'] is List ? data['data'] as List : [];
        return list
            .map((e) => Company.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      // Pas de fallback : on retourne une liste vide
    }
    return [];
  }

  /// Logo de la société (pour PDF). Retourne null si pas de société ou pas de logo.
  static Future<Uint8List?> getCompanyLogoBytes(int? companyId) async {
    if (companyId == null) return null;
    if (_logoBytesCache.containsKey(companyId)) return _logoBytesCache[companyId];
    final list = await getCompanies();
    final filtered = list.where((c) => c.id == companyId).toList();
    if (filtered.isEmpty || (filtered.first.logoUrl ?? '').isEmpty) return null;
    final c = filtered.first;
    try {
      final res = await HttpInterceptor.get(
        Uri.parse(c.logoUrl!),
        headers: ApiService.headers(),
      );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _logoBytesCache[companyId] = res.bodyBytes;
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  /// Signature de la société (pour PDF). Retourne null si pas de société ou pas de signature.
  static Future<Uint8List?> getCompanySignatureBytes(int? companyId) async {
    if (companyId == null) return null;
    if (_signatureBytesCache.containsKey(companyId)) return _signatureBytesCache[companyId];
    final list = await getCompanies();
    final filtered = list.where((c) => c.id == companyId).toList();
    if (filtered.isEmpty || (filtered.first.signatureUrl ?? '').isEmpty) return null;
    final c = filtered.first;
    try {
      final res = await HttpInterceptor.get(
        Uri.parse(c.signatureUrl!),
        headers: ApiService.headers(),
      );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _signatureBytesCache[companyId] = res.bodyBytes;
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  /// Invalide le cache logo/signature pour une société (après upload).
  static void invalidateCompanyAssetsCache(int? companyId) {
    if (companyId == null) return;
    _logoBytesCache.remove(companyId);
    _signatureBytesCache.remove(companyId);
  }

  /// Envoie le logo de la société (pour les PDF). [imageFile] vient de image_picker.
  static Future<Map<String, dynamic>> uploadCompanyLogo(int companyId, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/companies/$companyId/logo'),
      );
      final h = ApiService.headers();
      h.remove('Content-Type');
      request.headers.addAll(h);
      final ext = imageFile.name.split('.').last.toLowerCase();
      if (ext.isEmpty || !['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext)) {
        request.files.add(http.MultipartFile.fromBytes('logo', bytes, filename: 'logo.png'));
      } else {
        request.files.add(http.MultipartFile.fromBytes('logo', bytes, filename: 'logo.$ext'));
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = ApiService.parseResponse(response);
      if (data['success'] == true) invalidateCompanyAssetsCache(companyId);
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Envoie la signature de la société (pour les PDF). [imageFile] vient de image_picker.
  static Future<Map<String, dynamic>> uploadCompanySignature(int companyId, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/companies/$companyId/signature'),
      );
      final h = ApiService.headers();
      h.remove('Content-Type');
      request.headers.addAll(h);
      final ext = imageFile.name.split('.').last.toLowerCase();
      if (ext.isEmpty || !['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext)) {
        request.files.add(http.MultipartFile.fromBytes('signature', bytes, filename: 'signature.png'));
      } else {
        request.files.add(http.MultipartFile.fromBytes('signature', bytes, filename: 'signature.$ext'));
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = ApiService.parseResponse(response);
      if (data['success'] == true) invalidateCompanyAssetsCache(companyId);
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
