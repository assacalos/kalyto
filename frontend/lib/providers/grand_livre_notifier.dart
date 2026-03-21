import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/grand_livre_state.dart';
import 'package:easyconnect/services/api_service.dart';

final grandLivreProvider =
    NotifierProvider<GrandLivreNotifier, GrandLivreState>(GrandLivreNotifier.new);

class GrandLivreNotifier extends Notifier<GrandLivreState> {
  @override
  GrandLivreState build() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return GrandLivreState(
      dateDebut: _formatDate(start),
      dateFin: _formatDate(end),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> loadGrandLivre() async {
    final dateDebut = state.dateDebut;
    final dateFin = state.dateFin;
    if (dateDebut == null || dateFin == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.getJournal(
        dateDebut: dateDebut,
        dateFin: dateFin,
      );
      if (res['success'] == true && res['data'] != null) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final rawLignes = data['lignes'] is List ? data['lignes'] as List : [];
        final soldeInitial = (data['solde_initial'] is num)
            ? (data['solde_initial'] as num).toDouble()
            : 0.0;
        final List<GrandLivreLine> lignes = [];
        double soldeCourant = soldeInitial;
        for (final raw in rawLignes) {
          final map = raw is Map<String, dynamic> ? raw : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
          final entree = (map['entree'] is num) ? (map['entree'] as num).toDouble() : 0.0;
          final sortie = (map['sortie'] is num) ? (map['sortie'] as num).toDouble() : 0.0;
          final debit = entree;
          final credit = sortie;
          soldeCourant = soldeCourant + debit - credit;
          lignes.add(GrandLivreLine(
            date: map['date']?.toString() ?? '',
            libelle: map['libelle']?.toString() ?? '',
            debit: debit,
            credit: credit,
            soldeCourant: soldeCourant,
          ));
        }
        final soldeFinal = (data['solde_final'] is num)
            ? (data['solde_final'] as num).toDouble()
            : soldeCourant;
        state = state.copyWith(
          lignes: lignes,
          soldeInitial: soldeInitial,
          soldeFinal: soldeFinal,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void setDateRange(String? debut, String? fin) {
    state = state.copyWith(dateDebut: debut, dateFin: fin);
  }

  void setCompte(String? code) {
    state = state.copyWith(compteCode: code);
  }
}
