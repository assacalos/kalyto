import 'package:easyconnect/services/http_interceptor.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/utils/constant.dart';

class ComptableDashboardService {
  final storage = GetStorage();

  // Récupérer les entités en attente
  Future<Map<String, int>> getPendingEntities() async {
    try {
      final token = storage.read('token');
      int pendingFactures = 0;
      int pendingPaiements = 0;
      int pendingDepenses = 0;
      int pendingSalaires = 0;

      // Récupérer les factures en attente
      try {
        final facturesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/factures-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (facturesResponse.statusCode == 200) {
          final facturesData = json.decode(facturesResponse.body);
          if (facturesData is List) {
            pendingFactures =
                facturesData
                    .where((facture) => facture['status'] == 'draft')
                    .length; // 'draft' = en attente
          }
        }
      } catch (e) {}

      // Récupérer les paiements en attente
      try {
        final paiementsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/paiements-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (paiementsResponse.statusCode == 200) {
          final paiementsData = json.decode(paiementsResponse.body);
          if (paiementsData is List) {
            pendingPaiements =
                paiementsData
                    .where(
                      (paiement) =>
                          paiement['status'] == 'pending' ||
                          paiement['status'] == 'submitted',
                    )
                    .length; // 'pending' ou 'submitted' = en attente
          }
        }
      } catch (e) {}

      // Récupérer les dépenses en attente
      try {
        final depensesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/depenses-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (depensesResponse.statusCode == 200) {
          final depensesData = json.decode(depensesResponse.body);
          if (depensesData is List) {
            pendingDepenses =
                depensesData
                    .where((depense) => depense['status'] == 'pending')
                    .length; // 'pending' = en attente
          }
        }
      } catch (e) {}

      // Récupérer les salaires en attente
      try {
        final salariesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/salaires-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (salariesResponse.statusCode == 200) {
          final salariesData = json.decode(salariesResponse.body);
          if (salariesData is List) {
            pendingSalaires =
                salariesData
                    .where((salary) => salary['status'] == 'pending')
                    .length; // 'pending' = en attente
          }
        }
      } catch (e) {}

      return {
        'factures': pendingFactures,
        'paiements': pendingPaiements,
        'depenses': pendingDepenses,
        'salaires': pendingSalaires,
      };
    } catch (e) {
      return {'factures': 0, 'paiements': 0, 'depenses': 0, 'salaires': 0};
    }
  }

  // Récupérer les entités validées
  Future<Map<String, int>> getValidatedEntities() async {
    try {
      final token = storage.read('token');
      int validatedFactures = 0;
      int validatedPaiements = 0;
      int validatedDepenses = 0;
      int validatedSalaires = 0;

      // Récupérer les factures validées
      try {
        final facturesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/factures-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (facturesResponse.statusCode == 200) {
          final facturesData = json.decode(facturesResponse.body);
          if (facturesData is List) {
            validatedFactures =
                facturesData
                    .where(
                      (facture) =>
                          facture['status'] == 'sent' ||
                          facture['status'] == 'paid',
                    )
                    .length; // 'sent' ou 'paid' = validé
          }
        }
      } catch (e) {}

      // Récupérer les paiements validés
      try {
        final paiementsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/paiements-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (paiementsResponse.statusCode == 200) {
          final paiementsData = json.decode(paiementsResponse.body);
          if (paiementsData is List) {
            validatedPaiements =
                paiementsData
                    .where(
                      (paiement) =>
                          paiement['status'] == 'approved' ||
                          paiement['status'] == 'paid',
                    )
                    .length; // 'approved' ou 'paid' = validé
          }
        }
      } catch (e) {}

      // Récupérer les dépenses validées
      try {
        final depensesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/depenses-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (depensesResponse.statusCode == 200) {
          final depensesData = json.decode(depensesResponse.body);
          if (depensesData is List) {
            validatedDepenses =
                depensesData
                    .where((depense) => depense['status'] == 'approved')
                    .length; // 'approved' = validé
          }
        }
      } catch (e) {}

      // Récupérer les salaires validés
      try {
        final salariesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/salaires-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (salariesResponse.statusCode == 200) {
          final salariesData = json.decode(salariesResponse.body);
          if (salariesData is List) {
            validatedSalaires =
                salariesData
                    .where(
                      (salary) =>
                          salary['status'] == 'approved' ||
                          salary['status'] == 'paid',
                    )
                    .length; // 'approved' ou 'paid' = validé
          }
        }
      } catch (e) {}

      return {
        'factures': validatedFactures,
        'paiements': validatedPaiements,
        'depenses': validatedDepenses,
        'salaires': validatedSalaires,
      };
    } catch (e) {
      return {'factures': 0, 'paiements': 0, 'depenses': 0, 'salaires': 0};
    }
  }

