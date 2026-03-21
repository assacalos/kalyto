import 'package:easyconnect/providers/dashboard_refresh_callback.dart';

/// Helper pour rafraîchir les compteurs des dashboards après une validation/rejet.
/// Utilise uniquement les callbacks Riverpod (plus de Get.find).
class DashboardRefreshHelper {
  /// Rafraîchit le dashboard commercial (Riverpod).
  static void refreshCommercialDashboard() {
    DashboardRefreshCallback.instance.triggerCommercialRefresh();
  }

  /// Rafraîchit le compteur spécifique du dashboard patron.
  static void refreshPatronCounter(String entityType) {
    DashboardRefreshCallback.instance.triggerPatronRefresh();
  }

  /// Rafraîchit tous les compteurs du dashboard patron.
  static void refreshAllPatronCounters() {
    DashboardRefreshCallback.instance.triggerPatronRefresh();
  }

  /// Rafraîchit les entités en attente du dashboard comptable.
  static void refreshComptablePending(String entityType) {
    DashboardRefreshCallback.instance.triggerComptableRefresh();
  }

  /// Rafraîchit toutes les données du dashboard comptable.
  static void refreshComptableDashboard() {
    DashboardRefreshCallback.instance.triggerComptableRefresh();
  }

  /// Rafraîchit les entités en attente du dashboard technicien.
  static void refreshTechnicienPending(String entityType) {
    DashboardRefreshCallback.instance.triggerTechnicienRefresh();
  }

  /// Rafraîchit toutes les données du dashboard technicien.
  static void refreshTechnicienDashboard() {
    DashboardRefreshCallback.instance.triggerTechnicienRefresh();
  }

  /// Rafraîchit le dashboard RH (Riverpod).
  static void refreshRhDashboard() {
    DashboardRefreshCallback.instance.triggerRhRefresh();
  }
}
