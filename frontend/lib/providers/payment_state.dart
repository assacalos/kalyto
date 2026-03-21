import 'package:flutter/foundation.dart';
import 'package:easyconnect/Models/payment_model.dart';

@immutable
class PaymentState {
  final List<PaymentModel> payments;
  final bool isLoading;
  final bool isLoadingMore;
  final String searchQuery;
  final String selectedStatus;
  final String selectedType;
  final String selectedApprovalStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final PaymentStats? paymentStats;
  final int currentPage;
  final int lastPage;
  final int totalItems;
  final int perPage;
  final bool isCreating;
  final String generatedReference;

  const PaymentState({
    this.payments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.selectedStatus = 'all',
    this.selectedType = 'all',
    this.selectedApprovalStatus = 'all',
    this.startDate,
    this.endDate,
    this.paymentStats,
    this.currentPage = 1,
    this.lastPage = 1,
    this.totalItems = 0,
    this.perPage = 15,
    this.isCreating = false,
    this.generatedReference = '',
  });

  PaymentState copyWith({
    List<PaymentModel>? payments,
    bool? isLoading,
    bool? isLoadingMore,
    String? searchQuery,
    String? selectedStatus,
    String? selectedType,
    String? selectedApprovalStatus,
    DateTime? startDate,
    DateTime? endDate,
    PaymentStats? paymentStats,
    int? currentPage,
    int? lastPage,
    int? totalItems,
    int? perPage,
    bool? isCreating,
    String? generatedReference,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedType: selectedType ?? this.selectedType,
      selectedApprovalStatus:
          selectedApprovalStatus ?? this.selectedApprovalStatus,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentStats: paymentStats ?? this.paymentStats,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      totalItems: totalItems ?? this.totalItems,
      perPage: perPage ?? this.perPage,
      isCreating: isCreating ?? this.isCreating,
      generatedReference: generatedReference ?? this.generatedReference,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}
