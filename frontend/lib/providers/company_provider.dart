import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/company_model.dart';
import 'package:easyconnect/services/company_service.dart';

/// ID de la société courante (lecture réactive).
final currentCompanyIdProvider = StateProvider<int?>((ref) {
  return CompanyService.getCurrentCompanyId();
});

/// Liste des sociétés (API GET /api/companies).
final companiesProvider = FutureProvider<List<Company>>((ref) async {
  return CompanyService.getCompanies();
});

/// Société courante (objet Company) dérivée de l'ID et de la liste.
final currentCompanyProvider = Provider<Company?>((ref) {
  final id = ref.watch(currentCompanyIdProvider);
  final asyncCompanies = ref.watch(companiesProvider);
  if (id == null) return null;
  return asyncCompanies.when(
    data: (list) {
      for (final c in list) {
        if (c.id == id) return c;
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
