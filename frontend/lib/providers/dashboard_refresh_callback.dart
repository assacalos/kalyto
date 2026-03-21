import 'package:flutter/foundation.dart';

class DashboardRefreshCallback {
  DashboardRefreshCallback._();
  static final DashboardRefreshCallback instance = DashboardRefreshCallback._();

  VoidCallback? refreshCommercial;
  VoidCallback? refreshPatron;
  VoidCallback? refreshComptable;
  VoidCallback? refreshRh;
  VoidCallback? refreshTechnicien;

  void triggerCommercialRefresh() => refreshCommercial?.call();
  void triggerPatronRefresh() => refreshPatron?.call();
  void triggerComptableRefresh() => refreshComptable?.call();
  void triggerRhRefresh() => refreshRh?.call();
  void triggerTechnicienRefresh() => refreshTechnicien?.call();
}
