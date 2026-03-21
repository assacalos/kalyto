import 'package:flutter/foundation.dart';

@immutable
class JournalState {
  final Map<String, dynamic> journalData;
  final bool isLoading;
  final int? selectedMonth;
  final int? selectedYear;
  final String? dateDebut;
  final String? dateFin;

  const JournalState({
    this.journalData = const {},
    this.isLoading = false,
    this.selectedMonth,
    this.selectedYear,
    this.dateDebut,
    this.dateFin,
  });

  List<dynamic> get lignes =>
      journalData['lignes'] is List ? journalData['lignes'] as List : [];
  double get soldeInitial =>
      (journalData['solde_initial'] is num)
          ? (journalData['solde_initial'] as num).toDouble()
          : 0.0;
  double get soldeFinal =>
      (journalData['solde_final'] is num)
          ? (journalData['solde_final'] as num).toDouble()
          : 0.0;
  double get totalEntrees =>
      (journalData['total_entrees'] is num)
          ? (journalData['total_entrees'] as num).toDouble()
          : 0.0;
  double get totalSorties =>
      (journalData['total_sorties'] is num)
          ? (journalData['total_sorties'] as num).toDouble()
          : 0.0;

  JournalState copyWith({
    Map<String, dynamic>? journalData,
    bool? isLoading,
    int? selectedMonth,
    int? selectedYear,
    String? dateDebut,
    String? dateFin,
  }) {
    return JournalState(
      journalData: journalData ?? this.journalData,
      isLoading: isLoading ?? this.isLoading,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
    );
  }
}
