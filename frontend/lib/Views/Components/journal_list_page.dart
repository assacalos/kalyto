import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/journal_notifier.dart';
import 'package:easyconnect/Views/Components/export_format_dialog.dart';
import 'package:easyconnect/services/export_service.dart';

class JournalListPage extends ConsumerStatefulWidget {
  const JournalListPage({super.key});

  static final _formatNumber = NumberFormat('#,##0', 'fr_FR');

  @override
  ConsumerState<JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends ConsumerState<JournalListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(journalProvider.notifier).loadJournal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalProvider);
    final notifier = ref.read(journalProvider.notifier);
    final now = DateTime.now();
    final month = state.selectedMonth ?? now.month;
    final year = state.selectedYear ?? now.year;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal des comptes'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
            onPressed: state.lignes.isEmpty ? null : () => _exportJournal(context, state.lignes, state.selectedYear, state.selectedMonth),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadJournal(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, state, notifier, month, year),
          Expanded(
            child: state.isLoading && state.lignes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => notifier.loadJournal(),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSummaryCard(context, state, notifier, month, year),
                        const SizedBox(height: 16),
                        ...state.lignes.map(
                            (l) => _buildLineTile(context, notifier, l)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await context.push<bool>(
            '/journal/form',
            extra: null,
          );
          if (ok == true && context.mounted) {
            ref.read(journalProvider.notifier).loadJournal();
          }
        },
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _exportJournal(
    BuildContext context,
    List<dynamic> lignes,
    int? selectedYear,
    int? selectedMonth,
  ) async {
    final format = await showExportFormatDialog(context, title: 'Exporter le journal');
    if (format == null || !context.mounted) return;
    const headers = ['Date', 'Libellé', 'Entrée', 'Sortie', 'Solde'];
    final rows = lignes.map((l) {
      final m = l is Map ? Map<String, dynamic>.from(l) : <String, dynamic>{};
      return [
        m['date']?.toString() ?? '',
        m['libelle']?.toString() ?? '',
        m['entree'] ?? 0,
        m['sortie'] ?? 0,
        m['solde'] ?? 0,
      ];
    }).toList();
    final base = 'journal_${selectedYear ?? ''}_${selectedMonth ?? ''}';
    try {
      if (format == 'excel') {
        await ExportService.exportExcel(headers: headers, rows: rows, filenameBase: base, sheetName: 'Journal');
      } else {
        await ExportService.exportCsv(headers: headers, rows: rows, filenameBase: base);
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export réussi')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Widget _buildFilterBar(
    BuildContext context,
    dynamic state,
    JournalNotifier notifier,
    int month,
    int year,
  ) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<int>(
              value: month,
              isExpanded: true,
              items: List.generate(12, (i) => i + 1).map((m) {
                final name =
                    DateFormat('MMMM', 'fr_FR').format(DateTime(2000, m));
                return DropdownMenuItem(value: m, child: Text(name));
              }).toList(),
              onChanged: (v) {
                if (v != null) notifier.setMonthYear(v, year);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int>(
              value: year,
              isExpanded: true,
              items: [now.year, now.year - 1, now.year - 2]
                  .map((y) =>
                      DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setMonthYear(month, v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    dynamic state,
    JournalNotifier notifier,
    int month,
    int year,
  ) {
    final lastDayPrev = DateTime(year, month, 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solde initial',
                        style: TextStyle(color: Colors.grey.shade700)),
                    Text(
                      '${JournalListPage._formatNumber.format(state.soldeInitial)} FCFA',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () =>
                      _showSoldeOuvertureDialog(
                          context, notifier, lastDayPrev),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Définir solde d\'ouverture'),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.teal.shade700),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total entrées',
                    style: TextStyle(color: Colors.green.shade700)),
                Text(
                  '${JournalListPage._formatNumber.format(state.totalEntrees)} FCFA',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total sorties',
                    style: TextStyle(color: Colors.red.shade700)),
                Text(
                  '${JournalListPage._formatNumber.format(state.totalSorties)} FCFA',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700),
                ),
              ],
            ),
            const Divider(),
            Text('Solde final',
                style: TextStyle(color: Colors.grey.shade700)),
            Text(
              '${JournalListPage._formatNumber.format(state.soldeFinal)} FCFA',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineTile(
      BuildContext context, JournalNotifier notifier, dynamic line) {
    final id = line['id'];
    final date = line['date']?.toString() ?? '';
    final libelle = line['libelle']?.toString() ?? '';
    final entree =
        (line['entree'] is num) ? (line['entree'] as num).toDouble() : 0.0;
    final sortie =
        (line['sortie'] is num) ? (line['sortie'] as num).toDouble() : 0.0;
    final solde =
        (line['solde'] is num) ? (line['solde'] as num).toDouble() : 0.0;

    final entryId = id is int ? id : int.tryParse(id.toString());
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: entryId != null
            ? () async {
                await context.push(
                  '/journal/$entryId',
                );
                if (context.mounted) {
                  ref.read(journalProvider.notifier).loadJournal();
                }
              }
            : null,
        title: Text(libelle,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(date),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entree > 0)
              Text(
                '+${JournalListPage._formatNumber.format(entree)}',
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600),
              ),
            if (sortie > 0)
              Text(
                '-${JournalListPage._formatNumber.format(sortie)}',
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600),
              ),
            const SizedBox(width: 8),
            Text(
              JournalListPage._formatNumber.format(solde),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (entryId != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () async {
                  final ok = await context.push<bool>(
                    '/journal/form',
                    extra: entryId,
                  );
                  if (ok == true && context.mounted) {
                    ref.read(journalProvider.notifier).loadJournal();
                  }
                },
              ),
            if (entryId != null)
              IconButton(
                icon: Icon(Icons.delete, size: 20, color: Colors.red.shade700),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer'),
                      content: const Text('Supprimer cette écriture ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Supprimer',
                              style: TextStyle(color: Colors.red.shade700)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    try {
                      await notifier.deleteEntry(entryId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Écriture supprimée'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  static void _showSoldeOuvertureDialog(
    BuildContext context,
    JournalNotifier notifier,
    DateTime defaultDate,
  ) {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(defaultDate),
    );
    final montantController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Solde d\'ouverture'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le solde initial affiché correspond au cumul des écritures avant la période. '
                  'Pour fixer un solde d\'ouverture, enregistrez une écriture avec la date souhaitée '
                  '(ex. dernier jour du mois précédent). Montant positif = entrée, négatif = sortie (découvert).',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(dateController.text) ?? defaultDate,
                      firstDate: DateTime(2000),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      dateController.text =
                          DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Date requise' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: montantController,
                  decoration: const InputDecoration(
                    labelText:
                        'Montant (FCFA). Positif = entrée, Négatif = découvert',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Montant requis';
                    final n =
                        double.tryParse(v.replaceAll(',', '.'));
                    if (n == null) return 'Montant invalide';
                    if (n == 0) return 'Le montant ne peut pas être zéro';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final montant = double.tryParse(
                montantController.text.trim().replaceAll(',', '.'),
              );
              if (montant == null || montant == 0) return;
              final entree = montant > 0 ? montant : 0.0;
              final sortie = montant < 0 ? montant.abs() : 0.0;
              try {
                final ok = await notifier.createEntry({
                  'date': dateController.text.trim(),
                  'libelle': 'Solde d\'ouverture',
                  'mode_paiement': 'especes',
                  'entree': entree,
                  'sortie': sortie,
                });
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solde d\'ouverture enregistré'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
