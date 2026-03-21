import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/supplier_notifier.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:intl/intl.dart';

class SupplierDetail extends ConsumerWidget {
  final Supplier supplier;

  const SupplierDetail({super.key, required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(supplierProvider.notifier);
    const canCreate = true;
    const canApprove = true;

    return Scaffold(
      appBar: AppBar(
        title: Text(supplier.nom),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.go('/suppliers/${supplier.id}/edit', extra: supplier),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSupplier(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildInfoCard('Informations de base', [
              _buildInfoRow(Icons.business, 'Nom', supplier.nom),
              if (supplier.ninea != null && supplier.ninea!.isNotEmpty)
                _buildInfoRow(Icons.fingerprint, 'NINEA', supplier.ninea!),
              _buildInfoRow(Icons.email, 'Email', supplier.email),
              _buildInfoRow(Icons.phone, 'Téléphone', supplier.telephone),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Adresse', [
              _buildInfoRow(Icons.location_on, 'Adresse', supplier.adresse),
              _buildInfoRow(Icons.location_city, 'Ville', supplier.ville),
              _buildInfoRow(Icons.public, 'Pays', supplier.pays),
            ]),
            if (supplier.description != null &&
                supplier.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Description', [
                _buildInfoRow(
                  Icons.description,
                  'Description',
                  supplier.description!,
                ),
              ]),
            ],
            if (supplier.commentaires != null &&
                supplier.commentaires!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Commentaires', [
                _buildInfoRow(
                  Icons.comment,
                  'Commentaires',
                  supplier.commentaires!,
                ),
              ]),
            ],
            if (supplier.noteEvaluation != null) ...[
              const SizedBox(height: 16),
              _buildRatingCard(),
            ],
            const SizedBox(height: 16),
            _buildHistoryCard(),
            const SizedBox(height: 16),
            _buildAssociatedEntities(context),
            const SizedBox(height: 16),
            _buildActionButtons(context, ref, notifier, canCreate, canApprove),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatedEntities(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entités associées',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            _buildEntityButton(
              icon: Icons.shopping_cart,
              label: 'Bons de commande',
              color: Colors.deepPurple,
              onTap: () {
                context.go(
                    '/bons-de-commande-fournisseur?supplierId=${supplier.id}');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
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
              backgroundColor: _getStatusColor().withOpacity(0.1),
              child: Icon(Icons.business, size: 30, color: _getStatusColor()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.nom,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    supplier.createdAt != null
                        ? 'Créé le ${DateFormat('dd/MM/yyyy').format(supplier.createdAt!)}'
                        : 'Date de création non disponible',
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
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor().withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
          const SizedBox(width: 4),
          Text(
            supplier.statusText,
            style: TextStyle(
              color: _getStatusColor(),
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

  Widget _buildRatingCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évaluation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  '${supplier.noteEvaluation!.toStringAsFixed(1)}/5',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    value: supplier.noteEvaluation! / 5,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amber[600]!,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
            if (supplier.createdAt != null)
              _buildHistoryItem(
                Icons.add,
                'Créé',
                DateFormat('dd/MM/yyyy à HH:mm').format(supplier.createdAt!),
                Colors.blue,
              ),
            if (supplier.isValidated && supplier.updatedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Validé',
                DateFormat('dd/MM/yyyy à HH:mm').format(supplier.updatedAt!),
                Colors.green,
              ),
            if (supplier.isRejected && supplier.updatedAt != null)
              _buildHistoryItem(
                Icons.cancel,
                'Rejeté',
                DateFormat('dd/MM/yyyy à HH:mm').format(supplier.updatedAt!),
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
    SupplierNotifier notifier,
    bool canCreate,
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
                if (canCreate) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Soumettre'),
                      onPressed: () =>
                          _showSubmitDialog(context, supplier, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (supplier.isPending && canApprove) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      onPressed: () =>
                          _showApproveDialog(context, supplier, notifier),
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
                      onPressed: () =>
                          _showRejectDialog(context, supplier, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (supplier.isValidated) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.star),
                      label: const Text('Évaluer'),
                      onPressed: () =>
                          _showRatingDialog(context, supplier, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
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

  Color _getStatusColor() {
    switch (supplier.statusColor) {
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (supplier.statut) {
      case 'edit':
        return Icons.edit;
      case 'schedule':
        return Icons.schedule;
      case 'check_circle':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _shareSupplier(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à implémenter'),
      ),
    );
  }

  void _showSubmitDialog(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Soumettre le fournisseur'),
        content: const Text(
          'Êtes-vous sûr de vouloir soumettre ce fournisseur au patron pour approbation ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final ok = await notifier.submitSupplier(supplier);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Fournisseur soumis avec succès'
                          : 'Erreur lors de la soumission'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    final commentsController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver le fournisseur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Commentaires d\'approbation (optionnel) :'),
            const SizedBox(height: 8),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                hintText: 'Ajouter des commentaires...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final ok = await notifier.approveSupplier(
                  supplier,
                  validationComment: commentsController.text.trim().isEmpty
                      ? null
                      : commentsController.text.trim(),
                );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Fournisseur validé avec succès'
                          : 'La validation a échoué'),
                      backgroundColor: ok ? Colors.green : Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    final reasonController = TextEditingController();
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le fournisseur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Motif du rejet (obligatoire) :'),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Expliquez la raison du rejet...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Commentaire (optionnel) :'),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Commentaire supplémentaire...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Le motif du rejet est obligatoire'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectSupplier(
                  supplier,
                  rejectionReason: reasonController.text.trim(),
                  rejectionComment: commentController.text.trim().isEmpty
                      ? null
                      : commentController.text.trim(),
                );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Fournisseur rejeté'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    final commentsController = TextEditingController();
    double rating = supplier.noteEvaluation ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Évaluer le fournisseur'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Note (1-5 étoiles) :'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () =>
                          setState(() => rating = index + 1.0),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('Commentaires (optionnel) :'),
                const SizedBox(height: 8),
                TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(
                    hintText: 'Ajouter des commentaires...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await notifier.rateSupplier(
                      supplier,
                      rating,
                      comments: commentsController.text.trim().isEmpty
                          ? null
                          : commentsController.text.trim(),
                    );
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Fournisseur évalué avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Évaluer'),
              ),
            ],
          );
        },
      ),
    );
  }
}
