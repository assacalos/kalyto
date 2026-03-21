import 'package:easyconnect/Models/notification_model.dart';

/// État du provider de notifications (Riverpod).
class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool isLoadingMore;
  final bool unreadOnly;
  final String? selectedType;
  final String? selectedEntityType;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int perPage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.unreadOnly = false,
    this.selectedType,
    this.selectedEntityType,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.perPage = 20,
  });

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    bool? isLoadingMore,
    bool? unreadOnly,
    String? selectedType,
    String? selectedEntityType,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? perPage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      selectedType: selectedType ?? this.selectedType,
      selectedEntityType: selectedEntityType ?? this.selectedEntityType,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      perPage: perPage ?? this.perPage,
    );
  }
}
