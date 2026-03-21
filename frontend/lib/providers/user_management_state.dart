import 'package:flutter/material.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/utils/roles.dart';

class UserManagementState {
  final List<UserModel> users;
  final bool isLoading;
  final String searchQuery;
  final String selectedRole;
  final bool showActiveOnly;
  final int totalUsers;
  final int activeUsers;
  final int newUsersThisMonth;
  final bool isCreating;

  const UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedRole = 'all',
    this.showActiveOnly = true,
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.newUsersThisMonth = 0,
    this.isCreating = false,
  });

  UserManagementState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? searchQuery,
    String? selectedRole,
    bool? showActiveOnly,
    int? totalUsers,
    int? activeUsers,
    int? newUsersThisMonth,
    bool? isCreating,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRole: selectedRole ?? this.selectedRole,
      showActiveOnly: showActiveOnly ?? this.showActiveOnly,
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      newUsersThisMonth: newUsersThisMonth ?? this.newUsersThisMonth,
      isCreating: isCreating ?? this.isCreating,
    );
  }

  static String getRoleName(int? role) => Roles.getRoleName(role);

  static Color getRoleColor(int? role) {
    switch (role) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.teal;
      case 6:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static int roleIdFromName(String name) {
    switch (name) {
      case 'admin':
        return 1;
      case 'commercial':
        return 2;
      case 'comptable':
        return 3;
      case 'rh':
        return 4;
      case 'technicien':
        return 5;
      case 'patron':
        return 6;
      default:
        return 1;
    }
  }
}
