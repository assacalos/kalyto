import 'package:easyconnect/Models/pagination_response.dart';

/// Helper pour gérer la pagination côté Flutter
class PaginationHelper {
  /// Parse une réponse JSON de Laravel en PaginationResponse
  ///
  /// Laravel retourne la pagination dans ce format :
  /// {
  ///   "data": [...],
  ///   "current_page": 1,
  ///   "last_page": 5,
  ///   "per_page": 15,
  ///   "total": 100,
  ///   "from": 1,
  ///   "to": 15,
  ///   "first_page_url": "...",
  ///   "last_page_url": "...",
  ///   "next_page_url": "...",
  ///   "prev_page_url": null,
  ///   "path": "..."
  /// }
  static PaginationResponse<T> parseResponse<T>({
    required Map<String, dynamic> json,
    required T Function(Map<String, dynamic>) fromJsonT,
  }) {
    // Format 1: {"success": true, "data": [...], "pagination": {...}}
    // C'est le nouveau format du backend
    if (json.containsKey('success') &&
        json.containsKey('data') &&
        json.containsKey('pagination')) {
      final dataList = json['data'] is List ? json['data'] as List : [];
      final paginationData = json['pagination'] as Map<String, dynamic>;

      return PaginationResponse<T>(
        data:
            dataList
                .map((item) => fromJsonT(item as Map<String, dynamic>))
                .toList(),
        meta: PaginationMeta.fromJson(paginationData),
      );
    }

    // Format 1b: {"success": true, "data": [...], "meta": {...}} (ex: API Devis)
    if (json.containsKey('success') &&
        json.containsKey('data') &&
        json.containsKey('meta') &&
        json['meta'] is Map) {
      final dataList = json['data'] is List ? json['data'] as List : [];
      final metaData = json['meta'] as Map<String, dynamic>;

      return PaginationResponse<T>(
        data:
            dataList
                .map((item) => fromJsonT(item as Map<String, dynamic>))
                .toList(),
        meta: PaginationMeta.fromJson(metaData),
      );
    }

    // Format 2: Réponse paginée Laravel standard {"data": [...], "current_page": 1, ...}
    if (json.containsKey('data') &&
        (json.containsKey('current_page') || json.containsKey('currentPage'))) {
      return PaginationResponse.fromJson(json, fromJsonT);
    }

    // Format 3: Réponse encapsulée dans un objet success avec data contenant la pagination
    if (json.containsKey('success') && json['data'] != null) {
      final data = json['data'];
      if (data is Map<String, dynamic> &&
          (data.containsKey('current_page') ||
              data.containsKey('currentPage'))) {
        return PaginationResponse.fromJson(data, fromJsonT);
      }

      // Si data est une liste simple, créer une pagination factice
      if (data is List) {
        final parsedData = <T>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            if (item is Map<String, dynamic>) {
              final parsed = fromJsonT(item);
              parsedData.add(parsed);
            }
          } catch (e) {
            // Ignorer les erreurs de parsing
          }
        }
        return PaginationResponse<T>(
          data: parsedData,
          meta: PaginationMeta(
            currentPage: 1,
            lastPage: 1,
            perPage: parsedData.length,
            total: parsedData.length,
            path: '',
          ),
        );
      }
    }

    // Si c'est juste une liste, créer une pagination factice
    if (json.containsKey('data') && json['data'] is List) {
      final dataList = json['data'] as List;
      final parsedData = <T>[];
      for (var i = 0; i < dataList.length; i++) {
        try {
          final item = dataList[i];
          if (item is Map<String, dynamic>) {
            final parsed = fromJsonT(item);
            parsedData.add(parsed);
          }
        } catch (e) {
          // Ignorer les erreurs de parsing
        }
      }
      return PaginationResponse<T>(
        data: parsedData,
        meta: PaginationMeta(
          currentPage: 1,
          lastPage: 1,
          perPage: parsedData.length,
          total: parsedData.length,
          path: '',
        ),
      );
    }

    throw Exception('Format de réponse non reconnu pour la pagination');
  }

  /// Parse une réponse paginée en ignorant les éléments dont le parsing échoue (un objet corrompu ne bloque pas toute la liste).
  /// [fromJsonT] doit retourner null en cas d'erreur de parsing.
  static PaginationResponse<T> parseResponseSafe<T>({
    required Map<String, dynamic> json,
    required T? Function(Map<String, dynamic>) fromJsonT,
  }) {
    List<T> safeParseList(List list) {
      return list
          .map((item) =>
              item is Map<String, dynamic> ? fromJsonT(item) : null)
          .whereType<T>()
          .toList();
    }

    if (json.containsKey('success') &&
        json.containsKey('data') &&
        json.containsKey('pagination')) {
      final dataList = json['data'] is List ? json['data'] as List : [];
      final paginationData = json['pagination'] as Map<String, dynamic>;
      return PaginationResponse<T>(
        data: safeParseList(dataList),
        meta: PaginationMeta.fromJson(paginationData),
      );
    }

    if (json.containsKey('success') &&
        json.containsKey('data') &&
        json.containsKey('meta') &&
        json['meta'] is Map) {
      final dataList = json['data'] is List ? json['data'] as List : [];
      final metaData = json['meta'] as Map<String, dynamic>;
      return PaginationResponse<T>(
        data: safeParseList(dataList),
        meta: PaginationMeta.fromJson(metaData),
      );
    }

    if (json.containsKey('data') &&
        (json.containsKey('current_page') || json.containsKey('currentPage'))) {
      final dataList = json['data'] is List ? json['data'] as List : [];
      final paginationData =
          json.containsKey('meta') && json['meta'] is Map
              ? json['meta'] as Map<String, dynamic>
              : json;
      return PaginationResponse<T>(
        data: safeParseList(dataList),
        meta: PaginationMeta.fromJson(paginationData),
      );
    }

    if (json.containsKey('success') && json['data'] != null) {
      final data = json['data'];
      if (data is Map<String, dynamic> &&
          (data.containsKey('current_page') ||
              data.containsKey('currentPage'))) {
        final dataList = data['data'] is List ? data['data'] as List : [];
        final paginationData =
            data.containsKey('meta') && data['meta'] is Map
                ? data['meta'] as Map<String, dynamic>
                : data;
        return PaginationResponse<T>(
          data: safeParseList(dataList),
          meta: PaginationMeta.fromJson(paginationData),
        );
      }
      if (data is List) {
        return PaginationResponse<T>(
          data: safeParseList(data),
          meta: PaginationMeta(
            currentPage: 1,
            lastPage: 1,
            perPage: 0,
            total: 0,
            path: '',
          ),
        );
      }
    }

    if (json.containsKey('data') && json['data'] is List) {
      final dataList = json['data'] as List;
      return PaginationResponse<T>(
        data: safeParseList(dataList),
        meta: PaginationMeta(
          currentPage: 1,
          lastPage: 1,
          perPage: 0,
          total: 0,
          path: '',
        ),
      );
    }

    throw Exception('Format de réponse non reconnu pour la pagination');
  }

  /// Extrait le numéro de page depuis une URL Laravel
  static int? extractPageFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      final pageParam = uri.queryParameters['page'];
      if (pageParam != null) {
        return int.tryParse(pageParam);
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }

    return null;
  }

  /// Construit une URL de pagination avec les paramètres de requête
  static String buildPaginationUrl({
    required String baseUrl,
    required int page,
    Map<String, String>? queryParams,
  }) {
    final uri = Uri.parse(baseUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['page'] = page.toString();

    if (queryParams != null) {
      params.addAll(queryParams);
    }

    return uri.replace(queryParameters: params).toString();
  }

  /// Calcule le nombre total de pages
  static int calculateTotalPages(int total, int perPage) {
    if (total == 0 || perPage == 0) return 1;
    return (total / perPage).ceil();
  }

  /// Vérifie si une page est valide
  static bool isValidPage(int page, int lastPage) {
    return page >= 1 && page <= lastPage;
  }
}
