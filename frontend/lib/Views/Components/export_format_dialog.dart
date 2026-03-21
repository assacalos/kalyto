import 'package:flutter/material.dart';

/// Affiche un dialogue pour choisir le format d'export (Excel ou CSV).
/// Retourne 'excel', 'csv' ou null si annulé.
Future<String?> showExportFormatDialog(BuildContext context, {String title = 'Exporter'}) async {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Excel (.xlsx)'),
            subtitle: const Text('Fichier tableur'),
            onTap: () => Navigator.pop(ctx, 'excel'),
          ),
          ListTile(
            leading: const Icon(Icons.text_snippet),
            title: const Text('CSV (.csv)'),
            subtitle: const Text('Texte séparé par point-virgule'),
            onTap: () => Navigator.pop(ctx, 'csv'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
