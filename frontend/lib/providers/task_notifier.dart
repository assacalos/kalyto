import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/task_model.dart';
import 'package:easyconnect/providers/task_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/task_service.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:easyconnect/utils/roles.dart';

final taskProvider =
    NotifierProvider<TaskNotifier, TaskState>(TaskNotifier.new);

class TaskNotifier extends Notifier<TaskState> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  bool _isRefreshingFromApi = false;

  int? get _userRole => ref.read(authProvider).user?.role;

  bool get canAssignTasks =>
      _userRole == Roles.ADMIN || _userRole == Roles.PATRON;

  @override
  TaskState build() {
    return const TaskState();
  }

  Future<void> loadTasks({
    int page = 1,
    bool forceRefresh = false,
    bool isRetry = false,
  }) async {
    if (page == 1) state = state.copyWith(loadError: false);

    if (page == 1 && !forceRefresh) {
      final cached = TaskService.getCachedTaches();
      if (cached.isNotEmpty) {
        state = state.copyWith(tasks: cached, isLoading: false);
      } else {
        state = state.copyWith(tasks: [], isLoading: false);
      }
      Future.microtask(() => _refreshTasksFromApi(isRetry: isRetry));
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final res = await _taskService.getTasksPaginated(
        page: page,
        perPage: 20,
        assignedTo: state.selectedAssignedTo,
        status: state.selectedStatus,
      );
      state = state.copyWith(
        tasks: res.data,
        isLoading: false,
        loadError: false,
        currentPage: res.meta.currentPage,
        lastPage: res.meta.lastPage,
        totalItems: res.meta.total,
      );
    } catch (e) {
      if (page == 1 && !isRetry) {
        await Future.delayed(const Duration(milliseconds: 400));
        return loadTasks(page: page, forceRefresh: forceRefresh, isRetry: true);
      }
      state = state.copyWith(
        isLoading: false,
        loadError: page == 1,
      );
      if (state.tasks.isEmpty) rethrow;
    }
  }

  Future<void> _refreshTasksFromApi({bool isRetry = false}) async {
    if (_isRefreshingFromApi) return;
    _isRefreshingFromApi = true;
    try {
      state = state.copyWith(isLoading: true);
      final res = await _taskService.getTasksPaginated(
        page: 1,
        perPage: 20,
        assignedTo: state.selectedAssignedTo,
        status: state.selectedStatus,
      );
      state = state.copyWith(
        tasks: res.data,
        isLoading: false,
        loadError: false,
        currentPage: res.meta.currentPage,
        lastPage: res.meta.lastPage,
        totalItems: res.meta.total,
      );
    } catch (e) {
      if (!isRetry) {
        await Future.delayed(const Duration(milliseconds: 400));
        return _refreshTasksFromApi(isRetry: true);
      }
      state = state.copyWith(isLoading: false, loadError: true);
      if (state.tasks.isEmpty) rethrow;
    } finally {
      _isRefreshingFromApi = false;
    }
  }

  Future<void> loadUsers() async {
    try {
      final list = await _userService.getUsers();
      state = state.copyWith(users: list);
    } catch (e) {
      rethrow;
    }
  }

  Future<TaskModel?> loadTask(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      final task = await _taskService.getTask(id);
      state = state.copyWith(currentTask: task, isLoading: false);
      return task;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<bool> createTask({
    required String titre,
    String? description,
    required int assignedTo,
    String priority = 'medium',
    String? dueDate,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _taskService.createTask(
        titre: titre,
        description: description,
        assignedTo: assignedTo,
        priority: priority,
        dueDate: dueDate,
      );
      await loadTasks(page: 1);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<bool> updateTaskStatus(int id, String status) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _taskService.updateTaskStatus(id, status);
      final index = state.tasks.indexWhere((t) => t.id == id);
      if (index >= 0) {
        final newTasks = List<TaskModel>.from(state.tasks);
        newTasks[index] = updated;
        state = state.copyWith(tasks: newTasks, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      if (state.currentTask?.id == id) {
        state = state.copyWith(currentTask: updated);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<bool> updateTask(
    int id, {
    String? titre,
    String? description,
    int? assignedTo,
    String? status,
    String? priority,
    String? dueDate,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _taskService.updateTask(
        id,
        titre: titre,
        description: description,
        assignedTo: assignedTo,
        status: status,
        priority: priority,
        dueDate: dueDate,
      );
      final index = state.tasks.indexWhere((t) => t.id == id);
      if (index >= 0) {
        final newTasks = List<TaskModel>.from(state.tasks);
        newTasks[index] = updated;
        state = state.copyWith(tasks: newTasks);
      }
      state = state.copyWith(currentTask: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<bool> deleteTask(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _taskService.deleteTask(id);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
        currentTask: state.currentTask?.id == id ? null : state.currentTask,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(selectedStatus: status);
    loadTasks(page: 1);
  }

  void setAssignedToFilter(int? userId) {
    state = state.copyWith(selectedAssignedTo: userId);
    loadTasks(page: 1);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedStatus: null,
      selectedAssignedTo: null,
    );
    loadTasks(page: 1);
  }
}
