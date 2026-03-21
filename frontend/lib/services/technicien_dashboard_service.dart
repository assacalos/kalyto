import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/utils/constant.dart';

class TechnicienDashboardService {
  final storage = GetStorage();

  // Récupérer les entités en attente
  Future<Map<String, int>> getPendingEntities() async {
    try {
      final token = storage.read('token');
      int pendingInterventions = 0;
      int pendingMaintenance = 0;
      int pendingReports = 0;
      int pendingEquipments = 0;

      // Récupérer les interventions en attente
      try {
        final interventionsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/interventions-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (interventionsResponse.statusCode == 200) {
          final interventionsData = json.decode(interventionsResponse.body);
          if (interventionsData is List) {
            pendingInterventions =
                interventionsData
                    .where(
                      (intervention) => intervention['status'] == 'pending',
                    )
                    .length; // 'pending' = en attente
          }
        }
      } catch (e) {
      }

      // Récupérer les équipements nécessitant une maintenance
      try {
        final equipmentsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/equipments/needing-maintenance'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (equipmentsResponse.statusCode == 200) {
          final equipmentsData = json.decode(equipmentsResponse.body);
          if (equipmentsData is List) {
            pendingMaintenance = equipmentsData.length;
          }
        }
      } catch (e) {
      }

      // Récupérer les rapports en attente (utiliser les interventions comme proxy)
      try {
        final reportsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/interventions-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (reportsResponse.statusCode == 200) {
          final reportsData = json.decode(reportsResponse.body);
          if (reportsData is List) {
            pendingReports =
                reportsData
                    .where((report) => report['status'] == 'pending')
                    .length; // 'pending' = en attente
          }
        }
      } catch (e) {
      }

      // Récupérer les équipements en attente
      try {
        final equipmentsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/equipments'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (equipmentsResponse.statusCode == 200) {
          final equipmentsData = json.decode(equipmentsResponse.body);
          if (equipmentsData is List) {
            pendingEquipments =
                equipmentsData
                    .where((equipment) => equipment['status'] == 0)
                    .length;
          }
        }
      } catch (e) {
      }

      return {
        'interventions': pendingInterventions,
        'maintenance': pendingMaintenance,
        'reports': pendingReports,
        'equipments': pendingEquipments,
      };
    } catch (e) {
      return {
        'interventions': 0,
        'maintenance': 0,
        'reports': 0,
        'equipments': 0,
      };
    }
  }

  // Récupérer les entités validées
  Future<Map<String, int>> getValidatedEntities() async {
    try {
      final token = storage.read('token');
      int validatedInterventions = 0;
      int validatedMaintenance = 0;
      int validatedReports = 0;
      int validatedEquipments = 0;

      // Récupérer les interventions validées
      try {
        final interventionsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/interventions-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (interventionsResponse.statusCode == 200) {
          final interventionsData = json.decode(interventionsResponse.body);
          if (interventionsData is List) {
            validatedInterventions =
                interventionsData
                    .where(
                      (intervention) =>
                          intervention['status'] == 'approved' ||
                          intervention['status'] == 'completed',
                    )
                    .length; // 'approved' ou 'completed' = validé
          }
        }
      } catch (e) {
      }

      // Récupérer les équipements opérationnels
      try {
        final equipmentsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/equipments'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (equipmentsResponse.statusCode == 200) {
          final equipmentsData = json.decode(equipmentsResponse.body);
          if (equipmentsData is List) {
            validatedMaintenance =
                equipmentsData
                    .where((equipment) => equipment['status'] == 1)
                    .length;
            validatedEquipments =
                equipmentsData
                    .where((equipment) => equipment['status'] == 1)
                    .length;
          }
        }
      } catch (e) {
      }

      // Récupérer les rapports validés (utiliser les interventions comme proxy)
      try {
        final reportsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/interventions-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (reportsResponse.statusCode == 200) {
          final reportsData = json.decode(reportsResponse.body);
          if (reportsData is List) {
            validatedReports =
                reportsData
                    .where(
                      (report) =>
                          report['status'] == 'approved' ||
                          report['status'] == 'completed',
                    )
                    .length; // 'approved' ou 'completed' = validé
          }
        }
      } catch (e) {
      }

      return {
        'interventions': validatedInterventions,
        'maintenance': validatedMaintenance,
        'reports': validatedReports,
        'equipments': validatedEquipments,
      };
    } catch (e) {
      return {
        'interventions': 0,
        'maintenance': 0,
        'reports': 0,
        'equipments': 0,
      };
    }
  }

  // Récupérer les statistiques montants
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final token = storage.read('token');
      double interventionCost = 0.0;
      double maintenanceCost = 0.0;
      double equipmentValue = 0.0;
      double savings = 0.0;

      // Calculer le coût des interventions
      try {
        final interventionsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/interventions-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (interventionsResponse.statusCode == 200) {
          final interventionsData = json.decode(interventionsResponse.body);
          if (interventionsData is List) {
            for (var intervention in interventionsData) {
              if (intervention['status'] == 'approved' ||
                  intervention['status'] == 'completed') {
                // Status validé
                interventionCost +=
                    double.tryParse(intervention['cost']?.toString() ?? '0') ??
                    0;
              }
            }
          }
        }
      } catch (e) {
      }

      // Calculer le coût de maintenance
      try {
        final equipmentsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/equipments'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (equipmentsResponse.statusCode == 200) {
          final equipmentsData = json.decode(equipmentsResponse.body);
          if (equipmentsData is List) {
            for (var equipment in equipmentsData) {
              if (equipment['status'] == 1) {
                // Status opérationnel
                maintenanceCost +=
                    double.tryParse(
                      equipment['maintenance_cost']?.toString() ?? '0',
                    ) ??
                    0;
                equipmentValue +=
                    double.tryParse(equipment['value']?.toString() ?? '0') ?? 0;
              }
            }
          }
        }
      } catch (e) {
      }

      // Calculer les économies (différence entre coût préventif et correctif)
      savings = maintenanceCost * 0.3; // Estimation des économies

      return {
        'intervention_cost': interventionCost,
        'maintenance_cost': maintenanceCost,
        'equipment_value': equipmentValue,
        'savings': savings,
      };
    } catch (e) {
      return {
        'intervention_cost': 0.0,
        'maintenance_cost': 0.0,
        'equipment_value': 0.0,
        'savings': 0.0,
      };
    }
  }

  // Récupérer les données complètes du dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/technicien/dashboard/data'),
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
          'interventions': 0,
          'maintenance': 0,
          'reports': 0,
          'equipments': 0,
        },
        'validated_entities': {
          'interventions': 0,
          'maintenance': 0,
          'reports': 0,
          'equipments': 0,
        },
        'statistics': {
          'intervention_cost': 0.0,
          'maintenance_cost': 0.0,
          'equipment_value': 0.0,
          'savings': 0.0,
        },
      };
    }
  }
}
