import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/journal_state.dart';
import 'package:easyconnect/services/api_service.dart';

final journalProvider =
    NotifierProvider<JournalNotifier, JournalState>(JournalNotifier.new);

class JournalNotifier extends Notifier<JournalState> {
  @override
  JournalState build() {
    final now = DateTime.now();
    return JournalState(
      selectedMonth: now.month,
      selectedYear: now.year,
    );
  }

  Future<void> loadJournal() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.getJournal(
        mois: state.selectedMonth,
        annee: state.selectedYear,
        dateDebut: state.dateDebut,
        dateFin: state.dateFin,
      );
      if (res['success'] == true && res['data'] != null) {
        state = state.copyWith(
          journalData: Map<String, dynamic>.from(res['data'] as Map),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void setMonthYear(int month, int year) {
    state = state.copyWith(
      selectedMonth: month,
      selectedYear: year,
      dateDebut: null,
      dateFin: null,
    );
    loadJournal();
  }

  void setDateRange(String debut, String fin) {
    state = state.copyWith(
      dateDebut: debut,
      dateFin: fin,
      selectedMonth: null,
      selectedYear: null,
    );
    loadJournal();
  }

  Future<bool> createEntry(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.journalCreate(data);
      if (res['success'] == true) {
        await loadJournal();
        return true;
      }
      throw Exception(res['message']?.toString() ?? 'Échec');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateEntry(int id, Map<String, dynamic> data) async {
    try {
      final res = await ApiService.journalUpdate(id, data);
      if (res['success'] == true) {
        await loadJournal();
        return true;
      }
      throw Exception(res['message']?.toString() ?? 'Échec');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteEntry(int id) async {
    try {
      final res = await ApiService.journalDestroy(id);
      if (res['success'] == true) {
        await loadJournal();
        return true;
      }
      throw Exception(res['message']?.toString() ?? 'Échec');
    } catch (e) {
      rethrow;
    }
  }
}
