import 'dart:convert';
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/services/session_service.dart';
class PatronDashboardService {
  // Récupérer les données de validation en attente
  Future<Map<String, int>> getPendingValidations() async {
    try {
      final token = SessionService.getTokenSync();
      if (token == null || token.isEmpty) {
        return {
          'clients': 0,
          'proformas': 0,
          'bordereaux': 0,
          'factures': 0,
          'paiements': 0,
          'depenses': 0,
          'salaires': 0,
          'reporting': 0,
          'pointages': 0,
        };
      }

      // Compteurs pour les validations en attente (tous rôles confondus)
      int pendingClients = 0;
      int pendingDevis = 0;
      int pendingBordereaux = 0;
      int pendingFactures = 0;
      int pendingPaiements = 0;
      int pendingDepenses = 0;
      int pendingSalaires = 0;
      int pendingReporting = 0;
      int pendingPointages = 0;

      // Récupérer les clients en attente
      try {
        final clientsResponse = await HttpInterceptor.get(
          HttpInterceptor.apiUri('clients-list'),
        );
        if (clientsResponse.statusCode == 200) {
          final clientsData = json.decode(clientsResponse.body);
          List clientsList = [];
          if (clientsData is List) {
            clientsList = clientsData;
          } else if (clientsData is Map) {
            if (clientsData['data'] != null) {
              if (clientsData['data'] is List) {
                clientsList = clientsData['data'];
              } else if (clientsData['data'] is Map &&
                  clientsData['data']['data'] != null) {
                if (clientsData['data']['data'] is List) {
                  clientsList = clientsData['data']['data'];
                }
              }
            }
          }
          if (clientsList.isNotEmpty) {
          }
          pendingClients =
              clientsList
                  .where(
                    (client) =>
                        client['status'] == 0 || client['status'] == null,
                  )
                  .length; // 0 = en attente pour clients
        } else {
        }
      } catch (e) {
      }

      // Récupérer les devis en attente
      try {
        final devisResponse = await HttpInterceptor.get(
          HttpInterceptor.apiUri('devis-list'),
        );
        if (devisResponse.statusCode == 200) {
          final devisData = json.decode(devisResponse.body);
          List devisList = [];
          if (devisData is List) {
            devisList = devisData;
          } else if (devisData is Map) {
            if (devisData['data'] != null) {
              if (devisData['data'] is List) {
                devisList = devisData['data'];
              } else if (devisData['data'] is Map &&
                  devisData['data']['data'] != null) {
                if (devisData['data']['data'] is List) {
                  devisList = devisData['data']['data'];
                }
              }
            }
          }
          if (devisList.isNotEmpty) {
          }
          pendingDevis =
              devisList.where((devis) {
                final status = devis['status'];
                if (status == null) return false;
                // Gérer status comme int, String, ou num
                if (status is int) return status == 1;
                if (status is String) {
                  final parsed = int.tryParse(status.trim());
                  return parsed == 1;
                }
                if (status is num) return status.toInt() == 1;
                return false;
              }).length; // 1 = en attente
        } else {
        }
      } catch (e) {
      }

      // Récupérer les bordereaux en attente
      try {
        final bordereauxResponse = await HttpInterceptor.get(
          HttpInterceptor.apiUri('bordereaux-list'),
        );
        if (bordereauxResponse.statusCode == 200) {
          final bordereauxData = json.decode(bordereauxResponse.body);
          List bordereauxList = [];
          if (bordereauxData is List) {
            bordereauxList = bordereauxData;
          } else if (bordereauxData is Map) {
            if (bordereauxData['data'] != null) {
              if (bordereauxData['data'] is List) {
                bordereauxList = bordereauxData['data'];
              } else if (bordereauxData['data'] is Map &&
                  bordereauxData['data']['data'] != null) {
                if (bordereauxData['data']['data'] is List) {
                  bordereauxList = bordereauxData['data']['data'];
                }
              }
            }
          }
          if (bordereauxList.isNotEmpty) {
          }
          pendingBordereaux =
              bordereauxList.where((bordereau) {
                final status = bordereau['status'];
                if (status == null) return false;
                // Gérer status comme int, String, ou num
                if (status is int) return status == 1;
                if (status is String) {
                  final parsed = int.tryParse(status.trim());
                  return parsed == 1;
                }
                if (status is num) return status.toInt() == 1;
                return false;
              }).length; // 1 = en attente
        } else {
        }
      } catch (e) {
      }

      // Récupérer les factures en attente
      try {
        final facturesResponse = await HttpInterceptor.get(
          HttpInterceptor.apiUri('invoices-list'),
        );
        if (facturesResponse.statusCode == 200) {
          final facturesData = json.decode(facturesResponse.body);
          List facturesList = [];
          if (facturesData is List) {
            facturesList = facturesData;
          } else if (facturesData is Map) {
            if (facturesData['data'] != null) {
              if (facturesData['data'] is List) {
                facturesList = facturesData['data'];
              } else if (facturesData['data'] is Map &&
                  facturesData['data']['data'] != null) {
                if (facturesData['data']['data'] is List) {
                  facturesList = facturesData['data']['data'];
                }
              }
            }
          }
          if (facturesList.isNotEmpty) {
          }
          pendingFactures =
              facturesList
                  .where((facture) => facture['status'] == 'draft')
                  .length; // 'draft' = en attente
        } else {
        }
      } catch (e) {
      }

      // Récupérer TOUS les paiements (tous statuts) pour compter ceux en attente
      try {
        final paiementsResponse = await HttpInterceptor.get(
          HttpInterceptor.apiUri('payments-list'),
        );
        if (paiementsResponse.statusCode == 200) {
          final paiementsData = json.decode(paiementsResponse.body);
          List paiementsList = [];
          if (paiementsData is List) {
            paiementsList = paiementsData;
          } else if (paiementsData is Map) {
            if (paiementsData['data'] != null) {
              if (paiementsData['data'] is List) {
                paiementsList = paiementsData['data'];
              } else if (paiementsData['data'] is Map &&
                  paiementsData['data']['data'] != null) {
                if (paiementsData['data']['data'] is List) {
                  paiementsList = paiementsData['data']['data'];
                }
              }
            }
          }
          if (paiementsList.isNotEmpty) {
          }
          // Compter tous les paiements en attente (status = 'pending' ou 'submitted')
          pendingPaiements =
              paiementsList
                  .where(
                    (paiement) =>
                        paiement['status'] == 'pending' ||
                        paiement['status'] == 'submitted',
                  )
                  .length;
        } else {
        }
      } catch (e) {
      }

      // Récupérer TOUTES les dépenses (tous statuts) pour compter celles en attente
      try {
        final depensesResponse = await HttpInterceptor.get(
          HttpInterceptor.apiUri('expenses-list'),
        );
        if (depensesResponse.statusCode == 200) {
          final depensesData = json.decode(depensesResponse.body);
          List depensesList = [];
          if (depensesData is List) {
            depensesList = depensesData;
          } else if (depensesData is Map) {
            if (depensesData['data'] != null) {
              if (depensesData['data'] is List) {
                depensesList = depensesData['data'];
              } else if (depensesData['data'] is Map &&
                  depensesData['data']['data'] != null) {
                if (depensesData['data']['data'] is List) {
                  depensesList = depensesData['data']['data'];
                }
              }
            }
          }
          if (depensesList.isNotEmpty) {
          }
          // Compter toutes les dépenses en attente (status = 'pending')
          pendingDepenses =
              depensesList
                  .where((depense) => depense['status'] == 'pending')
                  .length;
        } else {
        }
      } catch (e) {
      }

      // Récupérer TOUS les salaires (tous statuts) pour compter ceux en attente
      try {
        final salariesResponse = await HttpInterceptor.get(
          HttpInterceptor.apiUri('salaries-list'),
        );
        if (salariesResponse.statusCode == 200) {
          final salariesData = json.decode(salariesResponse.body);
          List salariesList = [];
          if (salariesData is List) {
            salariesList = salariesData;
          } else if (salariesData is Map) {
            if (salariesData['data'] != null) {
              if (salariesData['data'] is List) {
                salariesList = salariesData['data'];
              } else if (salariesData['data'] is Map &&
                  salariesData['data']['data'] != null) {
                if (salariesData['data']['data'] is List) {
                  salariesList = salariesData['data']['data'];
                }
              }
            }
          }
          if (salariesList.isNotEmpty) {
          }
          // Compter tous les salaires en attente (status = 'pending')
          pendingSalaires =
              salariesList
                  .where((salary) => salary['status'] == 'pending')
                  .length;
        } else {
        }
      } catch (e) {
      }

      // Récupérer TOUS les rapports (tous statuts) pour compter ceux en attente
      try {
        final reportingResponse = await HttpInterceptor.get(
          HttpInterceptor.apiUri('reporting-list'),
        );
        if (reportingResponse.statusCode == 200) {
          final reportingData = json.decode(reportingResponse.body);
          List reportingList = [];
          if (reportingData is List) {
            reportingList = reportingData;
          } else if (reportingData is Map) {
            if (reportingData['data'] != null) {
              if (reportingData['data'] is List) {
                reportingList = reportingData['data'];
              } else if (reportingData['data'] is Map &&
                  reportingData['data']['data'] != null) {
                if (reportingData['data']['data'] is List) {
                  reportingList = reportingData['data']['data'];
                }
              }
            }
          }
          if (reportingList.isNotEmpty) {
          }
          // Compter tous les rapports en attente (status = 'submitted')
          pendingReporting =
              reportingList
                  .where((report) => report['status'] == 'submitted')
                  .length;
        } else {
        }
      } catch (e) {
      }

      // Récupérer TOUS les pointages (tous statuts) pour compter ceux en attente
      try {
        final pointagesResponse = await HttpInterceptor.get(
          HttpInterceptor.apiUri('attendance-punch-list'),
        );
        if (pointagesResponse.statusCode == 200) {
          final pointagesData = json.decode(pointagesResponse.body);
          List pointagesList = [];
          if (pointagesData is List) {
            pointagesList = pointagesData;
          } else if (pointagesData is Map) {
            if (pointagesData['data'] != null) {
              if (pointagesData['data'] is List) {
                pointagesList = pointagesData['data'];
              } else if (pointagesData['data'] is Map &&
                  pointagesData['data']['data'] != null) {
                if (pointagesData['data']['data'] is List) {
                  pointagesList = pointagesData['data']['data'];
                }
              }
            }
          }
          if (pointagesList.isNotEmpty) {
          }
          // Compter tous les pointages en attente (status = 'pending')
          pendingPointages =
              pointagesList
                  .where((pointage) => pointage['status'] == 'pending')
                  .length;
        } else {
        }
      } catch (e) {
      }

      final result = {
        'clients': pendingClients,
        'proformas': pendingDevis, // proformas = devis
        'bordereaux': pendingBordereaux,
        'factures': pendingFactures,
        'paiements': pendingPaiements,
        'depenses': pendingDepenses,
        'salaires': pendingSalaires,
        'reporting': pendingReporting,
        'pointages': pendingPointages,
      };
      return result;
    } catch (e) {
      return {
        'clients': 0,
        'proformas': 0,
        'bordereaux': 0,
        'factures': 0,
        'paiements': 0,
        'depenses': 0,
        'salaires': 0,
        'reporting': 0,
        'pointages': 0,
      };
    }
  }

