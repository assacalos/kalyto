import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/grand_livre_notifier.dart';
import 'package:easyconnect/providers/grand_livre_state.dart';
import 'package:easyconnect/utils/dashboard_entity_colors.dart';

class GrandLivrePage extends ConsumerStatefulWidget {
  const GrandLivrePage({super.key});

  @override
  ConsumerState<GrandLivrePage> createState() => _GrandLivrePageState();
}

class _GrandLivrePageState extends ConsumerState<GrandLivrePage> {
  final _formatNumber = NumberFormat('#,##0.00', 'fr_FR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(grandLivreProvider.notifier).loadGrandLivre();
    });
  }

  String _dateToApi(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  DateTime? _apiToDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(grandLivreProvider);
    final notifier = ref.read(grandLivreProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grand livre'),
        backgroundColor: DashboardEntityColors.grandLivre,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading ? null : () => notifier.loadGrandLivre(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(context, state, notifier),
          Expanded(
            child: state.isLoading && state.lignes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => notifier.loadGrandLivre(),
                    child: state.lignes.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 48),
                              Icon(
                                Icons.book_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun mouvement sur la période',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Modifiez les dates ou attendez des écritures.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              _buildSummaryCard(state),
                              const SizedBox(height: 16),
                              _buildTable(state),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    GrandLivreState state,
    GrandLivreNotifier notifier,
  ) {
    final debut = _apiToDate(state.dateDebut);
    final fin = _apiToDate(state.dateFin);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(debut != null
                  ? DateFormat('dd/MM/yyyy').format(debut)
                  : 'Date début'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: debut ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  notifier.setDateRange(_dateToApi(picked), state.dateFin);
                  notifier.loadGrandLivre();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(fin != null
                  ? DateFormat('dd/MM/yyyy').format(fin)
                  : 'Date fin'),
              onPressed: () async {
                final initial = fin ?? debut ?? DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: debut ?? DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  notifier.setDateRange(state.dateDebut, _dateToApi(picked));
                  notifier.loadGrandLivre();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search, size: 18),
            label: const Text('Appliquer'),
            onPressed: state.isLoading ? null : () => notifier.loadGrandLivre(),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardEntityColors.grandLivre,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(GrandLivreState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période du ${state.dateDebut ?? '—'} au ${state.dateFin ?? '—'}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solde initial',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${_formatNumber.format(state.soldeInitial)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Solde final',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${_formatNumber.format(state.soldeFinal)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(GrandLivreState state) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            DashboardEntityColors.grandLivre.withOpacity(0.15),
          ),
          columns: const [
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Libellé', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
              label: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Solde courant', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
          ],
          rows: [
            if (state.soldeInitial != 0)
              DataRow(
                cells: [
                  DataCell(Text(state.dateDebut ?? '')),
                  const DataCell(Text('Solde initial')),
                  DataCell(Text(state.soldeInitial > 0 ? _formatNumber.format(state.soldeInitial) : '')),
                  DataCell(Text(state.soldeInitial < 0 ? _formatNumber.format(-state.soldeInitial) : '')),
                  DataCell(Text(_formatNumber.format(state.soldeInitial))),
                ],
              ),
            ...state.lignes.map((l) {
              return DataRow(
                cells: [
                  DataCell(Text(l.date)),
                  DataCell(ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      l.libelle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  )),
                  DataCell(Text(
                    l.debit > 0 ? _formatNumber.format(l.debit) : '',
                    style: TextStyle(color: l.debit > 0 ? Colors.green.shade700 : null),
                  )),
                  DataCell(Text(
                    l.credit > 0 ? _formatNumber.format(l.credit) : '',
                    style: TextStyle(color: l.credit > 0 ? Colors.red.shade700 : null),
                  )),
                  DataCell(Text(
                    _formatNumber.format(l.soldeCourant),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
