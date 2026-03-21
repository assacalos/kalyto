import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/equipment_notifier.dart';
import 'package:easyconnect/providers/equipment_state.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:intl/intl.dart';

class EquipmentDetail extends ConsumerWidget {
  final Equipment equipment;

  const EquipmentDetail({super.key, required this.equipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(equipmentProvider);
    final notifier = ref.read(equipmentProvider.notifier);
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');
    final formatDate = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(equipment.name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (state.canManageEquipments)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.go('/equipments/${equipment.id}/edit', extra: equipment),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareEquipment(context),
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
              _buildInfoRow(Icons.devices, 'Nom', equipment.name),
              _buildInfoRow(Icons.category, 'Catégorie', _getCategoryLabel(equipment.category)),
              _buildInfoRow(Icons.info, 'Statut', equipment.statusText),
              _buildInfoRow(Icons.star, 'État', equipment.conditionText),
              _buildInfoRow(Icons.description, 'Description', equipment.description),
            ]),

            // Informations techniques
            if (equipment.serialNumber != null || equipment.model != null || equipment.brand != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Informations techniques', [
                if (equipment.serialNumber != null)
                  _buildInfoRow(Icons.qr_code, 'Numéro de série', equipment.serialNumber!),
                if (equipment.model != null)
                  _buildInfoRow(Icons.model_training, 'Modèle', equipment.model!),
                if (equipment.brand != null)
                  _buildInfoRow(Icons.branding_watermark, 'Marque', equipment.brand!),
              ]),
            ],

            // Localisation et assignation
            if (equipment.location != null || equipment.department != null || equipment.assignedTo != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Localisation et assignation', [
                if (equipment.location != null)
                  _buildInfoRow(Icons.location_on, 'Localisation', equipment.location!),
                if (equipment.department != null)
                  _buildInfoRow(Icons.business, 'Département', equipment.department!),
                if (equipment.assignedTo != null)
                  _buildInfoRow(Icons.person, 'Assigné à', equipment.assignedTo!),
              ]),
            ],

            // Informations financières
            if (equipment.purchasePrice != null || equipment.currentValue != null || equipment.supplier != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Informations financières', [
                if (equipment.purchasePrice != null)
                  _buildInfoRow(Icons.euro, 'Prix d\'achat', formatCurrency.format(equipment.purchasePrice!)),
                if (equipment.currentValue != null)
                  _buildInfoRow(Icons.attach_money, 'Valeur actuelle', formatCurrency.format(equipment.currentValue!)),
                if (equipment.supplier != null)
                  _buildInfoRow(Icons.store, 'Fournisseur', equipment.supplier!),
                if (equipment.purchasePrice != null && equipment.currentValue != null)
                  _buildInfoRow(Icons.trending_down, 'Dépréciation', '${equipment.depreciationRate?.toStringAsFixed(1) ?? 0}%'),
              ]),
            ],

            // Dates importantes
            const SizedBox(height: 16),
            _buildInfoCard('Dates importantes', [
              if (equipment.purchaseDate != null)
                _buildInfoRow(Icons.shopping_cart, 'Date d\'achat', formatDate.format(equipment.purchaseDate!)),
              if (equipment.warrantyExpiry != null)
                _buildInfoRow(
                  Icons.security,
                  'Expiration garantie',
                  formatDate.format(equipment.warrantyExpiry!),
                  isOverdue: equipment.isWarrantyExpired,
                  isExpiringSoon: equipment.isWarrantyExpiringSoon,
                ),
              if (equipment.lastMaintenance != null)
                _buildInfoRow(Icons.build, 'Dernière maintenance', formatDate.format(equipment.lastMaintenance!)),
              if (equipment.nextMaintenance != null)
                _buildInfoRow(
                  Icons.schedule,
                  'Prochaine maintenance',
                  formatDate.format(equipment.nextMaintenance!),
                  isOverdue: equipment.needsMaintenance,
                ),
              if (equipment.ageInYears != null)
                _buildInfoRow(Icons.cake, 'Âge', '${equipment.ageInYears} ans'),
            ]),

            // Notes
            if (equipment.notes != null && equipment.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes', [
                _buildInfoRow(Icons.note, 'Notes', equipment.notes!),
              ]),
            ],

            // Pièces jointes
            if (equipment.attachments != null && equipment.attachments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Pièces jointes', [
                for (String attachment in equipment.attachments!)
                  _buildInfoRow(Icons.attach_file, 'Fichier', attachment),
              ]),
            ],

            // Historique des actions
            const SizedBox(height: 16),
            _buildHistoryCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(context, ref, state, notifier),
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
              backgroundColor: equipment.statusColor.withOpacity(0.1),
              child: Icon(
                equipment.statusIcon,
                size: 30,
                color: equipment.statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(equipment.category),
                        size: 16,
                        color: _getCategoryColor(equipment.category),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCategoryLabel(equipment.category),
                        style: TextStyle(
                          color: _getCategoryColor(equipment.category),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        equipment.conditionIcon,
                        size: 16,
                        color: equipment.conditionColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        equipment.conditionText,
                        style: TextStyle(
                          color: equipment.conditionColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(equipment.createdAt)}',
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
        color: equipment.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: equipment.statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(equipment.statusIcon, size: 16, color: equipment.statusColor),
          const SizedBox(width: 4),
          Text(
            equipment.statusText,
            style: TextStyle(
              color: equipment.statusColor,
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
    bool? isOverdue,
    bool? isExpiringSoon,
  }) {
    Color? textColor;
    if (isOverdue == true) {
      textColor = Colors.red;
    } else if (isExpiringSoon == true) {
      textColor = Colors.orange;
    }

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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            _buildHistoryItem(
              Icons.add,
              'Créé',
              DateFormat('dd/MM/yyyy à HH:mm').format(equipment.createdAt),
              Colors.blue,
            ),
            if (equipment.updatedAt != equipment.createdAt)
              _buildHistoryItem(
                Icons.edit,
                'Modifié',
                DateFormat('dd/MM/yyyy à HH:mm').format(equipment.updatedAt),
                Colors.orange,
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
    EquipmentState state,
    EquipmentNotifier notifier,
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
                if (state.canManageEquipments) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      onPressed: () => context.go(
                          '/equipments/${equipment.id}/edit',
                          extra: equipment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.build),
                    label: const Text('Maintenance'),
                    onPressed: () => _showMaintenanceDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text('Détails'),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
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

  void _shareEquipment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à implémenter'),
      ),
    );
  }

  void _showMaintenanceDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de maintenance à implémenter'),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'computer':
        return Icons.computer;
      case 'printer':
        return Icons.print;
      case 'network':
        return Icons.router;
      case 'server':
        return Icons.dns;
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet;
      case 'monitor':
        return Icons.monitor;
      default:
        return Icons.devices_other;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'computer':
        return Colors.blue;
      case 'printer':
        return Colors.green;
      case 'network':
        return Colors.orange;
      case 'server':
        return Colors.purple;
      case 'mobile':
        return Colors.teal;
      case 'tablet':
        return Colors.indigo;
      case 'monitor':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'computer':
        return 'Ordinateur';
      case 'printer':
        return 'Imprimante';
      case 'network':
        return 'Réseau';
      case 'server':
        return 'Serveur';
      case 'mobile':
        return 'Mobile';
      case 'tablet':
        return 'Tablette';
      case 'monitor':
        return 'Écran';
      default:
        return 'Autre';
    }
  }
}