  // Récupérer les métriques de performance
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final response = await HttpInterceptor.get(
        HttpInterceptor.apiUri('patron/dashboard/performance-metrics'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body)['data'];
        return {
          'validated_clients': data['validated_clients'] ?? 0,
          'total_employees': data['total_employees'] ?? 0,
          'total_suppliers': data['total_suppliers'] ?? 0,
          'total_revenue': (data['total_revenue'] ?? 0).toDouble(),
        };
      }
      throw Exception(
        'Erreur lors de la récupération des métriques: ${response.statusCode}',
      );
    } catch (e) {
      // Retourner des données par défaut en cas d'erreur
      return {
        'validated_clients': 0,
        'total_employees': 0,
        'total_suppliers': 0,
        'total_revenue': 0.0,
      };
    }
  }

  // Récupérer les données complètes du dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await HttpInterceptor.get(
        HttpInterceptor.apiUri('patron/dashboard/data'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception(
        'Erreur lors de la récupération des données du dashboard: ${response.statusCode}',
      );
    } catch (e) {
      // Retourner des données par défaut en cas d'erreur
      return {
        'pending_validations': {
          'clients': 0,
          'proformas': 0,
          'bordereaux': 0,
          'factures': 0,
          'paiements': 0,
          'depenses': 0,
          'salaires': 0,
          'reporting': 0,
          'pointages': 0,
        },
        'performance_metrics': {
          'validated_clients': 0,
          'total_employees': 0,
          'total_suppliers': 0,
          'total_revenue': 0.0,
        },
      };
    }
  }
}
