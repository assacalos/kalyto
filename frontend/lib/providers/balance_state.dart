import 'package:flutter/foundation.dart';

/// Une ligne de la balance : compte, libellé, total débit, total crédit, solde.
@immutable
class BalanceRow {
  final String compte;
  final String libelleCompte;
  final double totalDebit;
  final double totalCredit;
  final double solde;

  const BalanceRow({
    required this.compte,
    required this.libelleCompte,
    required this.totalDebit,
    required this.totalCredit,
    required this.solde,
  });
}

@immutable
class BalanceState {
  final String? dateDebut;
  final String? dateFin;
  final int? mois;
  final int? annee;
  final List<BalanceRow> rows;
  final double totalDebit;
  final double totalCredit;
  final double soldeFinal;
  final bool isLoading;

  const BalanceState({
    this.dateDebut,
    this.dateFin,
    this.mois,
    this.annee,
    this.rows = const [],
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.soldeFinal = 0.0,
    this.isLoading = false,
  });

  BalanceState copyWith({
    String? dateDebut,
    String? dateFin,
    int? mois,
    int? annee,
    List<BalanceRow>? rows,
    double? totalDebit,
    double? totalCredit,
    double? soldeFinal,
    bool? isLoading,
  }) {
    return BalanceState(
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      mois: mois ?? this.mois,
      annee: annee ?? this.annee,
      rows: rows ?? this.rows,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      soldeFinal: soldeFinal ?? this.soldeFinal,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
