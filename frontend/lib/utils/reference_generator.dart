/// Utilitaire pour générer automatiquement les références
class ReferenceGenerator {
  /// Génère une référence de facture
  /// Format: FACT-YYYY-NNNN (ex: FACT-2025-0001)
  static String generateInvoiceReference() {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Utiliser les 4 derniers chiffres du timestamp pour l'unicité
    final uniqueId = timestamp.toString().substring(
      timestamp.toString().length - 4,
    );
    return 'FACT-$year-$uniqueId';
  }

  /// Génère une référence de paiement
  /// Format: PAY-YYYY-NNNN (ex: PAY-2025-0001)
  static String generatePaymentReference() {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = timestamp.toString().substring(
      timestamp.toString().length - 4,
    );
    return 'PAY-$year-$uniqueId';
  }

  /// Génère une référence de bon de commande
  /// Format: BC-YYYY-NNNN (ex: BC-2025-0001)
  static String generateBonCommandeReference() {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = timestamp.toString().substring(
      timestamp.toString().length - 4,
    );
    return 'BC-$year-$uniqueId';
  }

  /// Génère un numéro de commande fournisseur
  /// Format: BCF-YYYY-NNNN (ex: BCF-2025-0001)
  static String generateBonDeCommandeFournisseurReference() {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = timestamp.toString().substring(
      timestamp.toString().length - 4,
    );
    return 'BCF-$year-$uniqueId';
  }

  /// Génère une référence avec incrément basée sur une liste existante
  /// Format: [prefix]-YYYY-[increment]
  static String generateReferenceWithIncrement(
    String prefix,
    List<String> existingReferences,
  ) {
    final year = DateTime.now().year;
    final pattern = RegExp('^$prefix-$year-(\\d+)\$');

    // Extraire tous les numéros existants pour cette année
    final existingNumbers =
        existingReferences.where((ref) => pattern.hasMatch(ref)).map((ref) {
          final match = pattern.firstMatch(ref);
          return int.tryParse(match?.group(1) ?? '0') ?? 0;
        }).toList();

    // Trouver le prochain numéro disponible
    final nextNumber =
        existingNumbers.isEmpty
            ? 1
            : (existingNumbers.reduce((a, b) => a > b ? a : b) + 1);

    // Formater avec 4 chiffres (ex: 0001, 0002, etc.)
    final formattedNumber = nextNumber.toString().padLeft(4, '0');
    return '$prefix-$year-$formattedNumber';
  }
}
