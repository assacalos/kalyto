import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/salary_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';

class SalaryDetail extends ConsumerWidget {
  final Salary salary;

  const SalaryDetail({super.key, required this.salary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(salaryProvider.notifier);
    final userRole = ref.watch(authProvider).user?.role;
    final canManage = userRole == Roles.ADMIN || userRole == Roles.COMPTABLE;
    final canApprove = userRole == Roles.ADMIN || userRole == Roles.PATRON;
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');
    final formatDate = DateFormat('dd/MM/yyyy à HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Salaire - ${salary.employeeName}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generateBulletin(context),
            tooltip: 'Générer bulletin',
          ),
          if (canManage && salary.status == 'pending')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.go('/salaries/${salary.id}/edit', extra: salary),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSalary(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(formatCurrency),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoCard('Informations de base', [
              _buildInfoRow(Icons.person, 'Employé', salary.employeeName ?? ''),
              _buildInfoRow(Icons.email, 'Email', salary.employeeEmail ?? ''),
              _buildInfoRow(Icons.calendar_today, 'Période', salary.periodText),
            ]),

            // Détails du salaire
            const SizedBox(height: 16),
            _buildInfoCard('Détails du salaire', [
              _buildInfoRow(
                Icons.account_balance_wallet,
                'Salaire de base',
                formatCurrency.format(salary.baseSalary),
              ),
              if (salary.bonus > 0)
                _buildInfoRow(
                  Icons.star,
                  'Prime',
                  formatCurrency.format(salary.bonus),
                ),
              if (salary.deductions > 0)
                _buildInfoRow(
                  Icons.remove_circle,
                  'Déductions',
                  formatCurrency.format(salary.deductions),
                ),
              _buildInfoRow(
                Icons.calculate,
                'Salaire net',
                formatCurrency.format(salary.netSalary),
                isTotal: true,
              ),
            ]),

            // Notes si disponibles
            if (salary.notes != null && salary.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes', [
                _buildInfoRow(Icons.note, 'Notes', salary.notes!),
              ]),
            ],

            // Historique des actions
            const SizedBox(height: 16),
            _buildHistoryCard(formatDate),

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(context, ref, notifier, canManage, canApprove),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(NumberFormat formatCurrency) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: salary.statusColor.withOpacity(0.1),
              child: Icon(
                salary.statusIcon,
                size: 30,
                color: salary.statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salary.employeeName ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    '${salary.periodText} - ${formatCurrency.format(salary.netSalary)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: salary.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: salary.statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(salary.statusIcon, size: 16, color: salary.statusColor),
          const SizedBox(width: 4),
          Text(
            salary.statusText,
            style: TextStyle(
              color: salary.statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTotal ? 16 : 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                    color: isTotal ? Colors.deepPurple : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(DateFormat formatDate) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              Icons.add,
              'Créé',
              formatDate.format(salary.createdAt ?? DateTime.now()),
              Colors.blue,
            ),
            if (salary.status == 'approved' && salary.approvedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Approuvé',
                formatDate.format(DateTime.parse(salary.approvedAt!)),
                Colors.green,
              ),
            if (salary.status == 'paid' && salary.paidAt != null)
              _buildHistoryItem(
                Icons.payment,
                'Payé',
                formatDate.format(DateTime.parse(salary.paidAt!)),
                Colors.blue,
              ),
            if (salary.status == 'rejected')
              _buildHistoryItem(
                Icons.cancel,
                'Rejeté',
                formatDate.format(salary.updatedAt ?? DateTime.now()),
                Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    IconData icon,
    String action,
    String date,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    SalaryNotifier notifier,
    bool canManage,
    bool canApprove,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (salary.status == 'pending' && canManage) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      onPressed: () =>
                          context.go('/salaries/${salary.id}/edit', extra: salary),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (salary.status == 'pending' && canApprove) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(context, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      onPressed: () => _showRejectDialog(context, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (salary.status == 'approved' && canApprove) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Marquer payé'),
                      onPressed: () => _showMarkPaidDialog(context, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (salary.status == 'paid') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir détails'),
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateBulletin(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Génération du bulletin en cours...'),
          duration: Duration(seconds: 2),
        ),
      );
      await PdfService().generateBulletinPaiePdf(salary);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bulletin de paie généré'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareSalary(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à implémenter'),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, SalaryNotifier notifier) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver le salaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approuver le salaire de ${salary.employeeName} ?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await notifier.approveSalary(salary,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salaire approuvé')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, SalaryNotifier notifier) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le salaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejeter le salaire de ${salary.employeeName} ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez indiquer la raison du rejet')),
                );
                return;
              }
              await notifier.rejectSalary(
                  salary, reasonController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salaire rejeté')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showMarkPaidDialog(BuildContext context, SalaryNotifier notifier) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marquer comme payé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Marquer le salaire de ${salary.employeeName} comme payé ?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await notifier.markSalaryAsPaid(salary,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salaire marqué comme payé')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
