import 'package:easyconnect/Models/supplier_model.dart';

class SupplierState {
  final List<Supplier> allSuppliers;
  final List<Supplier> suppliers;
  final bool isLoading;
  final SupplierStats? supplierStats;
  final String searchQuery;
  final String selectedStatus;

  const SupplierState({
    this.allSuppliers = const [],
    this.suppliers = const [],
    this.isLoading = false,
    this.supplierStats,
    this.searchQuery = '',
    this.selectedStatus = 'all',
  });

  SupplierState copyWith({
    List<Supplier>? allSuppliers,
    List<Supplier>? suppliers,
    bool? isLoading,
    SupplierStats? supplierStats,
    String? searchQuery,
    String? selectedStatus,
  }) {
    return SupplierState(
      allSuppliers: allSuppliers ?? this.allSuppliers,
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      supplierStats: supplierStats ?? this.supplierStats,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}
