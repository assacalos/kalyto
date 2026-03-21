import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import '../Models/attendance_punch_model.dart';
import '../Models/pagination_response.dart';
import '../services/location_service.dart';
import '../services/camera_service.dart';
import '../utils/constant.dart';
import '../utils/app_config.dart';
import '../services/api_service.dart';
import '../utils/auth_error_handler.dart';
import '../utils/logger.dart';
import '../utils/retry_helper.dart';
import '../utils/pagination_helper.dart';
import 'storage_service.dart';

class AttendancePunchService {
  static final AttendancePunchService _instance =
      AttendancePunchService._internal();
  factory AttendancePunchService() => _instance;
  AttendancePunchService._internal();

  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();

  // Enregistrer un pointage avec photo et géolocalisation
  Future<Map<String, dynamic>> punchAttendance({
    required String type,
    required File photo,
    String? notes,
  }) async {
    try {
      final locationInfo = await _locationService.getLocationInfo();
      if (locationInfo == null) {
        throw Exception('Impossible d\'obtenir la localisation');
      }

      await _cameraService.validateImage(photo);

      final endpoint =
          type == 'check_in'
              ? '/attendances/check-in'
              : '/attendances/check-out';
      final url = '$baseUrl$endpoint';

      final request = http.MultipartRequest('POST', Uri.parse(url));

      final headers = ApiService.headers();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      request.fields['latitude'] = locationInfo.latitude.toString();
      request.fields['longitude'] = locationInfo.longitude.toString();
      if (locationInfo.address.isNotEmpty) {
        request.fields['address'] = locationInfo.address;
      }
      request.fields['accuracy'] = locationInfo.accuracy.toString();
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        filename: 'attendance_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
        AppConfig.extraLongTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas (envoi du pointage)'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        AttendancePunchModel? attendanceData;
        if (responseData['data'] != null) {
          try {
            attendanceData = AttendancePunchModel.fromJson(
              responseData['data'],
            );
          } catch (e) {
            // Ignorer l'erreur de parsing
          }
        } else if (responseData['attendance'] != null) {
          try {
            attendanceData = AttendancePunchModel.fromJson(
              responseData['attendance'],
            );
          } catch (e) {
            // Ignorer l'erreur de parsing
          }
        }

        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Pointage enregistré avec succès et soumis pour validation',
          'data': attendanceData,
        };
      } else if (response.statusCode == 500) {
        // Pour l'erreur 500, vérifier si le pointage a quand même été créé
        try {
          final errorData = jsonDecode(response.body);

          // Chercher un ID dans différents emplacements possibles
          int? attendanceId;
          Map<String, dynamic>? attendanceDataMap;

          if (errorData is Map) {
            // Chercher dans data.attendance.id ou data.id
            if (errorData['data'] != null && errorData['data'] is Map) {
              final data = errorData['data'] as Map;
              if (data['attendance'] != null && data['attendance'] is Map) {
                final attendanceObj = data['attendance'] as Map;
                if (attendanceObj['id'] != null) {
                  attendanceId =
                      attendanceObj['id'] is int
                          ? attendanceObj['id']
                          : int.tryParse(attendanceObj['id'].toString());
                  attendanceDataMap = Map<String, dynamic>.from(attendanceObj);
                }
              } else if (data['id'] != null) {
                attendanceId =
                    data['id'] is int
                        ? data['id']
                        : int.tryParse(data['id'].toString());
                attendanceDataMap = Map<String, dynamic>.from(data);
              }
            }
            // Chercher directement dans la racine
            else if (errorData['attendance'] != null &&
                errorData['attendance'] is Map) {
              final attendanceObj = errorData['attendance'] as Map;
              if (attendanceObj['id'] != null) {
                attendanceId =
                    attendanceObj['id'] is int
                        ? attendanceObj['id']
                        : int.tryParse(attendanceObj['id'].toString());
                attendanceDataMap = Map<String, dynamic>.from(attendanceObj);
              }
            }
            // Chercher directement l'ID à la racine
            else if (errorData['id'] != null) {
              attendanceId =
                  errorData['id'] is int
                      ? errorData['id']
                      : int.tryParse(errorData['id'].toString());
              attendanceDataMap = Map<String, dynamic>.from(errorData);
            }
          }

          // Si un ID a été trouvé, considérer que la création a réussi
          if (attendanceId != null) {
            AttendancePunchModel? attendanceData;
            if (attendanceDataMap != null) {
              try {
                attendanceData = AttendancePunchModel.fromJson(
                  attendanceDataMap,
                );
              } catch (e) {
                // Construire un pointage minimal avec l'ID et les données disponibles
                try {
                  final now = DateTime.now();
                  attendanceData = AttendancePunchModel.fromJson({
                    'id': attendanceId,
                    'user_id': 0, // Sera rempli par le backend
                    'type': type,
                    'timestamp': now.toIso8601String(),
                    'latitude': locationInfo.latitude,
                    'longitude': locationInfo.longitude,
                    'address': locationInfo.address,
                    'accuracy': locationInfo.accuracy,
                    'status': 'pending',
                    'created_at': now.toIso8601String(),
                    'updated_at': now.toIso8601String(),
                  });
                } catch (e2) {}
              }
            } else {
              // Construire un pointage minimal avec l'ID et les données disponibles
              try {
                final now = DateTime.now();
                attendanceData = AttendancePunchModel.fromJson({
                  'id': attendanceId,
                  'user_id': 0, // Sera rempli par le backend
                  'type': type,
                  'timestamp': now.toIso8601String(),
                  'latitude': locationInfo.latitude,
                  'longitude': locationInfo.longitude,
                  'address': locationInfo.address,
                  'accuracy': locationInfo.accuracy,
                  'status': 'pending',
                  'created_at': now.toIso8601String(),
                  'updated_at': now.toIso8601String(),
                });
              } catch (e) {}
            }

            if (attendanceData != null) {
              return {
                'success': true,
                'message':
                    'Pointage enregistré avec succès (malgré une erreur serveur)',
                'data': attendanceData,
              };
            }
          } else {}
        } catch (e) {
          // Ignorer l'erreur
        }

        // Si pas d'ID trouvé, vérifier si le pointage a quand même été créé
        // en cherchant les pointages récents du même type
        try {
          // Attendre un peu pour que le backend termine la création
          await Future.delayed(const Duration(milliseconds: 1000));

          final now = DateTime.now();
          AttendancePunchModel? foundAttendance;

          // Stratégie 1: Chercher tous les pointages du même type (sans filtre de date)
          try {
            final allAttendances = await getAttendances(type: type);

            // Chercher le pointage le plus récent du même type créé dans les 10 dernières minutes
            AttendancePunchModel? mostRecentAttendance;
            for (var attendance in allAttendances) {
              final timeDiff = now.difference(attendance.timestamp).inMinutes;
              if (timeDiff <= 10 && attendance.type == type) {
                // Garder le pointage le plus récent du même type
                if (mostRecentAttendance == null ||
                    attendance.timestamp.isAfter(
                      mostRecentAttendance.timestamp,
                    )) {
                  mostRecentAttendance = attendance;
                }

                // Vérifier aussi la localisation si disponible (approximative)
                final latDiff =
                    (attendance.latitude - locationInfo.latitude).abs();
                final lonDiff =
                    (attendance.longitude - locationInfo.longitude).abs();
                // Si la différence de localisation est inférieure à 0.01 degré (environ 1km), c'est probablement le même pointage
                if (latDiff < 0.01 && lonDiff < 0.01 && timeDiff <= 5) {
                  foundAttendance = attendance;
                  break;
                }
              }
            }

            // Si aucun pointage avec localisation correspondante, utiliser le plus récent du même type
            if (foundAttendance == null && mostRecentAttendance != null) {
              final timeDiff =
                  now.difference(mostRecentAttendance.timestamp).inMinutes;
              if (timeDiff <= 5) {
                foundAttendance = mostRecentAttendance;
              }
            }
          } catch (e) {
            // Ignorer l'erreur
          }

          // Stratégie 2: Si stratégie 1 n'a rien trouvé, chercher avec filtre de date
          if (foundAttendance == null) {
            try {
              final dateFrom =
                  now
                      .subtract(const Duration(minutes: 10))
                      .toIso8601String()
                      .split('T')[0];
              final dateTo = now.toIso8601String().split('T')[0];

              final recentAttendances = await getAttendances(
                type: type,
                dateFrom: dateFrom,
                dateTo: dateTo,
              );

              // Chercher le pointage le plus récent
              for (var attendance in recentAttendances) {
                final timeDiff = now.difference(attendance.timestamp).inMinutes;
                if (timeDiff <= 10 && attendance.type == type) {
                  if (foundAttendance == null ||
                      attendance.timestamp.isAfter(foundAttendance.timestamp)) {
                    foundAttendance = attendance;
                  }
                }
              }
            } catch (e) {
              // Ignorer l'erreur
            }
          }

          if (foundAttendance != null && foundAttendance.id != null) {
            return {
              'success': true,
              'message':
                  'Pointage enregistré avec succès (malgré une erreur serveur)',
              'data': foundAttendance,
            };
          } else {}
        } catch (e) {
          // Ignorer l'erreur
        }

        // Si pas trouvé, c'est une vraie erreur
        String errorMessage =
            'Erreur serveur lors de l\'enregistrement du pointage (500)';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // Ignorer
        }

