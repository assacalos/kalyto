import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/providers/reporting_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/router/app_router.dart' show rootGoRouter;

final reportingProvider =
    NotifierProvider<ReportingNotifier, ReportingState>(ReportingNotifier.new);

class ReportingNotifier extends Notifier<ReportingState> {
  final ReportingService _reportingService = ReportingService();
  bool _isLoadingInProgress = false;

  int? get _userRole => ref.read(authProvider).user?.role;
  int? get _userId => ref.read(authProvider).user?.id;

  @override
  ReportingState build() {
    return ReportingState();
  }

  ReportingModel? _findReport(int id) {
    for (final r in state.reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> loadReports({int page = 1, bool forceRefresh = false}) async {
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;

    if (page == 1) {
      state = state.copyWith(isLoading: true);
      final hiveList = ReportingService.getCachedReporting();
      if (hiveList.isNotEmpty && !forceRefresh) {
        state = state.copyWith(reports: hiveList, isLoading: false);
        _isLoadingInProgress = false;
        Future.microtask(() => _refreshFromApi());
        return;
      }
      state = state.copyWith(reports: []);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final paginatedResponse = await _reportingService.getReportsPaginated(
        startDate: state.startDate,
        endDate: state.endDate,
        userRole: state.selectedUserRole,
        userId: (_userRole == Roles.ADMIN || _userRole == Roles.PATRON) ? null : _userId,
        page: page,
        perPage: state.perPage,
      );

      List<ReportingModel> filteredData = paginatedResponse.data;
      if (_userRole != Roles.ADMIN && _userRole != Roles.PATRON && _userId != null) {
        filteredData = paginatedResponse.data.where((r) => r.userId == _userId).toList();
      }

      if (page == 1) {
        state = state.copyWith(
          reports: filteredData,
          isLoading: false,
          currentPage: paginatedResponse.meta.currentPage,
          lastPage: paginatedResponse.meta.lastPage,
          totalItems: paginatedResponse.meta.total,
        );
        ReportingService.saveCachedReporting(filteredData);
      } else {
        state = state.copyWith(
          reports: [...state.reports, ...filteredData],
          isLoadingMore: false,
          currentPage: paginatedResponse.meta.currentPage,
          lastPage: paginatedResponse.meta.lastPage,
          totalItems: paginatedResponse.meta.total,
        );
      }
    } catch (e) {
      if (page == 1) {
        try {
          if (_userRole == Roles.ADMIN || _userRole == Roles.PATRON) {
            final allReports = await _reportingService.getAllReports(
              startDate: state.startDate,
              endDate: state.endDate,
              userRole: state.selectedUserRole,
            );
            state = state.copyWith(
              reports: allReports,
              isLoading: false,
              totalItems: allReports.length,
              lastPage: 1,
            );
            if (allReports.isNotEmpty) ReportingService.saveCachedReporting(allReports);
          } else if (_userId != null) {
            final userReports = await _reportingService.getUserReports(
              userId: _userId!,
              startDate: state.startDate,
              endDate: state.endDate,
            );
            final filtered = userReports.where((r) => r.userId == _userId).toList();
            state = state.copyWith(
              reports: filtered,
              isLoading: false,
              totalItems: filtered.length,
              lastPage: 1,
            );
            if (filtered.isNotEmpty) ReportingService.saveCachedReporting(filtered);
          } else {
            throw e;
          }
        } catch (_) {
          if (state.reports.isEmpty) {
            final fallback = ReportingService.getCachedReporting();
            if (fallback.isNotEmpty) {
              state = state.copyWith(reports: fallback, isLoading: false);
            } else {
              state = state.copyWith(isLoading: false);
              rethrow;
            }
          } else {
            state = state.copyWith(isLoading: false);
          }
        }
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } finally {
      _isLoadingInProgress = false;
    }
  }

  Future<void> _refreshFromApi() async {
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;
    try {
      final paginatedResponse = await _reportingService.getReportsPaginated(
        startDate: state.startDate,
        endDate: state.endDate,
        userRole: state.selectedUserRole,
        userId: (_userRole == Roles.ADMIN || _userRole == Roles.PATRON) ? null : _userId,
        page: 1,
        perPage: state.perPage,
      );
      List<ReportingModel> filteredData = paginatedResponse.data;
      if (_userRole != Roles.ADMIN && _userRole != Roles.PATRON && _userId != null) {
        filteredData = paginatedResponse.data.where((r) => r.userId == _userId).toList();
      }
      state = state.copyWith(
        reports: filteredData,
        currentPage: paginatedResponse.meta.currentPage,
        lastPage: paginatedResponse.meta.lastPage,
        totalItems: paginatedResponse.meta.total,
      );
      if (filteredData.isNotEmpty) ReportingService.saveCachedReporting(filteredData);
    } catch (_) {}
    _isLoadingInProgress = false;
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadReports(page: state.currentPage + 1);
    }
  }

  void updateDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    loadReports();
  }

  void filterByUserRole(String? role) {
    state = state.copyWith(selectedUserRole: role);
    loadReports();
  }

  /// [data] doit contenir: reportDate, nature, nomSociete, nomPersonne, moyenContact,
  /// et optionnellement contactSociete, contactPersonne, produitDemarche, commentaire, typeRelance, relanceDateHeure.
  Future<void> createReport(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = _userId!;
      final userRole = Roles.getRoleName(_userRole);
      final reportDate = data['reportDate'] as DateTime;
      final nature = data['nature'] as String;
      final nomSociete = data['nomSociete'] as String;
      final nomPersonne = data['nomPersonne'] as String;
      final moyenContact = data['moyenContact'] as String;

      final response = await _reportingService.createReport(
        userId: userId,
        userRole: userRole,
        reportDate: reportDate,
        nature: nature,
        nomSociete: nomSociete,
        contactSociete: data['contactSociete'] as String?,
        nomPersonne: nomPersonne,
        contactPersonne: data['contactPersonne'] as String?,
        moyenContact: moyenContact,
        produitDemarche: data['produitDemarche'] as String?,
        commentaire: data['commentaire'] as String?,
        typeRelance: data['typeRelance'] as String?,
        relanceDateHeure: data['relanceDateHeure'] as DateTime?,
      );

      ReportingModel? createdReport;
      try {
        final responseData = response['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          final user = ref.read(authProvider).user;
          final userName = user != null ? '${user.prenom ?? ''} ${user.nom ?? ''}'.trim() : '';
          createdReport = ReportingModel(
            id: responseData['id'] is int
                ? responseData['id'] as int
                : (responseData['id'] is String
                    ? int.tryParse(responseData['id'] as String) ?? DateTime.now().millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch),
            userId: responseData['user_id'] is int
                ? responseData['user_id'] as int
                : (responseData['user_id'] is String
                    ? int.tryParse(responseData['user_id'] as String) ?? userId
                    : userId),
            userName: responseData['user_name'] as String? ?? userName,
            userRole: responseData['user_role'] as String? ?? userRole,
            reportDate: reportDate,
            status: responseData['status'] as String? ?? 'submitted',
            nature: responseData['nature'] as String? ?? nature,
            nomSociete: responseData['nom_societe'] as String? ?? nomSociete,
            contactSociete: responseData['contact_societe'] as String?,
            nomPersonne: responseData['nom_personne'] as String? ?? nomPersonne,
            contactPersonne: responseData['contact_personne'] as String?,
            moyenContact: responseData['moyen_contact'] as String? ?? moyenContact,
            produitDemarche: responseData['produit_demarche'] as String?,
            commentaire: responseData['commentaire'] as String?,
            typeRelance: responseData['type_relance'] as String?,
            relanceDateHeure: data['relanceDateHeure'] as DateTime?,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      } catch (_) {}

      if (createdReport != null) {
        state = state.copyWith(
          reports: [createdReport, ...state.reports],
          isLoading: false,
        );
        ReportingService.saveCachedReporting(state.reports);
      } else {
        state = state.copyWith(isLoading: false);
      }
      rootGoRouter?.go('/reporting');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateReport(int reportId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await _reportingService.updateReport(
        reportId: reportId,
        nature: data['nature'] as String?,
        nomSociete: data['nomSociete'] as String?,
        contactSociete: data['contactSociete'] as String?,
        nomPersonne: data['nomPersonne'] as String?,
        contactPersonne: data['contactPersonne'] as String?,
        moyenContact: data['moyenContact'] as String?,
        produitDemarche: data['produitDemarche'] as String?,
        commentaire: data['commentaire'] as String?,
        typeRelance: data['typeRelance'] as String?,
        relanceDateHeure: data['relanceDateHeure'] as DateTime?,
      );
      state = state.copyWith(isLoading: false);
      loadReports(forceRefresh: true);
      rootGoRouter?.go('/reporting');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> submitReport(int reportId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _reportingService.submitReport(reportId);
      final report = _findReport(reportId);
      if (report != null) {
        final userName = report.userName.isNotEmpty ? report.userName : 'Utilisateur #${report.userId}';
        final entityDisplayName = NotificationHelper.getEntityDisplayName('report', report);
        NotificationHelper.notifySubmission(
          entityType: 'report',
          entityName: 'Reporting de $userName - $entityDisplayName',
          entityId: reportId.toString(),
          route: NotificationHelper.getEntityRoute('report', reportId.toString()),
        );
      }
      state = state.copyWith(isLoading: false);
      loadReports();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> approveReport(int reportId, {String? patronNote}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _reportingService.approveReport(
        reportId,
        patronNote: patronNote,
      );
      final isSuccess = result['success'] == true || result['success'] == 1 || result['success'] == 'true';
      if (isSuccess) {
        final report = _findReport(reportId);
        if (report != null) {
          NotificationHelper.notifyValidation(
            entityType: 'report',
            entityName: NotificationHelper.getEntityDisplayName('report', report),
            entityId: reportId.toString(),
            route: NotificationHelper.getEntityRoute('report', reportId.toString()),
            entity: report,
          );
        }
        loadReports().ignore();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de l\'approbation');
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> rejectReport(int reportId, {String? reason}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _reportingService.rejectReport(
        reportId,
        comments: reason,
      );
      final isSuccess = result['success'] == true || result['success'] == 1 || result['success'] == 'true';
      if (isSuccess) {
        final report = _findReport(reportId);
        if (report != null) {
          NotificationHelper.notifyRejection(
            entityType: 'report',
            entityName: NotificationHelper.getEntityDisplayName('report', report),
            entityId: reportId.toString(),
            reason: reason,
            route: NotificationHelper.getEntityRoute('report', reportId.toString()),
            entity: report,
          );
        }
        loadReports().ignore();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors du rejet');
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> addPatronNote(int reportId, {String? note}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _reportingService.addPatronNote(
        reportId,
        note: note,
      );
      final isSuccess = result['success'] == true || result['success'] == 1 || result['success'] == 'true';
      if (!isSuccess) {
        throw Exception(result['message'] ?? 'Erreur lors de l\'enregistrement de la note');
      }
      loadReports().ignore();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}
