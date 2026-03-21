import 'package:flutter/foundation.dart';

/// Une ligne du grand livre : date, libellé, débit, crédit, solde courant.
@immutable
class GrandLivreLine {
  final String date;
  final String libelle;
  final double debit;
  final double credit;
  final double soldeCourant;

  const GrandLivreLine({
    required this.date,
    required this.libelle,
    required this.debit,
    required this.credit,
    required this.soldeCourant,
  });
}

@immutable
class GrandLivreState {
  final String? dateDebut;
  final String? dateFin;
  final String? compteCode;
  final List<GrandLivreLine> lignes;
  final double soldeInitial;
  final double soldeFinal;
  final bool isLoading;

  const GrandLivreState({
    this.dateDebut,
    this.dateFin,
    this.compteCode,
    this.lignes = const [],
    this.soldeInitial = 0.0,
    this.soldeFinal = 0.0,
    this.isLoading = false,
  });

  GrandLivreState copyWith({
    String? dateDebut,
    String? dateFin,
    String? compteCode,
    List<GrandLivreLine>? lignes,
    double? soldeInitial,
    double? soldeFinal,
    bool? isLoading,
  }) {
    return GrandLivreState(
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      compteCode: compteCode ?? this.compteCode,
      lignes: lignes ?? this.lignes,
      soldeInitial: soldeInitial ?? this.soldeInitial,
      soldeFinal: soldeFinal ?? this.soldeFinal,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
