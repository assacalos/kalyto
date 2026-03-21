import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/expense_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';

class ExpenseDetail extends ConsumerWidget {
  final Expense expense;

  const ExpenseDetail({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(expenseProvider.notifier);
    final userRole = ref.watch(authProvider).user?.role;
    final canManage = userRole == Roles.ADMIN || userRole == Roles.COMPTABLE;
    final canApprove = userRole == Roles.ADMIN || userRole == Roles.PATRON;
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(expense.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (canManage && expense.status == 'pending')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.go('/expenses/${expense.id}/edit', extra: expense),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareExpense(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoCard('Informations de base', [
              _buildInfoRow(Icons.title, 'Titre', expense.title),
              _buildInfoRow(Icons.category, 'Catégorie', expense.categoryText),
              _buildInfoRow(
                Icons.currency_franc,
                'Montant',
                formatCurrency.format(expense.amount),
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Date de dépense',
                DateFormat('dd/MM/yyyy').format(expense.expenseDate),
              ),
              _buildInfoRow(
                Icons.description,
                'Description',
                expense.description,
              ),
            ]),

            // Justificatif si disponible
            if (expense.receiptPath != null && expense.receiptUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildReceiptCard(context),
            ],

            // Notes si disponibles
            if (expense.notes != null && expense.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes', [
                _buildInfoRow(Icons.note, 'Notes', expense.notes!),
              ]),
            ],

            // Raison du rejet si rejetée
            if (expense.status == 'rejected' &&
                expense.rejectionReason != null &&
                expense.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Motif du rejet', [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    expense.rejectionReason!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ]),
            ],

            // Historique des actions
            const SizedBox(height: 16),
            _buildHistoryCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(context, ref, notifier, canManage, canApprove),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: expense.statusColor.withOpacity(0.1),
              child: Icon(
                expense.statusIcon,
                size: 30,
                color: expense.statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(expense.createdAt)}',
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
        color: expense.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: expense.statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(expense.statusIcon, size: 16, color: expense.statusColor),
          const SizedBox(width: 4),
          Text(
            expense.statusText,
            style: TextStyle(
              color: expense.statusColor,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context) {
    // Vérifier si c'est une image (jpg, jpeg, png, gif, webp)
    final isImage = expense.receiptPath != null &&
        ['jpg', 'jpeg', 'png', 'gif', 'webp'].any(
          (ext) => expense.receiptPath!.toLowerCase().endsWith('.$ext'),
        );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Justificatif',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                // Bouton de téléchargement
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Télécharger',
                  onPressed: () => _downloadReceipt(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isImage && expense.receiptUrl.isNotEmpty)
              // Afficher l'image si c'est un fichier image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: expense.receiptUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ),
              )
            else
              // Afficher une icône de fichier pour les autres types
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fichier joint',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expense.receiptPath?.split('/').last ?? 'Justificatif',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _downloadReceipt(BuildContext context) {
    if (expense.receiptUrl.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ouverture du justificatif...'),
        ),
      );
    }
  }

  Widget _buildHistoryCard() {
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
              DateFormat('dd/MM/yyyy à HH:mm').format(expense.createdAt),
              Colors.blue,
            ),
            if (expense.status == 'approved' && expense.approvedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Approuvé',
                DateFormat(
                  'dd/MM/yyyy à HH:mm',
                ).format(DateTime.parse(expense.approvedAt!)),
                Colors.green,
              ),
            if (expense.status == 'rejected')
              _buildHistoryItem(
                Icons.cancel,
                'Rejeté',
                DateFormat('dd/MM/yyyy à HH:mm').format(expense.updatedAt),
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
    ExpenseNotifier notifier,
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
                if (expense.status == 'pending' && canManage) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      onPressed: () =>
                          context.go('/expenses/${expense.id}/edit', extra: expense),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (expense.status == 'pending' && canApprove) ...[
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
                if (expense.status == 'approved' ||
                    expense.status == 'rejected') ...[
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

  void _shareExpense(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à implémenter'),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, ExpenseNotifier notifier) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver la dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir approuver cette dépense ?'),
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
              await notifier.approveExpense(expense,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dépense approuvée')),
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

  void _showRejectDialog(BuildContext context, ExpenseNotifier notifier) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet :'),
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
              await notifier.rejectExpense(
                  expense, reasonController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dépense rejetée')),
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
}
