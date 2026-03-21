import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easyconnect/providers/balance_notifier.dart';
import 'package:easyconnect/providers/balance_state.dart';
import 'package:easyconnect/utils/dashboard_entity_colors.dart';
import 'package:easyconnect/Views/Comptable/balance_csv_export.dart';

class BalancePage extends ConsumerStatefulWidget {
  const BalancePage({super.key});

  @override
  ConsumerState<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends ConsumerState<BalancePage> {
  final _formatNumber = NumberFormat('#,##0.00', 'fr_FR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(balanceProvider.notifier).loadBalance();
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

  Future<void> _exportCsv() async {
    final state = ref.read(balanceProvider);
    if (state.rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune donnée à exporter')),
        );
      }
      return;
    }
    const sep = ';';
    const utf8Bom = '\uFEFF';
    final sb = StringBuffer(utf8Bom);
    sb.writeln('Compte${sep}Libellé${sep}Total Débit${sep}Total Crédit${sep}Solde');
    for (final r in state.rows) {
      sb.writeln('${r.compte}$sep${r.libelleCompte}$sep${_formatNumber.format(r.totalDebit)}$sep${_formatNumber.format(r.totalCredit)}$sep${_formatNumber.format(r.solde)}');
    }
    sb.writeln('TOTAL$sep$sep${_formatNumber.format(state.totalDebit)}$sep${_formatNumber.format(state.totalCredit)}$sep${_formatNumber.format(state.soldeFinal)}');
    final csv = sb.toString();
    try {
      final path = await writeBalanceCsvToFile(
        csv,
        state.dateDebut ?? '',
        state.dateFin ?? '',
      );
      if (path != null) {
        await Share.shareXFiles([XFile(path)], text: 'Balance comptable');
      } else {
        await Share.share(csv, subject: 'Balance comptable');
      }
    } catch (e) {
      if (mounted) {
        try {
          await Share.share(csv, subject: 'Balance comptable');
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export impossible: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(balanceProvider);
    final notifier = ref.read(balanceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance comptable'),
        backgroundColor: DashboardEntityColors.balance,
        foregroundColor: Colors.white,
        actions: [
          // Export CSV (partage fichier sur mobile/desktop, texte sur Web).
          // Pour export Excel : ajouter package excel (ex: excel ^4.0.2), générer un .xlsx puis Share.shareXFiles.
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: state.rows.isEmpty ? null : _exportCsv,
            tooltip: 'Exporter en CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading ? null : () => notifier.loadBalance(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(context, state, notifier),
          Expanded(
            child: state.isLoading && state.rows.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => notifier.loadBalance(),
                    child: state.rows.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 48),
                              Icon(
                                Icons.account_balance_wallet,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            children: [
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
    BalanceState state,
    BalanceNotifier notifier,
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
                  notifier.loadBalance();
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
                  notifier.loadBalance();
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
            onPressed: state.isLoading ? null : () => notifier.loadBalance(),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardEntityColors.balance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BalanceState state) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            DashboardEntityColors.balance.withOpacity(0.15),
          ),
          columns: const [
            DataColumn(
                label: Text('Compte',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Libellé',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
              label: Text('Total Débit',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Total Crédit',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Solde', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
          ],
          rows: [
            ...state.rows.map((r) {
              return DataRow(
                cells: [
                  DataCell(Text(r.compte)),
                  DataCell(ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      r.libelleCompte,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  )),
                  DataCell(Text(
                    r.totalDebit > 0 ? _formatNumber.format(r.totalDebit) : '',
                    style: r.totalDebit > 0
                        ? TextStyle(color: Colors.green.shade700)
                        : null,
                  )),
                  DataCell(Text(
                    r.totalCredit > 0
                        ? _formatNumber.format(r.totalCredit)
                        : '',
                    style: r.totalCredit > 0
                        ? TextStyle(color: Colors.red.shade700)
                        : null,
                  )),
                  DataCell(Text(
                    _formatNumber.format(r.solde),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                ],
              );
            }),
            DataRow(
              color: WidgetStateProperty.all(
                DashboardEntityColors.balance.withOpacity(0.08),
              ),
              cells: [
                const DataCell(Text('')),
                const DataCell(Text('TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(
                  _formatNumber.format(state.totalDebit),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
                DataCell(Text(
                  _formatNumber.format(state.totalCredit),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
                DataCell(Text(
                  _formatNumber.format(state.soldeFinal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
