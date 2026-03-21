import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/inventory_session_state.dart';
import 'package:easyconnect/Models/inventory_session_model.dart';
import 'package:easyconnect/services/api_service.dart';

final inventorySessionProvider =
    NotifierProvider<InventorySessionNotifier, InventorySessionState>(
        InventorySessionNotifier.new);

class InventorySessionNotifier extends Notifier<InventorySessionState> {
  @override
  InventorySessionState build() => const InventorySessionState();

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.getInventorySessions();
      if (res['success'] == true) {
        final data = res['data'];
        List<InventorySession> list = [];
        if (data is List) {
          list = data
              .map((e) => InventorySession.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList();
        } else if (data is Map && data['data'] is List) {
          list = (data['data'] as List)
              .map((e) => InventorySession.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList();
        }
        state = state.copyWith(sessions: list, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res['message']?.toString() ?? 'Erreur',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadSession(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.getInventorySession(id);
      if (res['success'] == true && res['data'] != null) {
        final session = InventorySession.fromJson(
            Map<String, dynamic>.from(res['data'] as Map));
        state = state.copyWith(currentSession: session, isLoading: false);
        await loadLines(id);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res['message']?.toString() ?? 'Session non trouvée',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadLines(int sessionId) async {
    state = state.copyWith(isLoadingLines: true, error: null);
    try {
      final res = await ApiService.getInventoryLines(sessionId);
      if (res['success'] == true) {
        final data = res['data'];
        List<InventoryLine> list = [];
        if (data is List) {
          list = data
              .map((e) =>
                  InventoryLine.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        } else if (data is Map && data['lines'] is List) {
          list = (data['lines'] as List)
              .map((e) =>
                  InventoryLine.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        } else if (data is Map && data['data'] is List) {
          list = (data['data'] as List)
              .map((e) =>
                  InventoryLine.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
        state = state.copyWith(lines: list, isLoadingLines: false);
      } else {
        state = state.copyWith(isLoadingLines: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingLines: false);
    }
  }

  Future<InventorySession?> createSession({String? date, String? depot}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.createInventorySession(date: date, depot: depot);
      if (res['success'] == true && res['data'] != null) {
        final session = InventorySession.fromJson(
            Map<String, dynamic>.from(res['data'] as Map));
        state = state.copyWith(
          sessions: [session, ...state.sessions],
          currentSession: session,
          isLoading: false,
        );
        return session;
      }
      state = state.copyWith(
        isLoading: false,
        error: res['message']?.toString() ?? 'Erreur création',
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> addLinesFromStocks(int sessionId, {List<int>? stockIds}) async {
    state = state.copyWith(isLoadingLines: true, error: null);
    try {
      final res = await ApiService.addInventoryLines(sessionId, stockIds: stockIds);
      if (res['success'] == true) {
        await loadLines(sessionId);
        state = state.copyWith(isLoadingLines: false);
        return true;
      }
      state = state.copyWith(
        isLoadingLines: false,
        error: res['message']?.toString(),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoadingLines: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void setLineCountedLocally(int lineIndex, double countedQty) {
    if (lineIndex < 0 || lineIndex >= state.lines.length) return;
    final updated = state.lines.toList();
    updated[lineIndex] = updated[lineIndex].copyWith(countedQty: countedQty);
    state = state.copyWith(lines: updated);
  }

  Future<bool> updateLineCounted(int sessionId, int lineId, double countedQty) async {
    try {
      final res = await ApiService.updateInventoryLineCounted(
          sessionId, lineId, countedQty);
      if (res['success'] == true) {
        await loadLines(sessionId);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> closeSession(int sessionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.closeInventorySession(sessionId);
      if (res['success'] == true) {
        if (state.currentSession?.id == sessionId) {
          final updated = state.currentSession!.copyWith(
            status: 'closed',
            closedAt: DateTime.now().toIso8601String(),
          );
          state = state.copyWith(currentSession: updated);
        }
        await loadSessions();
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: res['message']?.toString() ?? 'Erreur clôture',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void setCurrentSession(InventorySession? session) {
    state = state.copyWith(currentSession: session, lines: session == null ? [] : state.lines);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

extension on InventorySession {
  InventorySession copyWith({
    int? id,
    String? date,
    String? depot,
    String? status,
    String? closedAt,
    int? linesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventorySession(
      id: id ?? this.id,
      date: date ?? this.date,
      depot: depot ?? this.depot,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      linesCount: linesCount ?? this.linesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
