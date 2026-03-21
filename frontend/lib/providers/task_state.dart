import 'package:flutter/material.dart';
import 'package:easyconnect/Models/task_model.dart';
import 'package:easyconnect/Models/user_model.dart';

@immutable
class TaskState {
  final List<TaskModel> tasks;
  final TaskModel? currentTask;
  final List<UserModel> users;
  final bool isLoading;
  final bool loadError;
  final String? selectedStatus;
  final int? selectedAssignedTo;
  final int currentPage;
  final int lastPage;
  final int totalItems;

  const TaskState({
    this.tasks = const [],
    this.currentTask,
    this.users = const [],
    this.isLoading = false,
    this.loadError = false,
    this.selectedStatus,
    this.selectedAssignedTo,
    this.currentPage = 1,
    this.lastPage = 1,
    this.totalItems = 0,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    TaskModel? currentTask,
    List<UserModel>? users,
    bool? isLoading,
    bool? loadError,
    String? selectedStatus,
    int? selectedAssignedTo,
    int? currentPage,
    int? lastPage,
    int? totalItems,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      currentTask: currentTask ?? this.currentTask,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      loadError: loadError ?? this.loadError,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedAssignedTo: selectedAssignedTo ?? this.selectedAssignedTo,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
}