        return {'success': false, 'message': errorMessage, 'status_code': 500};
      } else {
        String errorMessage = 'Erreur lors du pointage';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;

          // Gestion spécifique de l'erreur 403 (Accès refusé)
          if (response.statusCode == 403) {
            final message = errorData['message'] ?? 'Accès refusé';

            // Si le message contient "rôle" ou "role", c'est probablement un problème de permissions
            if (message.toLowerCase().contains('rôle') ||
                message.toLowerCase().contains('role') ||
                message.toLowerCase().contains('accès refusé')) {
              errorMessage =
                  'Accès refusé. Le pointage est autorisé pour tous les employés. '
                  'Si vous êtes RH, vous devriez pouvoir pointer. '
                  'Vérifiez vos permissions avec l\'administrateur.';
            } else {
              errorMessage = message;
            }
          } else if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorList = errors.values.expand((e) => e as List).join(', ');
            errorMessage = errorList.isNotEmpty ? errorList : errorMessage;
          }
        } catch (e) {
          errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
        }

        return {
          'success': false,
          'message': errorMessage,
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Erreur lors de l\'enregistrement du pointage: ${e.toString()}',
      };
    }
  }

  // Vérifier si l'utilisateur peut pointer (statut actuel)
  // MODIFICATION: Plus de restrictions - toujours autoriser le pointage
  Future<Map<String, dynamic>> canPunch({String type = 'check_in'}) async {
    // MODIFICATION: Toujours autoriser le pointage sans condition
    final typeLabel = type == 'check_in' ? 'arrivée' : 'départ';

    return {
      'success': true,
      'can_punch': true,
      'message': 'Vous pouvez pointer votre $typeLabel',
      'current_status': null,
    };

    /* CODE ANCIEN (désactivé) - Gardé pour référence si besoin de réactiver
    try {
      final url = '$baseUrl/attendances/current-status?type=$type';

      print('🔵 [ATTENDANCE_PUNCH_SERVICE] ===== DÉBUT canPunch =====');
      print('🔵 [ATTENDANCE_PUNCH_SERVICE] URL: $url');
      print('🔵 [ATTENDANCE_PUNCH_SERVICE] Type demandé: $type');
      http.Response response;
      try {
        response = await HttpInterceptor.get(
          Uri.parse(url),
          headers: ApiService.headers(),
        );
      } catch (e) {
        print('🔴 [ATTENDANCE_PUNCH_SERVICE] Erreur lors de l\'appel API: $e');
        // En cas d'erreur serveur, autoriser le pointage
        return {
          'success': true,
          'can_punch': true,
          'message': 'Vous pouvez pointer maintenant',
        };
      }

      print('🔵 [ATTENDANCE_PUNCH_SERVICE] Status Code: ${response.statusCode}');
      print('🔵 [ATTENDANCE_PUNCH_SERVICE] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('🔵 [ATTENDANCE_PUNCH_SERVICE] Result: $result');

        bool canPunchValue = false;
        String message = '';
        String? currentStatus;

        // Si le backend retourne directement can_punch, l'utiliser (le backend a la logique finale)
        if (result['can_punch'] != null) {
          canPunchValue = result['can_punch'] ?? false;
          message =
              result['message'] ??
              (canPunchValue
                  ? 'Vous pouvez pointer maintenant'
                  : 'Vous ne pouvez pas pointer maintenant');
          print('🔵 [ATTENDANCE_PUNCH_SERVICE] can_punch direct du backend: $canPunchValue');
          print('🔵 [ATTENDANCE_PUNCH_SERVICE] message du backend: $message');
        } else if (result['data'] != null) {
          final data = result['data'];
          print('🔵 [ATTENDANCE_PUNCH_SERVICE] Data: $data');

          // Si le backend retourne can_punch dans data, l'utiliser (le backend a la logique finale)
          if (data['can_punch'] != null) {
            canPunchValue = data['can_punch'] ?? false;
            message =
                data['message'] ??
                (canPunchValue
                    ? 'Vous pouvez pointer maintenant'
                    : 'Vous ne pouvez pas pointer maintenant');
            print('🔵 [ATTENDANCE_PUNCH_SERVICE] can_punch dans data du backend: $canPunchValue');
            print('🔵 [ATTENDANCE_PUNCH_SERVICE] message dans data: $message');
          } else if (data is Map) {
            // Vérifier si c'est vraiment un pointage vide ou si c'est juste une structure vide du backend
            // Le backend peut retourner une structure avec tous les champs null même s'il y a un pointage
            final hasCheckInTime = data['check_in_time'] != null;
            final hasCheckOutTime = data['check_out_time'] != null;
            final hasId = data['id'] != null;
            final hasStatus = data['status'] != null;
            final hasType = data['type'] != null;
            
            print('🔵 [ATTENDANCE_PUNCH_SERVICE] Vérification pointage: hasId=$hasId, hasStatus=$hasStatus, hasType=$hasType, hasCheckInTime=$hasCheckInTime, hasCheckOutTime=$hasCheckOutTime');
            
            // Si aucun indicateur de pointage n'est présent, c'est qu'il n'y a vraiment pas de pointage
            // OU le backend ne retourne pas les données correctement
            if (!hasId && !hasStatus && !hasType && !hasCheckInTime && !hasCheckOutTime &&
                data['user'] == null && data['approver'] == null) {
              // Le backend retourne tous les champs null - cela peut signifier :
              // 1. Il n'y a vraiment pas de pointage
              // 2. Le backend ne retourne pas les données correctement
              // On fait une requête supplémentaire pour récupérer le dernier pointage
              print('🔵 [ATTENDANCE_PUNCH_SERVICE] Tous les champs sont null, récupération du dernier pointage...');
              try {
                final lastAttendances = await getAttendances();
                if (lastAttendances.isNotEmpty) {
                  final lastAttendance = lastAttendances.first;
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Dernier pointage trouvé: ID=${lastAttendance.id}, Type=${lastAttendance.type}, Status=${lastAttendance.status}');
                  
                  // Utiliser le dernier pointage pour déterminer si on peut pointer
                  final lastType = lastAttendance.type.toLowerCase();
                  final lastStatus = lastAttendance.status.toLowerCase();
                  
                  if (lastType == 'check_in' || lastType == 'arrivée' || lastType == 'arrivee') {
                    // Il y a une arrivée, permettre le départ
                    canPunchValue = type == 'check_out';
                    message = canPunchValue
                        ? 'Vous pouvez pointer votre départ'
                        : 'Vous avez déjà pointé votre arrivée. Vous pouvez pointer votre départ.';
                    currentStatus = lastStatus;
                    print('🔵 [ATTENDANCE_PUNCH_SERVICE] Arrivée trouvée via getAttendances, permettre départ');
                  } else if (lastType == 'check_out' || lastType == 'départ' || lastType == 'depart') {
                    // Il y a un départ, permettre l'arrivée
                    canPunchValue = type == 'check_in';
                    message = canPunchValue
                        ? 'Vous pouvez pointer votre arrivée'
                        : 'Vous avez déjà pointé votre départ. Vous pouvez pointer votre arrivée.';
                    currentStatus = lastStatus;
                    print('🔵 [ATTENDANCE_PUNCH_SERVICE] Départ trouvé via getAttendances, permettre arrivée');
                  } else {
                    // Type inconnu, autoriser check_in par défaut
                    canPunchValue = type == 'check_in';
                    message = canPunchValue
                        ? 'Vous pouvez pointer votre arrivée'
                        : 'Vous devez d\'abord pointer votre arrivée';
                    currentStatus = 'no_attendance';
                    print('🔵 [ATTENDANCE_PUNCH_SERVICE] Type inconnu dans dernier pointage, autoriser check_in');
                  }
                } else {
                  // Vraiment aucun pointage trouvé
                  canPunchValue = type == 'check_in';
                  message = canPunchValue
                      ? 'Vous pouvez pointer votre arrivée'
                      : 'Vous devez d\'abord pointer votre arrivée';
                  currentStatus = 'no_attendance';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Aucun pointage trouvé via getAttendances, autoriser check_in uniquement');
                }
              } catch (e) {
                print('🔴 [ATTENDANCE_PUNCH_SERVICE] Erreur lors de la récupération du dernier pointage: $e');
                // En cas d'erreur, autoriser check_in par défaut
                canPunchValue = type == 'check_in';
                message = canPunchValue
                    ? 'Vous pouvez pointer votre arrivée'
                    : 'Vous devez d\'abord pointer votre arrivée';
                currentStatus = 'no_attendance';
                print('🔵 [ATTENDANCE_PUNCH_SERVICE] Erreur, autoriser check_in par défaut');
              }
            } else {
              // Il y a des indicateurs de pointage, traiter comme un pointage existant
              final status = data['status'] ?? result['status'];
              final lastType = data['type']?.toString().toLowerCase() ?? 
                               (hasCheckInTime && !hasCheckOutTime ? 'check_in' : 
                                hasCheckOutTime ? 'check_out' : '');
              currentStatus = status?.toString();
              
              print('🔵 [ATTENDANCE_PUNCH_SERVICE] Pointage détecté via check_in_time/check_out_time');
              print('🔵 [ATTENDANCE_PUNCH_SERVICE] Status: $status, Last Type: $lastType');
              print('🔵 [ATTENDANCE_PUNCH_SERVICE] Type demandé: $type');
              
              // Continuer avec la logique normale de traitement du pointage
              if (status == null) {
                // Pas de statut mais il y a un pointage (peut-être en attente de traitement)
                if (hasCheckInTime && !hasCheckOutTime) {
                  // Il y a une arrivée mais pas de départ
                  canPunchValue = type == 'check_out';
                  message = canPunchValue
                      ? 'Vous pouvez pointer votre départ'
                      : 'Vous avez déjà pointé votre arrivée. Vous pouvez pointer votre départ.';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Arrivée détectée (via check_in_time), permettre départ');
                } else if (hasCheckOutTime) {
                  // Il y a un départ
                  canPunchValue = type == 'check_in';
                  message = canPunchValue
                      ? 'Vous pouvez pointer votre arrivée'
                      : 'Vous avez déjà pointé votre départ. Vous pouvez pointer votre arrivée.';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Départ détecté (via check_out_time), permettre arrivée');
                } else {
                  canPunchValue = type == 'check_in';
                  message = canPunchValue
                      ? 'Vous pouvez pointer votre arrivée'
                      : 'Vous devez d\'abord pointer votre arrivée';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Pointage détecté mais type inconnu, autoriser check_in par défaut');
                }
              } else {
                // Il y a un statut, utiliser la logique normale
                final statusStr = status.toString();
                final normalizedStatus = statusStr.toLowerCase().trim();
                
                // CORRECTION: Le backend permet maintenant le départ même si l'arrivée est en pending
                // Donc on permet le départ si l'arrivée est en pending
                if (normalizedStatus == 'pending' ||
                    normalizedStatus == 'en_attente' ||
                    normalizedStatus == 'en attente') {
                  // Vérifier le type du dernier pointage
                  final lastTypeLower = lastType.toLowerCase();
                  if (lastTypeLower == 'check_in' ||
                      lastTypeLower == 'arrivée' ||
                      lastTypeLower == 'arrivee' ||
                      (hasCheckInTime && !hasCheckOutTime)) {
                    // Si le dernier pointage est une arrivée (même en pending), permettre le départ
                    // Le backend a été modifié pour permettre cela
                    canPunchValue = type == 'check_out';
                    message = canPunchValue
                        ? 'Vous pouvez pointer votre départ'
                        : 'Vous avez déjà pointé votre arrivée. Vous pouvez pointer votre départ.';
                    print('🔵 [ATTENDANCE_PUNCH_SERVICE] Arrivée en pending, permettre départ (backend modifié)');
                  } else if (lastTypeLower == 'check_out' ||
                      lastTypeLower == 'départ' ||
                      lastTypeLower == 'depart' ||
                      hasCheckOutTime) {
                    // Si le dernier pointage est un départ en pending, permettre l'arrivée pour le jour suivant
                    // ou bloquer selon la logique métier
                    canPunchValue = type == 'check_in';
                    message = canPunchValue
                        ? 'Vous pouvez pointer votre arrivée'
                        : 'Vous avez un pointage de départ en attente. Vous pouvez pointer votre arrivée pour un nouveau jour.';
                    print('🔵 [ATTENDANCE_PUNCH_SERVICE] Départ en pending, permettre arrivée si type=check_in');
                  } else {
                    // Type inconnu, permettre selon le type demandé
                    canPunchValue = type == 'check_in';
                    message = canPunchValue
                        ? 'Vous pouvez pointer votre arrivée'
                        : 'Vous pouvez pointer votre départ';
                    print('🔵 [ATTENDANCE_PUNCH_SERVICE] Type inconnu en pending, permettre selon type demandé');
                  }
                } else if (normalizedStatus == 'rejected' ||
                    normalizedStatus == 'rejeté' ||
                    normalizedStatus == 'rejete') {
                  canPunchValue = type == 'check_in';
                  message =
                      canPunchValue
                          ? 'Votre dernier pointage a été rejeté. Vous pouvez pointer votre arrivée.'
                          : 'Votre dernier pointage a été rejeté. Vous devez d\'abord pointer votre arrivée.';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Pointage rejeté, autoriser check_in');
                } else if (normalizedStatus == 'approved' ||
                    normalizedStatus == 'approuvé' ||
                    normalizedStatus == 'approuve' ||
                    normalizedStatus == 'valide' ||
                    normalizedStatus == 'validé') {
                  if (lastType == 'check_in' ||
                      lastType == 'arrivée' ||
                      lastType == 'arrivee' ||
                      (hasCheckInTime && !hasCheckOutTime)) {
                    canPunchValue = type == 'check_out';
                    message =
                        canPunchValue
                            ? 'Vous pouvez pointer votre départ'
                            : 'Vous avez déjà pointé votre arrivée. Vous pouvez pointer votre départ.';
                    print('🔵 [ATTENDANCE_PUNCH_SERVICE] Arrivée approuvée, permettre départ si type=check_out');
                  } else if (lastType == 'check_out' ||
                      lastType == 'départ' ||
                      lastType == 'depart' ||
                      hasCheckOutTime) {
                    canPunchValue = type == 'check_in';
                    message =
                        canPunchValue
                            ? 'Vous pouvez pointer votre arrivée'
                            : 'Vous avez déjà pointé votre départ. Vous pouvez pointer votre arrivée.';
                    print('🔵 [ATTENDANCE_PUNCH_SERVICE] Départ approuvé, permettre arrivée si type=check_in');
                  } else {
                    canPunchValue = type == 'check_in';
                    message =
                        canPunchValue
                            ? 'Vous pouvez pointer votre arrivée'
                            : 'Vous devez d\'abord pointer votre arrivée';
                    print('🔵 [ATTENDANCE_PUNCH_SERVICE] Type inconnu, autoriser check_in par défaut');
                  }
                } else if (normalizedStatus == 'checked_in' ||
                    normalizedStatus == 'checked_out') {
                  if (type == 'check_in') {
                    canPunchValue = normalizedStatus != 'checked_in';
                  } else if (type == 'check_out') {
                    canPunchValue = normalizedStatus == 'checked_in';
                  }
                  message =
                      canPunchValue
                          ? 'Vous pouvez pointer maintenant'
                          : 'Vous ne pouvez pas pointer maintenant';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Status checked_in/checked_out, canPunch: $canPunchValue');
                } else {
                  canPunchValue = type == 'check_in';
                  message =
                      canPunchValue
                          ? 'Vous pouvez pointer votre arrivée'
                          : 'Vous devez d\'abord pointer votre arrivée';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Status inconnu ($normalizedStatus), autoriser check_in par défaut');
                }
              }
            }
          } else {
            final status = data['status'] ?? result['status'];
            final lastType = data['type']?.toString().toLowerCase() ?? '';
            currentStatus = status?.toString();

            print('🔵 [ATTENDANCE_PUNCH_SERVICE] Status: $status');
            print('🔵 [ATTENDANCE_PUNCH_SERVICE] Last Type: $lastType');
            print('🔵 [ATTENDANCE_PUNCH_SERVICE] Type demandé: $type');

            if (status == null) {
              canPunchValue = type == 'check_in';
              message =
                  canPunchValue
                      ? 'Vous pouvez pointer votre arrivée'
                      : 'Vous devez d\'abord pointer votre arrivée';
              print('🔵 [ATTENDANCE_PUNCH_SERVICE] Status null, autoriser check_in');
            } else {
              final statusStr = status.toString();
              final normalizedStatus = statusStr.toLowerCase().trim();

              // CORRECTION: Le backend permet maintenant le départ même si l'arrivée est en pending
              // Donc on permet le départ si l'arrivée est en pending
              if (normalizedStatus == 'pending' ||
                  normalizedStatus == 'en_attente' ||
                  normalizedStatus == 'en attente') {
                // Vérifier le type du dernier pointage
                final lastTypeLower = lastType.toLowerCase();
                if (lastTypeLower == 'check_in' ||
                    lastTypeLower == 'arrivée' ||
                    lastTypeLower == 'arrivee') {
                  // Si le dernier pointage est une arrivée (même en pending), permettre le départ
                  // Le backend a été modifié pour permettre cela
                  canPunchValue = type == 'check_out';
                  message = canPunchValue
                      ? 'Vous pouvez pointer votre départ'
                      : 'Vous avez déjà pointé votre arrivée. Vous pouvez pointer votre départ.';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Arrivée en pending, permettre départ (backend modifié)');
                } else if (lastTypeLower == 'check_out' ||
                    lastTypeLower == 'départ' ||
                    lastTypeLower == 'depart') {
                  // Si le dernier pointage est un départ en pending, permettre l'arrivée pour le jour suivant
                  // ou bloquer selon la logique métier
                  canPunchValue = type == 'check_in';
                  message = canPunchValue
                      ? 'Vous pouvez pointer votre arrivée'
                      : 'Vous avez un pointage de départ en attente. Vous pouvez pointer votre arrivée pour un nouveau jour.';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Départ en pending, permettre arrivée si type=check_in');
                } else {
                  // Type inconnu, permettre selon le type demandé
                  canPunchValue = type == 'check_in';
                  message = canPunchValue
                      ? 'Vous pouvez pointer votre arrivée'
                      : 'Vous pouvez pointer votre départ';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Type inconnu en pending, permettre selon type demandé');
                }
              } else if (normalizedStatus == 'rejected' ||
                  normalizedStatus == 'rejeté' ||
                  normalizedStatus == 'rejete') {
                canPunchValue = type == 'check_in';
                message =
                    canPunchValue
                        ? 'Votre dernier pointage a été rejeté. Vous pouvez pointer votre arrivée.'
                        : 'Votre dernier pointage a été rejeté. Vous devez d\'abord pointer votre arrivée.';
                print('🔵 [ATTENDANCE_PUNCH_SERVICE] Pointage rejeté, autoriser check_in');
              } else if (normalizedStatus == 'approved' ||
                  normalizedStatus == 'approuvé' ||
                  normalizedStatus == 'approuve' ||
                  normalizedStatus == 'valide' ||
                  normalizedStatus == 'validé') {
                if (lastType == 'check_in' ||
                    lastType == 'arrivée' ||
                    lastType == 'arrivee') {
                  canPunchValue = type == 'check_out';
                  message =
                      canPunchValue
                          ? 'Vous pouvez pointer votre départ'
                          : 'Vous avez déjà pointé votre arrivée. Vous pouvez pointer votre départ.';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Arrivée approuvée, permettre départ si type=check_out');
                } else if (lastType == 'check_out' ||
                    lastType == 'départ' ||
                    lastType == 'depart') {
                  canPunchValue = type == 'check_in';
                  message =
                      canPunchValue
                          ? 'Vous pouvez pointer votre arrivée'
                          : 'Vous avez déjà pointé votre départ. Vous pouvez pointer votre arrivée.';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Départ approuvé, permettre arrivée si type=check_in');
                } else {
                  canPunchValue = type == 'check_in';
                  message =
                      canPunchValue
                          ? 'Vous pouvez pointer votre arrivée'
                          : 'Vous devez d\'abord pointer votre arrivée';
                  print('🔵 [ATTENDANCE_PUNCH_SERVICE] Type inconnu, autoriser check_in par défaut');
                }
              } else if (normalizedStatus == 'checked_in' ||
                  normalizedStatus == 'checked_out') {
                if (type == 'check_in') {
                  canPunchValue = normalizedStatus != 'checked_in';
                } else if (type == 'check_out') {
                  canPunchValue = normalizedStatus == 'checked_in';
                }
                message =
                    canPunchValue
                        ? 'Vous pouvez pointer maintenant'
                        : 'Vous ne pouvez pas pointer maintenant';
                print('🔵 [ATTENDANCE_PUNCH_SERVICE] Status checked_in/checked_out, canPunch: $canPunchValue');
              } else {
                canPunchValue = type == 'check_in';
                message =
                    canPunchValue
                        ? 'Vous pouvez pointer votre arrivée'
                        : 'Vous devez d\'abord pointer votre arrivée';
                print('🔵 [ATTENDANCE_PUNCH_SERVICE] Status inconnu ($normalizedStatus), autoriser check_in par défaut');
              }
            }
          }
        } else {
          canPunchValue = type == 'check_in';
          message = 'Statut non disponible, pointage autorisé';
          print('🔵 [ATTENDANCE_PUNCH_SERVICE] Pas de données, autoriser check_in par défaut');
        }

        print('🔵 [ATTENDANCE_PUNCH_SERVICE] Résultat final: canPunch=$canPunchValue, message=$message');
        print('🔵 [ATTENDANCE_PUNCH_SERVICE] ===== FIN canPunch =====');

        return {
          'success': true,
          'can_punch': canPunchValue,
          'message': message,
          'current_status': currentStatus,
        };
      } else {
        String errorMessage = 'Erreur lors de la vérification du statut';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
        }

        print('🔴 [ATTENDANCE_PUNCH_SERVICE] Erreur HTTP ${response.statusCode}: $errorMessage');
        // En cas d'erreur serveur, autoriser le pointage pour éviter les blocages
        return {
          'success': true,
          'can_punch': true,
          'message': 'Vous pouvez pointer maintenant',
        };
      }
    } catch (e, stackTrace) {
      print('🔴 [ATTENDANCE_PUNCH_SERVICE] Exception: $e');
      print('🔴 [ATTENDANCE_PUNCH_SERVICE] StackTrace: $stackTrace');
      // En cas d'erreur, autoriser le pointage pour éviter les blocages
      return {
        'success': true,
        'can_punch': true,
        'message': 'Vous pouvez pointer maintenant',
      };
    }
    */
  }

  /// Point d'entrée unique pour la lecture : pointages avec pagination.
  Future<PaginationResponse<AttendancePunchModel>> getAttendancesPaginated({
    String? status,
    String? type,
    int? userId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
      if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('${AppConfig.baseUrl}/attendances').replace(
        queryParameters: queryParams,
      );
      AppLogger.httpRequest('GET', uri.toString(), tag: 'ATTENDANCE_PUNCH_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation: () => http
            .get(uri, headers: ApiService.headers())
            .timeout(
              AppConfig.defaultTimeout,
              onTimeout: () =>
                  throw Exception('Timeout: le serveur ne répond pas'),
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'ATTENDANCE_PUNCH_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PaginationHelper.parseResponseSafe<AttendancePunchModel>(
          json: data,
          fromJsonT: (json) {
            try {
              return AttendancePunchModel.fromJson(json);
            } catch (_) {
              return null;
            }
          },
        );
        if (page == 1 && result.data.isNotEmpty) {
          _saveAttendancesToHive(result.data);
        }
        return result;
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des pointages: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getAttendancesPaginated: $e',
        tag: 'ATTENDANCE_PUNCH_SERVICE',
      );
      rethrow;
    }
  }

  /// Liste des pointages : délègue à getAttendancesPaginated (page 1, perPage 500).
  Future<List<AttendancePunchModel>> getAttendances({
    String? status,
    String? type,
    int? userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final res = await getAttendancesPaginated(
        status: status,
        type: type,
        userId: userId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: 1,
        perPage: 500,
      );
      if (res.data.isNotEmpty) {
        _saveAttendancesToHive(res.data);
      }
      return res.data;
    } catch (e) {
      AppLogger.error(
        'Erreur getAttendances: $e',
        tag: 'ATTENDANCE_PUNCH_SERVICE',
      );
      return [];
    }
  }

  // Obtenir les pointages en attente
  Future<List<AttendancePunchModel>> getPendingAttendances() async {
    return await getAttendances(status: 'pending');
  }

  // Approuver un pointage
  Future<Map<String, dynamic>> approveAttendance(int attendanceId) async {
    try {
      var response = await http
          .post(
            Uri.parse('$baseUrl/attendances-validate/$attendanceId'),
            headers: ApiService.headers(jsonContent: true),
            body: jsonEncode({'comment': ''}),
          )
          .timeout(
            AppConfig.defaultTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          );

      if (response.statusCode == 500 || response.statusCode == 400) {
        response = await http
            .put(
              Uri.parse('$baseUrl/attendances/$attendanceId'),
              headers: ApiService.headers(jsonContent: true),
              body: jsonEncode({
                'status': 'valide',
                'validated_by': null,
                'validated_at': null,
              }),
            )
            .timeout(
              AppConfig.defaultTimeout,
              onTimeout: () =>
                  throw Exception('Timeout: le serveur ne répond pas'),
            );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        AttendancePunchModel? updatedAttendance;
        if (data['data'] != null) {
          try {
            updatedAttendance = AttendancePunchModel.fromJson(data['data']);
          } catch (e) {
            // Ignorer l'erreur de parsing
          }
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Pointage approuvé avec succès',
          'data': updatedAttendance,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur lors de l\'approbation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de l\'approbation: ${e.toString()}',
      };
    }
  }

  // Rejeter un pointage
  Future<Map<String, dynamic>> rejectAttendance(
    int attendanceId,
    String reason,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/attendances-reject/$attendanceId'),
            headers: ApiService.headers(jsonContent: true),
            body: jsonEncode({'reason': reason}),
          )
          .timeout(
            AppConfig.defaultTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        AttendancePunchModel? updatedAttendance;
        if (data['data'] != null) {
          try {
            updatedAttendance = AttendancePunchModel.fromJson(data['data']);
          } catch (e) {
            // Ignorer l'erreur de parsing
          }
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Pointage rejeté avec succès',
          'data': updatedAttendance,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur lors du rejet',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors du rejet: ${e.toString()}',
      };
    }
  }

  static void _saveAttendancesToHive(List<AttendancePunchModel> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyAttendances,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des pointages pour affichage instantané.
  static List<AttendancePunchModel> getCachedAttendances() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyAttendances);
      return raw.map((e) => AttendancePunchModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Résumé des présences par employé (semaine / mois / année). Pour le patron.
  /// Retourne { success, period, period_label, date_debut, date_fin, employees: [{ user_id, nom_complet, presence_count }] }
  Future<Map<String, dynamic>> getPresenceSummary({
    required String period,
    int? year,
    int? month,
    int? week,
  }) async {
    try {
      final now = DateTime.now();
      year ??= now.year;
      month ??= now.month;
      week ??= _isoWeek(now);

      final query = <String, String>{
        'period': period,
        'year': year.toString(),
        if (period == 'month') 'month': month.toString(),
        if (period == 'week') 'week': week.toString(),
      };
      final qs = query.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final url = '$baseUrl/attendances-presence-summary?$qs';

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['success'] == true)) {
        return Map<String, dynamic>.from(data);
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors du chargement des présences',
        'employees': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
        'employees': <Map<String, dynamic>>[],
      };
    }
  }

  static int _isoWeek(DateTime d) {
    final thursday = d.add(Duration(days: 4 - d.weekday % 7));
    final jan1 = DateTime(thursday.year, 1, 1);
    return 1 + (thursday.difference(jan1).inDays / 7).floor();
  }
}
