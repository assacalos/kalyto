import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/utils/constant.dart';

class RhDashboardService {
  final storage = GetStorage();

  // Récupérer les entités en attente
  Future<Map<String, int>> getPendingEntities() async {
    try {
      final token = storage.read('token');
      int pendingLeaves = 0;
      int pendingRecruitments = 0;
      int pendingAttendance = 0;
      int pendingSalaries = 0;

      // Récupérer les congés en attente
      try {
        final leavesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/api/leaves-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (leavesResponse.statusCode == 200) {
          final leavesData = json.decode(leavesResponse.body);
          if (leavesData is List) {
            pendingLeaves =
                leavesData
                    .where((leave) => leave['status'] == 'pending')
                    .length; // 'pending' = en attente
          }
        }
      } catch (e) {
      }

      // Récupérer les recrutements en attente
      try {
        final recruitmentsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/api/recruitments-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (recruitmentsResponse.statusCode == 200) {
          final recruitmentsData = json.decode(recruitmentsResponse.body);
          if (recruitmentsData is List) {
            pendingRecruitments =
                recruitmentsData
                    .where((recruitment) => recruitment['status'] == 'draft')
                    .length; // 'draft' = en attente
          }
        }
      } catch (e) {
      }

      // Récupérer les pointages en attente
      try {
        final attendanceResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/api/attendance-punch-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (attendanceResponse.statusCode == 200) {
          final attendanceData = json.decode(attendanceResponse.body);
          if (attendanceData is List) {
            pendingAttendance =
                attendanceData
                    .where((attendance) => attendance['status'] == 'pending')
                    .length; // 'pending' = en attente
          }
        }
      } catch (e) {
      }

      // Récupérer les salaires en attente
      try {
        final salariesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/api/salaries-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (salariesResponse.statusCode == 200) {
          final salariesData = json.decode(salariesResponse.body);
          if (salariesData is List) {
            pendingSalaries =
                salariesData
                    .where((salary) => salary['status'] == 'pending')
                    .length; // 'pending' = en attente
          }
        }
      } catch (e) {
      }

      return {
        'leaves': pendingLeaves,
        'recruitments': pendingRecruitments,
        'attendance': pendingAttendance,
        'salaries': pendingSalaries,
      };
    } catch (e) {
      return {'leaves': 0, 'recruitments': 0, 'attendance': 0, 'salaries': 0};
    }
  }

  // Récupérer les entités validées
  Future<Map<String, int>> getValidatedEntities() async {
    try {
      final token = storage.read('token');
      int validatedEmployees = 0;
      int validatedLeaves = 0;
      int validatedRecruitments = 0;
      int validatedSalaries = 0;

      // Récupérer les employés validés
      try {
        final employeesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/api/employees-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (employeesResponse.statusCode == 200) {
          final employeesData = json.decode(employeesResponse.body);
          if (employeesData is List) {
            validatedEmployees =
                employeesData
                    .where((employee) => employee['status'] == 1)
                    .length;
          }
        }
      } catch (e) {
      }

      // Récupérer les congés validés
      try {
        final leavesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/api/leaves-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (leavesResponse.statusCode == 200) {
          final leavesData = json.decode(leavesResponse.body);
          if (leavesData is List) {
            validatedLeaves =
                leavesData
                    .where((leave) => leave['status'] == 'approved')
                    .length; // 'approved' = validé
          }
        }
      } catch (e) {
      }

      // Récupérer les recrutements validés
      try {
        final recruitmentsResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/api/recruitments-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (recruitmentsResponse.statusCode == 200) {
          final recruitmentsData = json.decode(recruitmentsResponse.body);
          if (recruitmentsData is List) {
            validatedRecruitments =
                recruitmentsData
                    .where(
                      (recruitment) => recruitment['status'] == 'published',
                    )
                    .length; // 'published' = validé
          }
        }
      } catch (e) {
      }

      // Récupérer les salaires validés
      try {
        final salariesResponse = await HttpInterceptor.get(
          Uri.parse('$baseUrl/api/salaries-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (salariesResponse.statusCode == 200) {
          final salariesData = json.decode(salariesResponse.body);
          if (salariesData is List) {
            validatedSalaries =
                salariesData
                    .where(
                      (salary) =>
                          salary['status'] == 'approved' ||
                          salary['status'] == 'paid',
                    )
                    .length; // 'approved' ou 'paid' = validé
          }
        }
      } catch (e) {
      }

      return {
        'employees': validatedEmployees,
        'leaves': validatedLeaves,
        'recruitments': validatedRecruitments,
        'salaries': validatedSalaries,
      };
    } catch (e) {
      return {'employees': 0, 'leaves': 0, 'recruitments': 0, 'salaries': 0};
    }
  }

  // Récupérer les statistiques montants
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/rh/dashboard/statistics'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body)['data'];
        return {
          'total_salary_mass': (data['total_salary_mass'] ?? 0).toDouble(),
          'total_bonuses': (data['total_bonuses'] ?? 0).toDouble(),
          'recruitment_cost': (data['recruitment_cost'] ?? 0).toDouble(),
          'training_cost': (data['training_cost'] ?? 0).toDouble(),
        };
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      return {
        'total_salary_mass': 0.0,
        'total_bonuses': 0.0,
        'recruitment_cost': 0.0,
        'training_cost': 0.0,
      };
    }
  }

  // Récupérer les données complètes du dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/rh/dashboard/data'),
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
          'leaves': 0,
          'recruitments': 0,
          'attendance': 0,
          'salaries': 0,
        },
        'validated_entities': {
          'employees': 0,
          'leaves': 0,
          'recruitments': 0,
          'salaries': 0,
        },
        'statistics': {
          'total_salary_mass': 0.0,
          'total_bonuses': 0.0,
          'recruitment_cost': 0.0,
          'training_cost': 0.0,
        },
      };
    }
  }
}
