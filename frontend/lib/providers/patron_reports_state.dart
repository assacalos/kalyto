import 'package:flutter/foundation.dart';

@immutable
class PatronReportsState {
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;
  final int devisCount;
  final double devisTotal;
  final int bordereauxCount;
  final double bordereauxTotal;
  final int facturesCount;
  final double facturesTotal;
  final int paiementsCount;
  final double paiementsTotal;
  final int depensesCount;
  final double depensesTotal;
  final int salairesCount;
  final double salairesTotal;
  final double beneficeNet;
  /// Créances par tranche d'âge (factures non soldées)
  final double creances0_30;
  final double creances31_60;
  final double creances61_90;
  final double creances90Plus;

  const PatronReportsState({
    required this.startDate,
    required this.endDate,
    this.isLoading = false,
    this.devisCount = 0,
    this.devisTotal = 0.0,
    this.bordereauxCount = 0,
    this.bordereauxTotal = 0.0,
    this.facturesCount = 0,
    this.facturesTotal = 0.0,
    this.paiementsCount = 0,
    this.paiementsTotal = 0.0,
    this.depensesCount = 0,
    this.depensesTotal = 0.0,
    this.salairesCount = 0,
    this.salairesTotal = 0.0,
    this.beneficeNet = 0.0,
    this.creances0_30 = 0.0,
    this.creances31_60 = 0.0,
    this.creances61_90 = 0.0,
    this.creances90Plus = 0.0,
  });

  PatronReportsState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    int? devisCount,
    double? devisTotal,
    int? bordereauxCount,
    double? bordereauxTotal,
    int? facturesCount,
    double? facturesTotal,
    int? paiementsCount,
    double? paiementsTotal,
    int? depensesCount,
    double? depensesTotal,
    int? salairesCount,
    double? salairesTotal,
    double? beneficeNet,
    double? creances0_30,
    double? creances31_60,
    double? creances61_90,
    double? creances90Plus,
  }) {
    return PatronReportsState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      devisCount: devisCount ?? this.devisCount,
      devisTotal: devisTotal ?? this.devisTotal,
      bordereauxCount: bordereauxCount ?? this.bordereauxCount,
      bordereauxTotal: bordereauxTotal ?? this.bordereauxTotal,
      facturesCount: facturesCount ?? this.facturesCount,
      facturesTotal: facturesTotal ?? this.facturesTotal,
      paiementsCount: paiementsCount ?? this.paiementsCount,
      paiementsTotal: paiementsTotal ?? this.paiementsTotal,
      depensesCount: depensesCount ?? this.depensesCount,
      depensesTotal: depensesTotal ?? this.depensesTotal,
      salairesCount: salairesCount ?? this.salairesCount,
      salairesTotal: salairesTotal ?? this.salairesTotal,
      beneficeNet: beneficeNet ?? this.beneficeNet,
      creances0_30: creances0_30 ?? this.creances0_30,
      creances31_60: creances31_60 ?? this.creances31_60,
      creances61_90: creances61_90 ?? this.creances61_90,
      creances90Plus: creances90Plus ?? this.creances90Plus,
    );
  }
}
