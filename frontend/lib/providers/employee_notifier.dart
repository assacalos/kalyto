import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/providers/employee_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/notification_helper.dart';

final employeeProvider =
    NotifierProvider<EmployeeNotifier, EmployeeState>(EmployeeNotifier.new);

class EmployeeNotifier extends Notifier<EmployeeState> {
  final EmployeeService _service = EmployeeService();
  bool _loadingInProgress = false;

  @override
  EmployeeState build() {
    return const EmployeeState();
  }

  String get _cacheKey =>
      'employees_${state.searchQuery}_${state.selectedDepartment}_${state.selectedPosition}_${state.selectedStatus}';

  Future<void> loadEmployees({
    bool loadAll = false,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (_loadingInProgress) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (page == 1) {
      state = state.copyWith(isLoading: true);
      final hiveList = EmployeeService.getCachedEmployees();
      if (hiveList.isNotEmpty && !forceRefresh) {
        state = state.copyWith(
          employees: hiveList,
          isLoading: false,
          currentPage: 1,
        );
        return;
      }
      final cached = CacheHelper.get<List<Employee>>(_cacheKey);
      if (cached != null && cached.isNotEmpty && !forceRefresh) {
        state = state.copyWith(
          employees: cached,
          isLoading: false,
        );
      } else {
        state = state.copyWith(employees: []);
      }
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    _loadingInProgress = true;
    try {
      final res = await _service.getEmployeesPaginated(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        department: state.selectedDepartment != 'all' && state.selectedDepartment.isNotEmpty
            ? state.selectedDepartment
            : null,
        position: state.selectedPosition != 'all' && state.selectedPosition.isNotEmpty
            ? state.selectedPosition
            : null,
        status: (loadAll || state.selectedStatus == 'all') ? null : state.selectedStatus,
        page: page,
        perPage: state.perPage,
      );

      final list = res.data;
      if (page == 1) {
        state = state.copyWith(
          employees: list,
          isLoading: false,
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
          hasNextPage: res.hasNextPage,
          hasPreviousPage: res.hasPreviousPage,
        );
        CacheHelper.set(_cacheKey, list, duration: AppConfig.mediumCacheDuration);
      } else {
        final existingIds = state.employees.map((e) => e.id).toSet();
        final newList = List<Employee>.from(state.employees)
          ..addAll(
            list.where((e) => e.id != null && !existingIds.contains(e.id)),
          );
        state = state.copyWith(
          employees: newList,
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
          hasNextPage: res.hasNextPage,
          hasPreviousPage: res.hasPreviousPage,
        );
      }

      state = state.copyWith(
        employees: List.from(state.employees)
          ..sort((a, b) =>
              '${a.lastName} ${a.firstName}'.toLowerCase().compareTo(
                    '${b.lastName} ${b.firstName}'.toLowerCase(),
                  )),
      );
    } catch (e) {
      if (page == 1 && state.employees.isEmpty) {
        final fallback = EmployeeService.getCachedEmployees();
        if (fallback.isNotEmpty) {
          state = state.copyWith(employees: fallback, isLoading: false);
        } else {
          final cached = CacheHelper.get<List<Employee>>(_cacheKey);
          if (cached != null && cached.isNotEmpty) {
            state = state.copyWith(employees: cached, isLoading: false);
          } else {
            state = state.copyWith(isLoading: false);
          }
        }
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } finally {
      _loadingInProgress = false;
    }
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadEmployees(page: state.currentPage + 1);
    }
  }

  Future<void> loadEmployeeStats() async {
    try {
      final stats = await _service.getEmployeeStats();
      state = state.copyWith(employeeStats: stats);
    } catch (_) {}
  }

  Future<void> loadDepartments() async {
    try {
      final list = await _service.getDepartments();
      state = state.copyWith(departments: list);
    } catch (_) {}
  }

  Future<void> loadPositions() async {
    try {
      final list = await _service.getPositions();
      state = state.copyWith(positions: list);
    } catch (_) {}
  }

  void searchEmployees(String query) {
    state = state.copyWith(searchQuery: query);
    loadEmployees();
  }

  void filterByDepartment(String department) {
    state = state.copyWith(selectedDepartment: department);
    loadEmployees();
  }

  void filterByPosition(String position) {
    state = state.copyWith(selectedPosition: position);
    loadEmployees();
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadEmployees();
  }

  void loadByStatus(int index, {bool forceRefresh = false}) {
    const statuses = ['active', 'inactive', 'on_leave', 'terminated'];
    state = state.copyWith(selectedStatus: statuses[index]);
    loadEmployees(forceRefresh: forceRefresh);
  }

  Future<bool> createEmployee({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    String? nationality,
    String? idNumber,
    String? socialSecurityNumber,
    String? position,
    String? department,
    String? manager,
    DateTime? hireDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? contractType,
    double? salary,
    String? currency,
    String? workSchedule,
    String? notes,
  }) async {
    try {
      final result = await _service.createEmployee(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        birthDate: birthDate,
        gender: gender,
        maritalStatus: maritalStatus,
        nationality: nationality,
        idNumber: idNumber,
        socialSecurityNumber: socialSecurityNumber,
        position: position,
        department: department,
        manager: manager,
        hireDate: hireDate,
        contractStartDate: contractStartDate,
        contractEndDate: contractEndDate,
        contractType: contractType,
        salary: salary,
        currency: currency ?? 'fcfa',
        workSchedule: workSchedule,
        notes: notes,
      );
      if (result['data'] != null) {
        final created = Employee.fromJson(Map<String, dynamic>.from(result['data'] as Map));
        if (!state.employees.any((e) => e.id == created.id)) {
          state = state.copyWith(
            employees: [created, ...state.employees],
          );
          EmployeeService.saveCachedEmployees(state.employees);
        }
      }
      CacheHelper.clearByPrefix('employees_');
      await loadEmployeeStats();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateEmployee(
    Employee employee, {
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    String? nationality,
    String? idNumber,
    String? socialSecurityNumber,
    String? position,
    String? department,
    String? manager,
    DateTime? hireDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? contractType,
    double? salary,
    String? currency,
    String? workSchedule,
    String? status,
    String? notes,
  }) async {
    if (employee.id == null) return false;
    try {
      await _service.updateEmployee(
        id: employee.id!,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        birthDate: birthDate,
        gender: gender,
        maritalStatus: maritalStatus,
        nationality: nationality,
        idNumber: idNumber,
        socialSecurityNumber: socialSecurityNumber,
        position: position,
        department: department,
        manager: manager,
        hireDate: hireDate,
        contractStartDate: contractStartDate,
        contractEndDate: contractEndDate,
        contractType: contractType,
        salary: salary,
        currency: currency ?? 'fcfa',
        workSchedule: workSchedule,
        status: status,
        notes: notes,
      );
      CacheHelper.clearByPrefix('employees_');
      await loadEmployees(loadAll: true, forceRefresh: true);
      await loadEmployeeStats();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteEmployee(Employee employee) async {
    if (employee.id == null) return;
    try {
      await _service.deleteEmployee(employee.id!);
      CacheHelper.clearByPrefix('employees_');
      await loadEmployees(loadAll: true, forceRefresh: true);
      await loadEmployeeStats();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> submitEmployeeForApproval(Employee employee) async {
    if (employee.id == null) return;
    try {
      await _service.submitEmployeeForApproval(employee.id!);
      NotificationHelper.notifySubmission(
        entityType: 'employee',
        entityName: NotificationHelper.getEntityDisplayName('employee', employee),
        entityId: employee.id.toString(),
        route: NotificationHelper.getEntityRoute('employee', employee.id.toString()),
      );
      await loadEmployees();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> approveEmployee(Employee employee, {String? comments}) async {
    if (employee.id == null) return;
    try {
      await _service.approveEmployee(employee.id!, comments: comments);
      NotificationHelper.notifyValidation(
        entityType: 'employee',
        entityName: NotificationHelper.getEntityDisplayName('employee', employee),
        entityId: employee.id.toString(),
        route: NotificationHelper.getEntityRoute('employee', employee.id.toString()),
        entity: employee,
      );
      await loadEmployees();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> rejectEmployee(Employee employee, {required String reason}) async {
    if (employee.id == null) return;
    try {
      await _service.rejectEmployee(employee.id!, reason: reason);
      NotificationHelper.notifyRejection(
        entityType: 'employee',
        entityName: NotificationHelper.getEntityDisplayName('employee', employee),
        entityId: employee.id.toString(),
        reason: reason,
        route: NotificationHelper.getEntityRoute('employee', employee.id.toString()),
        entity: employee,
      );
      await loadEmployees();
    } catch (_) {
      rethrow;
    }
  }
}
