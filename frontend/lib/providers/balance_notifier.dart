import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/balance_state.dart';
import 'package:easyconnect/services/api_service.dart';

final balanceProvider =
    NotifierProvider<BalanceNotifier, BalanceState>(BalanceNotifier.new);

class BalanceNotifier extends Notifier<BalanceState> {
  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  BalanceState build() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return BalanceState(
      dateDebut: _formatDate(start),
      dateFin: _formatDate(end),
      mois: now.month,
      annee: now.year,
    );
  }

  Future<void> loadBalance() async {
    final dateDebut = state.dateDebut;
    final dateFin = state.dateFin;
    if (dateDebut == null || dateFin == null) return;
    state = state.copyWith(isLoading: true);
    try {
      // Préférer l'API balance (plan de comptes) si disponible
      final res = await ApiService.getBalance(
        dateDebut: dateDebut,
        dateFin: dateFin,
        mois: state.mois,
        annee: state.annee,
      );
      if (res['success'] == true && res['data'] != null) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final rawLignes = data['lignes'] is List ? data['lignes'] as List : [];
        final rows = <BalanceRow>[];
        double totalDebit = 0.0;
        double totalCredit = 0.0;
        for (final raw in rawLignes) {
          final map = raw is Map<String, dynamic>
              ? raw
              : (raw is Map
                  ? Map<String, dynamic>.from(raw)
                  : <String, dynamic>{});
          final debit = (map['total_debit'] is num)
              ? (map['total_debit'] as num).toDouble()
              : 0.0;
          final credit = (map['total_credit'] is num)
              ? (map['total_credit'] as num).toDouble()
              : 0.0;
          final solde = (map['solde'] is num)
              ? (map['solde'] as num).toDouble()
              : (debit - credit);
          totalDebit += debit;
          totalCredit += credit;
          rows.add(BalanceRow(
            compte: map['compte']?.toString() ?? '',
            libelleCompte: map['libelle_compte']?.toString() ?? '',
            totalDebit: debit,
            totalCredit: credit,
            solde: solde,
          ));
        }
        final soldeFinal = (data['solde_final'] is num)
            ? (data['solde_final'] as num).toDouble()
            : (totalDebit - totalCredit);
        state = state.copyWith(
          rows: rows,
          totalDebit: totalDebit,
          totalCredit: totalCredit,
          soldeFinal: soldeFinal,
          isLoading: false,
        );
        return;
      }
      // Fallback : agrégation depuis le journal (une ligne "Caisse")
      await _loadBalanceFromJournal();
    } catch (_) {
      try {
        await _loadBalanceFromJournal();
      } catch (e) {
        state = state.copyWith(isLoading: false);
        rethrow;
      }
    }
  }

  Future<void> _loadBalanceFromJournal() async {
    final dateDebut = state.dateDebut;
    final dateFin = state.dateFin;
    if (dateDebut == null || dateFin == null) return;
    final res = await ApiService.getJournal(
      dateDebut: dateDebut,
      dateFin: dateFin,
      mois: state.mois,
      annee: state.annee,
    );
    if (res['success'] == true && res['data'] != null) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      final rawLignes = data['lignes'] is List ? data['lignes'] as List : [];
      double totalDebit = 0.0;
      double totalCredit = 0.0;
      for (final raw in rawLignes) {
        final map = raw is Map<String, dynamic>
            ? raw
            : (raw is Map
                ? Map<String, dynamic>.from(raw)
                : <String, dynamic>{});
        totalDebit += (map['entree'] is num)
            ? (map['entree'] as num).toDouble()
            : 0.0;
        totalCredit += (map['sortie'] is num)
            ? (map['sortie'] as num).toDouble()
            : 0.0;
      }
      final soldeFinal = (data['solde_final'] is num)
          ? (data['solde_final'] as num).toDouble()
          : 0.0;
      state = state.copyWith(
        rows: [
          BalanceRow(
            compte: '51',
            libelleCompte: 'Caisse (Journal)',
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            solde: soldeFinal,
          ),
        ],
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        soldeFinal: soldeFinal,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void setDateRange(String? debut, String? fin) {
    state = state.copyWith(
      dateDebut: debut,
      dateFin: fin,
      mois: null,
      annee: null,
    );
  }

  void setMonthYear(int? month, int? year) {
    if (month == null || year == null) return;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    state = state.copyWith(
      mois: month,
      annee: year,
      dateDebut: _formatDate(start),
      dateFin: _formatDate(end),
    );
  }
}
