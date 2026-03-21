import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final List<Filter> filters;
  final List<Filter> activeFilters;
  final void Function(Filter filter, bool selected) onFilterChanged;
  final VoidCallback? onClear;

  const FilterBar({
    super.key,
    required this.filters,
    required this.activeFilters,
    required this.onFilterChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: activeFilters.isEmpty ? null : onClear,
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filters.map((filter) {
                return FilterChip(
                  label: Text(filter.label),
                  selected: activeFilters.contains(filter),
                  onSelected: (selected) {
                    onFilterChanged(filter, selected);
                  },
                  avatar: filter.icon != null ? Icon(filter.icon) : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class Filter {
  final String id;
  final String label;
  final IconData? icon;
  final FilterType type;
  final dynamic value;

  const Filter({
    required this.id,
    required this.label,
    this.icon,
    required this.type,
    this.value,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Filter && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum FilterType {
  date,
  status,
  category,
  user,
  department,
  custom,
}
