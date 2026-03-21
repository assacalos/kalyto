import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/providers/contract_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/contract_service.dart';
import 'package:easyconnect/utils/notification_helper.dart';

final contractProvider =
    NotifierProvider<ContractNotifier, ContractState>(ContractNotifier.new);

class ContractNotifier extends Notifier<ContractState> {
  final ContractService _service = ContractService();
  bool _loadingInProgress = false;

  @override
  ContractState build() {
    return const ContractState();
  }

  Future<void> loadContracts({int page = 1, bool forceRefresh = false}) async {
    if (_loadingInProgress) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (page == 1) {
      if (!forceRefresh) {
        final cached = ContractService.getCachedContracts();
        if (cached.isNotEmpty) {
          state = state.copyWith(
            contracts: cached,
            isLoading: false,
            currentPage: 1,
          );
          Future.microtask(() => _refreshFromApi());
          return;
        }
      }
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    _loadingInProgress = true;
    try {
      final res = await _service.getContractsPaginated(
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        contractType: state.selectedContractType != 'all'
            ? state.selectedContractType
            : null,
        department: state.selectedDepartment != 'all'
            ? state.selectedDepartment
            : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: page,
        perPage: state.perPage,
      );

      final list = res.data;
      if (page == 1) {
        state = state.copyWith(
          contracts: list,
          isLoading: false,
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
          hasNextPage: res.hasNextPage,
          hasPreviousPage: res.hasPreviousPage,
        );
      } else {
        final existingIds = state.contracts.map((c) => c.id).toSet();
        final newList = List<Contract>.from(state.contracts)
          ..addAll(
            list.where((c) => c.id != null && !existingIds.contains(c.id)),
          );
        state = state.copyWith(
          contracts: newList,
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
          hasNextPage: res.hasNextPage,
          hasPreviousPage: res.hasPreviousPage,
        );
      }
    } catch (e) {
      if (page == 1 && state.contracts.isEmpty) {
        final cached = ContractService.getCachedContracts();
        if (cached.isNotEmpty) {
          state = state.copyWith(contracts: cached, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      final res = await _service.getContractsPaginated(
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        contractType: state.selectedContractType != 'all'
            ? state.selectedContractType
            : null,
        department: state.selectedDepartment != 'all'
            ? state.selectedDepartment
            : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: 1,
        perPage: state.perPage,
      );
      state = state.copyWith(
        contracts: res.data,
        currentPage: res.meta.currentPage,
        totalPages: res.meta.lastPage,
        totalItems: res.meta.total,
        hasNextPage: res.hasNextPage,
        hasPreviousPage: res.hasPreviousPage,
      );
    } catch (_) {}
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadContracts(page: state.currentPage + 1);
    }
  }

  Future<void> loadContractStats() async {
    try {
      final stats = await _service.getContractStats(
        startDate: null,
        endDate: null,
        department: state.selectedDepartment != 'all'
            ? state.selectedDepartment
            : null,
        contractType: state.selectedContractType != 'all'
            ? state.selectedContractType
            : null,
      );
      state = state.copyWith(contractStats: stats);
    } catch (_) {}
  }

  void searchContracts(String query) {
    state = state.copyWith(searchQuery: query);
    loadContracts();
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadContracts();
  }

  void filterByContractType(String type) {
    state = state.copyWith(selectedContractType: type);
    loadContracts();
  }

  void filterByDepartment(String department) {
    state = state.copyWith(selectedDepartment: department);
    loadContracts();
  }

  Future<void> submitContract(Contract contract) async {
    if (contract.id == null) return;
    try {
      final result = await _service.submitContract(contract.id!);
      if (result['success'] == true) {
        NotificationHelper.notifySubmission(
          entityType: 'contract',
          entityName: NotificationHelper.getEntityDisplayName(
            'contract',
            contract,
          ),
          entityId: contract.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'contract',
            contract.id.toString(),
          ),
        );
        await loadContracts();
        await loadContractStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la soumission');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveContract(Contract contract, {String? notes}) async {
    if (contract.id == null) return;
    try {
      final result = await _service.approveContract(contract.id!, notes: notes);
      if (result['success'] == true) {
        NotificationHelper.notifyValidation(
          entityType: 'contract',
          entityName: NotificationHelper.getEntityDisplayName(
            'contract',
            contract,
          ),
          entityId: contract.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'contract',
            contract.id.toString(),
          ),
          entity: contract,
        );
        await loadContracts();
        await loadContractStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de l\'approbation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectContract(Contract contract, String reason) async {
    if (contract.id == null) return;
    try {
      final result =
          await _service.rejectContract(contract.id!, reason: reason);
      if (result['success'] == true) {
        NotificationHelper.notifyRejection(
          entityType: 'contract',
          entityName: NotificationHelper.getEntityDisplayName(
            'contract',
            contract,
          ),
          entityId: contract.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute(
            'contract',
            contract.id.toString(),
          ),
          entity: contract,
        );
        await loadContracts();
        await loadContractStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> terminateContract(
    Contract contract,
    String reason,
    DateTime terminationDate,
  ) async {
    if (contract.id == null) return;
    try {
      final result = await _service.terminateContract(
        id: contract.id!,
        reason: reason,
        terminationDate: terminationDate,
      );
      if (result['success'] == true) {
        await loadContracts();
        await loadContractStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la résiliation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelContract(Contract contract, {String? reason}) async {
    if (contract.id == null) return;
    try {
      final result = await _service.cancelContract(contract.id!, reason: reason);
      if (result['success'] == true) {
        await loadContracts();
        await loadContractStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de l\'annulation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteContract(Contract contract) async {
    if (contract.id == null) return;
    try {
      final result = await _service.deleteContract(contract.id!);
      if (result['success'] == true) {
        await loadContracts();
        await loadContractStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Crée un contrat. Utilisé par le formulaire (Riverpod).
  Future<bool> createContract({
    required int employeeId,
    required String contractType,
    required String position,
    required String department,
    required String jobTitle,
    required String jobDescription,
    required double grossSalary,
    required String salaryCurrency,
    required String paymentFrequency,
    required DateTime startDate,
    DateTime? endDate,
    int? durationMonths,
    required String workLocation,
    required String workSchedule,
    required int weeklyHours,
    required String probationPeriod,
    String? notes,
    String? contractTemplate,
    List<ContractClause>? clauses,
  }) async {
    try {
      final netSalary = grossSalary * 0.8;
      final result = await _service.createContract(
        employeeId: employeeId,
        contractType: contractType,
        position: position,
        department: department,
        jobTitle: jobTitle,
        jobDescription: jobDescription,
        grossSalary: grossSalary,
        netSalary: netSalary,
        salaryCurrency: salaryCurrency,
        paymentFrequency: paymentFrequency,
        startDate: startDate,
        endDate: endDate,
        durationMonths: durationMonths,
        workLocation: workLocation,
        workSchedule: workSchedule,
        weeklyHours: weeklyHours,
        probationPeriod: probationPeriod,
        notes: notes,
        contractTemplate: contractTemplate,
        clauses: clauses,
      );
      if (result['success'] == true || result['data'] != null) {
        await loadContracts(forceRefresh: true);
        await loadContractStats();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Met à jour un contrat. Utilisé par le formulaire (Riverpod).
  Future<bool> updateContract({
    required int id,
    String? contractType,
    String? position,
    String? department,
    String? jobTitle,
    String? jobDescription,
    double? grossSalary,
    double? netSalary,
    String? salaryCurrency,
    String? paymentFrequency,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMonths,
    String? workLocation,
    String? workSchedule,
    int? weeklyHours,
    String? probationPeriod,
    String? notes,
    List<ContractClause>? clauses,
  }) async {
    try {
      final result = await _service.updateContract(
        id: id,
        contractType: contractType,
        position: position,
        department: department,
        jobTitle: jobTitle,
        jobDescription: jobDescription,
        grossSalary: grossSalary,
        netSalary: netSalary,
        salaryCurrency: salaryCurrency,
        paymentFrequency: paymentFrequency,
        startDate: startDate,
        endDate: endDate,
        durationMonths: durationMonths,
        workLocation: workLocation,
        workSchedule: workSchedule,
        weeklyHours: weeklyHours,
        probationPeriod: probationPeriod,
        notes: notes,
        clauses: clauses,
      );
      if (result['success'] == true) {
        await loadContracts(forceRefresh: true);
        await loadContractStats();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
