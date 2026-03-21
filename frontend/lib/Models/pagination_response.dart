/// Modèle pour représenter une réponse paginée de Laravel
/// Supporte deux formats :
/// 1. Format standard Laravel : {"data": [...], "meta": {...}, "links": {...}}
/// 2. Format simplifié : {"success": true, "data": [...], "pagination": {...}}
class PaginationResponse<T> {
  final List<T> data;
  final PaginationMeta meta;

  PaginationResponse({required this.data, required this.meta});

  factory PaginationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    // Extraire les données
    List<dynamic> dataList = [];

    // Format 1: {"success": true, "data": [...], "pagination": {...}}
    if (json.containsKey('success') && json['success'] == true) {
      if (json['data'] is List) {
        dataList = json['data'] as List<dynamic>;
      }
      // Extraire les métadonnées de pagination
      if (json.containsKey('pagination') && json['pagination'] is Map) {
        final paginationData = json['pagination'] as Map<String, dynamic>;
        return PaginationResponse<T>(
          data:
              dataList
                  .map((item) => fromJsonT(item as Map<String, dynamic>))
                  .toList(),
          meta: PaginationMeta.fromJson(paginationData),
        );
      }
    }

    // Format 2: Format standard Laravel {"data": [...], "meta": {...}, "links": {...}}
    if (json.containsKey('data') && json['data'] is List) {
      dataList = json['data'] as List<dynamic>;
    }

    // Utiliser les métadonnées directement ou depuis meta
    final paginationData =
        json.containsKey('meta') && json['meta'] is Map
            ? json['meta'] as Map<String, dynamic>
            : json;

    return PaginationResponse<T>(
      data:
          dataList
              .map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList(),
      meta: PaginationMeta.fromJson(paginationData),
    );
  }

  /// Vérifie s'il y a une page suivante
  bool get hasNextPage => meta.currentPage < meta.lastPage;

  /// Vérifie s'il y a une page précédente
  bool get hasPreviousPage => meta.currentPage > 1;

  /// Vérifie si c'est la première page
  bool get isFirstPage => meta.currentPage == 1;

  /// Vérifie si c'est la dernière page
  bool get isLastPage => meta.currentPage >= meta.lastPage;

  Map<String, dynamic> toJson() => {'data': data, 'meta': meta.toJson()};
}

/// Métadonnées de pagination Laravel
class PaginationMeta {
  final int currentPage;
  final int? from;
  final int lastPage;
  final int perPage;
  final int? to;
  final int total;
  final String? firstPageUrl;
  final String? lastPageUrl;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final String path;

  PaginationMeta({
    required this.currentPage,
    this.from,
    required this.lastPage,
    required this.perPage,
    this.to,
    required this.total,
    this.firstPageUrl,
    this.lastPageUrl,
    this.nextPageUrl,
    this.prevPageUrl,
    required this.path,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage:
          json['current_page'] as int? ?? json['currentPage'] as int? ?? 1,
      from: json['from'] as int?,
      lastPage: json['last_page'] as int? ?? json['lastPage'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? json['perPage'] as int? ?? 15,
      to: json['to'] as int?,
      total: json['total'] as int? ?? 0,
      firstPageUrl:
          json['first_page_url'] as String? ?? json['firstPageUrl'] as String?,
      lastPageUrl:
          json['last_page_url'] as String? ?? json['lastPageUrl'] as String?,
      nextPageUrl:
          json['next_page_url'] as String? ?? json['nextPageUrl'] as String?,
      prevPageUrl:
          json['prev_page_url'] as String? ?? json['prevPageUrl'] as String?,
      path: json['path'] as String? ?? json['base_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'current_page': currentPage,
    'from': from,
    'last_page': lastPage,
    'per_page': perPage,
    'to': to,
    'total': total,
    'first_page_url': firstPageUrl,
    'last_page_url': lastPageUrl,
    'next_page_url': nextPageUrl,
    'prev_page_url': prevPageUrl,
    'path': path,
  };
}
