import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/equipment_notifier.dart';
import 'package:easyconnect/providers/equipment_state.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:intl/intl.dart';

class EquipmentList extends ConsumerStatefulWidget {
  const EquipmentList({super.key});

  @override
  ConsumerState<EquipmentList> createState() => _EquipmentListState();
}

class _EquipmentListState extends ConsumerState<EquipmentList> {
  static const List<String> _tabStatuses = [
    'active',
    'inactive',
    'maintenance',
    'broken',
    'retired',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(equipmentProvider.notifier);
      notifier.loadEquipments(forceRefresh: true);
      notifier.loadEquipmentStats();
      notifier.loadEquipmentCategories();
      notifier.loadEquipmentsNeedingMaintenance();
      notifier.loadEquipmentsWithExpiredWarranty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(equipmentProvider);
    final notifier = ref.read(equipmentProvider.notifier);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des Équipements'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => notifier.loadEquipments(forceRefresh: true),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.check_circle), text: 'Actif'),
              Tab(icon: Icon(Icons.pause_circle), text: 'Inactif'),
              Tab(icon: Icon(Icons.build), text: 'Maintenance'),
              Tab(icon: Icon(Icons.error), text: 'Hors service'),
              Tab(icon: Icon(Icons.archive), text: 'Retiré'),
            ],
          ),
        ),
        body: TabBarView(
          children: List.generate(5, (i) {
            return _buildEquipmentTab(_tabStatuses[i], state, notifier);
          }),
        ),
        floatingActionButton: state.canManageEquipments
            ? FloatingActionButton.extended(
                onPressed: () => context.go('/equipments/new'),
                icon: const Icon(Icons.add),
                label: const Text('Nouvel Équipement'),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                elevation: 8,
                tooltip: 'Créer un nouvel équipement',
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildEquipmentTab(
    String status,
    EquipmentState state,
    EquipmentNotifier notifier,
  ) {
    final normalized = status.toLowerCase().trim();
    final list = state.equipments
        .where((e) => e.status.toLowerCase().trim() == normalized)
        .toList();

    if (state.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    if (list.isEmpty) {
      if (state.equipments.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => notifier.loadEquipments(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 320,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.devices_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun équipement chargé',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tirez pour actualiser',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                      onPressed: () => notifier.loadEquipments(forceRefresh: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => notifier.loadEquipments(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getEmptyIcon(status), size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyMessage(status),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptySubMessage(status),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadEquipments(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final equipment = list[index];
          return _buildEquipmentCard(context, equipment, state, notifier);
        },
      ),
    );
  }

  IconData _getEmptyIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.check_circle_outline;
      case 'inactive':
        return Icons.pause_circle_outline;
      case 'maintenance':
        return Icons.build_outlined;
      case 'broken':
        return Icons.error_outline;
      case 'retired':
        return Icons.archive_outlined;
      default:
        return Icons.devices_outlined;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'active':
        return 'Aucun équipement actif';
      case 'inactive':
        return 'Aucun équipement inactif';
      case 'maintenance':
        return 'Aucun équipement en maintenance';
      case 'broken':
        return 'Aucun équipement hors service';
      case 'retired':
        return 'Aucun équipement retiré';
      default:
        return 'Aucun équipement trouvé';
    }
  }

  String _getEmptySubMessage(String status) {
    switch (status) {
      case 'active':
        return 'Les équipements actifs apparaîtront ici';
      case 'inactive':
        return 'Les équipements inactifs apparaîtront ici';
      case 'maintenance':
        return 'Les équipements en maintenance apparaîtront ici';
      case 'broken':
        return 'Les équipements hors service apparaîtront ici';
      case 'retired':
        return 'Les équipements retirés apparaîtront ici';
      default:
        return 'Commencez par ajouter un équipement';
    }
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    Equipment equipment,
    EquipmentState state,
    EquipmentNotifier notifier,
  ) {
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/equipments/${equipment.id}', extra: equipment),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      equipment.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(equipment),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(equipment.category),
                    size: 16,
                    color: _getCategoryColor(equipment.category),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryLabel(equipment.category),
                    style: TextStyle(
                      color: _getCategoryColor(equipment.category),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    equipment.conditionIcon,
                    size: 16,
                    color: equipment.conditionColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    equipment.conditionText,
                    style: TextStyle(
                      color: equipment.conditionColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (equipment.description.isNotEmpty)
                Text(
                  equipment.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              if (equipment.serialNumber != null) ...[
                Row(
                  children: [
                    Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'S/N: ${equipment.serialNumber}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (equipment.location != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      equipment.location!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (equipment.assignedTo != null) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Assigné à: ${equipment.assignedTo}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (equipment.nextMaintenance != null) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Prochaine maintenance: ${formatDate.format(equipment.nextMaintenance!)}',
                      style: TextStyle(
                        color: equipment.needsMaintenance
                            ? Colors.red
                            : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: equipment.needsMaintenance
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (equipment.warrantyExpiry != null) ...[
                Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Garantie: ${formatDate.format(equipment.warrantyExpiry!)}',
                      style: TextStyle(
                        color: equipment.isWarrantyExpired
                            ? Colors.red
                            : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: equipment.isWarrantyExpired
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (state.canManageEquipments) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => context.go(
                          '/equipments/${equipment.id}/edit',
                          extra: equipment),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Détails'),
                    onPressed: () => context.go(
                        '/equipments/${equipment.id}',
                        extra: equipment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Equipment equipment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: equipment.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: equipment.statusColor.withOpacity(0.5)),
      ),
      child: Text(
        equipment.statusText,
        style: TextStyle(
          color: equipment.statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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
