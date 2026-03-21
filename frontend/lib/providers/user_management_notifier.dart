import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/providers/user_management_state.dart';
import 'package:easyconnect/services/user_service.dart';

final userManagementProvider =
    NotifierProvider<UserManagementNotifier, UserManagementState>(
        UserManagementNotifier.new);

class UserManagementNotifier extends Notifier<UserManagementState> {
  final UserService _service = UserService();

  @override
  UserManagementState build() => const UserManagementState();

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getUsers();
      state = state.copyWith(users: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadUserStats() async {
    try {
      final stats = await _service.getUserStats();
      state = state.copyWith(
        totalUsers: stats['total'] ?? 0,
        activeUsers: stats['active'] ?? 0,
        newUsersThisMonth: stats['new_this_month'] ?? 0,
      );
    } catch (_) {}
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setSelectedRole(String role) {
    state = state.copyWith(selectedRole: role);
  }

  void setShowActiveOnly(bool v) {
    state = state.copyWith(showActiveOnly: v);
  }

  List<UserModel> getFilteredUsers() {
    var list = state.users;
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      list = list.where((u) {
        final name = '${u.nom ?? ''} ${u.prenom ?? ''}'.toLowerCase();
        final email = (u.email ?? '').toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }
    if (state.selectedRole != 'all') {
      final roleId = UserManagementState.roleIdFromName(state.selectedRole);
      list = list.where((u) => u.role == roleId).toList();
    }
    if (state.showActiveOnly) {
      list = list.where((u) => u.isActive).toList();
    }
    return list;
  }

  Future<bool> createUser({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required int roleId,
    int? companyId,
  }) async {
    state = state.copyWith(isCreating: true);
    try {
      final user = UserModel(
        id: 0,
        nom: nom.trim(),
        prenom: prenom.trim(),
        email: email.trim(),
        role: roleId,
        companyId: companyId,
        isActive: true,
      );
      await _service.createUser(user, password);
      await loadUsers();
      await loadUserStats();
      state = state.copyWith(isCreating: false);
      return true;
    } catch (_) {
      state = state.copyWith(isCreating: false);
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateUser(user);
      await loadUsers();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final ok = await _service.deleteUser(userId);
      if (ok) {
        await loadUsers();
        await loadUserStats();
      }
      state = state.copyWith(isLoading: false);
      return ok;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> toggleUserStatus(int userId, bool isActive) async {
    state = state.copyWith(isLoading: true);
    try {
      final ok = await _service.toggleUserStatus(userId, isActive);
      if (ok) {
        await loadUsers();
        await loadUserStats();
      }
      state = state.copyWith(isLoading: false);
      return ok;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}