  // Récupérer les statistiques montants
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final token = storage.read('token');
      double totalRevenue = 0.0;
      double totalPayments = 0.0;
      double totalExpenses = 0.0;
      double totalSalaries = 0.0;

      // Calculer le chiffre d'affaires total à partir des factures validées
      try {
        final facturesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/factures-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (facturesResponse.statusCode == 200) {
          final facturesData = json.decode(facturesResponse.body);
          if (facturesData is List) {
            for (var facture in facturesData) {
              final status =
                  facture['status']?.toString().toLowerCase().trim() ?? '';
              if (status == 'valide' ||
                  status == 'validated' ||
                  status == 'approved') {
                // Status validé
                totalRevenue +=
                    double.tryParse(
                      facture['total_amount']?.toString() ?? '0',
                    ) ??
                    0;
              }
            }
          }
        }
      } catch (e) {}

      // Calculer le total des paiements
      try {
        final paiementsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/paiements-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (paiementsResponse.statusCode == 200) {
          final paiementsData = json.decode(paiementsResponse.body);
          if (paiementsData is List) {
            for (var paiement in paiementsData) {
              if (paiement['status'] == 'approved' ||
                  paiement['status'] == 'paid') {
                // Status validé
                totalPayments +=
                    double.tryParse(paiement['amount']?.toString() ?? '0') ?? 0;
              }
            }
          }
        }
      } catch (e) {}

      // Calculer le total des dépenses
      try {
        final depensesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/depenses-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (depensesResponse.statusCode == 200) {
          final depensesData = json.decode(depensesResponse.body);
          if (depensesData is List) {
            for (var depense in depensesData) {
              if (depense['status'] == 'approved') {
                // Status validé
                totalExpenses +=
                    double.tryParse(depense['amount']?.toString() ?? '0') ?? 0;
              }
            }
          }
        }
      } catch (e) {}

      // Calculer le total des salaires
      try {
        final salariesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/salaires-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (salariesResponse.statusCode == 200) {
          final salariesData = json.decode(salariesResponse.body);
          if (salariesData is List) {
            for (var salary in salariesData) {
              if (salary['status'] == 'approved' ||
                  salary['status'] == 'paid') {
                // Status validé
                totalSalaries +=
                    double.tryParse(salary['amount']?.toString() ?? '0') ?? 0;
              }
            }
          }
        }
      } catch (e) {}

      double netProfit = totalRevenue - totalExpenses - totalSalaries;

      return {
        'total_revenue': totalRevenue,
        'total_payments': totalPayments,
        'total_expenses': totalExpenses,
        'total_salaries': totalSalaries,
        'net_profit': netProfit,
      };
    } catch (e) {
      return {
        'total_revenue': 0.0,
        'total_payments': 0.0,
        'total_expenses': 0.0,
        'total_salaries': 0.0,
        'net_profit': 0.0,
      };
    }
  }

  // Récupérer les données complètes du dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/comptable/dashboard/data'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception(
        'Erreur lors de la récupération des données du dashboard: ${response.statusCode}',
      );
    } catch (e) {
      return {
        'pending_entities': {
          'factures': 0,
          'paiements': 0,
          'depenses': 0,
          'salaires': 0,
        },
        'validated_entities': {
          'factures': 0,
          'paiements': 0,
          'depenses': 0,
          'salaires': 0,
        },
        'statistics': {
          'total_revenue': 0.0,
          'total_payments': 0.0,
          'total_expenses': 0.0,
          'total_salaries': 0.0,
          'net_profit': 0.0,
        },
      };
    }
  }
}
