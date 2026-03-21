import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';

class DashboardFilters {
  // Filtres de période
  static final periodFilters = [
    Filter(
      id: 'today',
      label: "Aujourd'hui",
      icon: Icons.today,
      type: FilterType.date,
      value: 'today',
    ),
    Filter(
      id: 'week',
      label: 'Cette semaine',
      icon: Icons.view_week,
      type: FilterType.date,
      value: 'week',
    ),
    Filter(
      id: 'month',
      label: 'Ce mois',
      icon: Icons.calendar_month,
      type: FilterType.date,
      value: 'month',
    ),
    Filter(
      id: 'quarter',
      label: 'Ce trimestre',
      icon: Icons.calendar_view_month,
      type: FilterType.date,
      value: 'quarter',
    ),
    Filter(
      id: 'year',
      label: 'Cette année',
      icon: Icons.calendar_today,
      type: FilterType.date,
      value: 'year',
    ),
  ];

  // Filtres de statut
  static final statusFilters = [
    Filter(
      id: 'active',
      label: 'Actif',
      icon: Icons.check_circle,
      type: FilterType.status,
      value: 'active',
    ),
    Filter(
      id: 'pending',
      label: 'En attente',
      icon: Icons.pending,
      type: FilterType.status,
      value: 'pending',
    ),
    Filter(
      id: 'completed',
      label: 'Terminé',
      icon: Icons.done_all,
      type: FilterType.status,
      value: 'completed',
    ),
    Filter(
      id: 'cancelled',
      label: 'Annulé',
      icon: Icons.cancel,
      type: FilterType.status,
      value: 'cancelled',
    ),
  ];

  // Filtres de département
  static final departmentFilters = [
    Filter(
      id: 'commercial',
      label: 'Commercial',
      icon: Icons.business,
      type: FilterType.department,
      value: 'commercial',
    ),
    Filter(
      id: 'rh',
      label: 'RH',
      icon: Icons.people,
      type: FilterType.department,
      value: 'rh',
    ),
    Filter(
      id: 'tech',
      label: 'Technique',
      icon: Icons.computer,
      type: FilterType.department,
      value: 'tech',
    ),
    Filter(
      id: 'compta',
      label: 'Comptabilité',
      icon: Icons.account_balance,
      type: FilterType.department,
      value: 'compta',
    ),
  ];

  // Filtres de catégorie
  static final categoryFilters = [
    Filter(
      id: 'sales',
      label: 'Ventes',
      icon: Icons.shopping_cart,
      type: FilterType.category,
      value: 'sales',
    ),
    Filter(
      id: 'expenses',
      label: 'Dépenses',
      icon: Icons.money_off,
      type: FilterType.category,
      value: 'expenses',
    ),
    Filter(
      id: 'tickets',
      label: 'Tickets',
      icon: Icons.build,
      type: FilterType.category,
      value: 'tickets',
    ),
    Filter(
      id: 'leaves',
      label: 'Congés',
      icon: Icons.beach_access,
      type: FilterType.category,
      value: 'leaves',
    ),
  ];

  // Filtres de priorité
  static final priorityFilters = [
    Filter(
      id: 'high',
      label: 'Haute',
      icon: Icons.priority_high,
      type: FilterType.custom,
      value: 'high',
    ),
    Filter(
      id: 'medium',
      label: 'Moyenne',
      icon: Icons.remove,
      type: FilterType.custom,
      value: 'medium',
    ),
    Filter(
      id: 'low',
      label: 'Basse',
      icon: Icons.arrow_downward,
      type: FilterType.custom,
      value: 'low',
    ),
  ];

  // Obtenir les filtres par rôle
  static List<Filter> getFiltersForRole(int role) {
    final filters = <Filter>[];

    // Ajouter les filtres de période pour tous les rôles
    filters.addAll(periodFilters);

    // Ajouter les filtres spécifiques selon le rôle
    switch (role) {
      case 1: // Admin
        filters.addAll([
          ...departmentFilters,
          ...statusFilters,
          ...categoryFilters,
          ...priorityFilters,
        ]);
        break;
      case 2: // Commercial
        filters.addAll([
          ...statusFilters.where((f) => f.id != 'cancelled'),
          Filter(
            id: 'prospects',
            label: 'Prospects',
            icon: Icons.person_add,
            type: FilterType.custom,
            value: 'prospects',
          ),
          Filter(
            id: 'clients',
            label: 'Clients',
            icon: Icons.people,
            type: FilterType.custom,
            value: 'clients',
          ),
        ]);
        break;
      case 3: // Comptable
        filters.addAll([
          ...categoryFilters.where(
            (f) => f.id == 'sales' || f.id == 'expenses',
          ),
          Filter(
            id: 'invoices',
            label: 'Factures',
            icon: Icons.receipt,
            type: FilterType.custom,
            value: 'invoices',
          ),
        ]);
        break;
      case 4: // Patron
        filters.addAll([
          ...departmentFilters,
          ...categoryFilters,
          ...priorityFilters,
        ]);
        break;
      case 5: // RH
        filters.addAll([
          ...statusFilters,
          ...categoryFilters.where((f) => f.id == 'leaves'),
          Filter(
            id: 'recruitment',
            label: 'Recrutement',
            icon: Icons.person_search,
            type: FilterType.custom,
            value: 'recruitment',
          ),
        ]);
        break;
      case 6: // Technicien
        filters.addAll([
          ...statusFilters,
          ...priorityFilters,
          Filter(
            id: 'maintenance',
            label: 'Maintenance',
            icon: Icons.build,
            type: FilterType.custom,
            value: 'maintenance',
          ),
        ]);
        break;
    }

    return filters;
  }
}
