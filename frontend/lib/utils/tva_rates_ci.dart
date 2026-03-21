/// Taux de TVA en vigueur en Côte d'Ivoire.
/// Utilisé pour les factures et devis (FCFA).
class TvaRateCi {
  final double rate;
  final String label;

  const TvaRateCi({required this.rate, required this.label});

  @override
  String toString() => label;
}

/// Taux de TVA ivoiriens : 18% (normal), 10% (réduit), 0% (exonéré).
const List<TvaRateCi> tvaRatesCi = [
  TvaRateCi(rate: 18.0, label: 'TVA 18% (normal)'),
  TvaRateCi(rate: 10.0, label: 'TVA 10% (réduit)'),
  TvaRateCi(rate: 0.0, label: 'TVA 0% (exonéré)'),
];

/// Taux par défaut (normal).
const double tvaRateCiDefault = 18.0;

/// Valeurs numériques des taux autorisés (pour dropdown / validation).
const List<double> tvaRatesCiValues = [18.0, 10.0, 0.0];

/// Retourne le libellé pour un taux donné, ou [rate]% si hors liste.
String tvaRateLabelCi(double rate) {
  for (final e in tvaRatesCi) {
    if ((e.rate - rate).abs() < 0.01) return e.label;
  }
  return 'TVA ${rate.toStringAsFixed(0)}%';
}

/// Retourne true si [rate] est un des taux autorisés.
bool isAllowedTvaRateCi(double rate) {
  return tvaRatesCiValues.any((v) => (v - rate).abs() < 0.01);
}

/// Ramène [rate] au plus proche taux autorisé (priorité : 18, 10, 0).
double clampTvaRateCi(double rate) {
  if (isAllowedTvaRateCi(rate)) return rate;
  double closest = tvaRateCiDefault;
  double minDiff = (rate - closest).abs();
  for (final v in tvaRatesCiValues) {
    final d = (rate - v).abs();
    if (d < minDiff) {
      minDiff = d;
      closest = v;
    }
  }
  return closest;
}
