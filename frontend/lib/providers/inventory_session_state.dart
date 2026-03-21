import 'package:flutter/foundation.dart';
import 'package:easyconnect/Models/inventory_session_model.dart';

@immutable
class InventorySessionState {
  final List<InventorySession> sessions;
  final InventorySession? currentSession;
  final List<InventoryLine> lines;
  final bool isLoading;
  final bool isLoadingLines;
  final String? error;

  const InventorySessionState({
    this.sessions = const [],
    this.currentSession,
    this.lines = const [],
    this.isLoading = false,
    this.isLoadingLines = false,
    this.error,
  });

  InventorySessionState copyWith({
    List<InventorySession>? sessions,
    InventorySession? currentSession,
    List<InventoryLine>? lines,
    bool? isLoading,
    bool? isLoadingLines,
    String? error,
  }) {
    return InventorySessionState(
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      lines: lines ?? this.lines,
      isLoading: isLoading ?? this.isLoading,
      isLoadingLines: isLoadingLines ?? this.isLoadingLines,
      error: error,
    );
  }

  double get totalEcart =>
      lines.fold(0.0, (s, l) => s + l.ecart);
  int get linesWithEcart => lines.where((l) => l.hasEcart).length;
}
