import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/client_notifier.dart';
import 'package:easyconnect/providers/client_state.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/export_format_dialog.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:easyconnect/services/export_service.dart';
import 'package:intl/intl.dart';

class ClientsPage extends ConsumerStatefulWidget {
  final bool isPatron;
  final int status;

  const ClientsPage({super.key, this.isPatron = false, this.status = 1});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return "Validé";
      case 2:
        return "Rejeté";
      default:
        return "En attente";
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  @override
  void initState() {
    super.initState();
    final tabParam = Uri.base.queryParameters['tab'];
    final initialIndex = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      ref.read(clientProvider.notifier).loadClients(status: null, forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final notifier = ref.read(clientProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/commercial', iconColor: Colors.white),
        title: const Text('Clients'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Validés'),
            Tab(text: 'Rejetés'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
            onPressed: clientState.clients.isEmpty ? null : () => _exportClients(context, clientState.clients),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.refreshData(),
          ),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildClientList(0, clientState, notifier),
              _buildClientList(1, clientState, notifier),
              _buildClientList(2, clientState, notifier),
            ],
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: RoleBasedWidget(
              allowedRoles: [Roles.ADMIN, Roles.PATRON, Roles.COMMERCIAL],
              child: UniformAddButton(
                onPressed: () => context.go('/clients/new'),
                label: 'Nouveau Client',
                icon: Icons.person_add,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportClients(BuildContext context, List<Client> clients) async {
    final format = await showExportFormatDialog(context, title: 'Exporter les clients');
    if (format == null || !context.mounted) return;
    const headers = ['Id', 'Nom entreprise', 'Nom', 'Prénom', 'Email', 'Contact', 'Adresse', 'NINEA', 'N° contribuable', 'Statut', 'Créé le'];
    String statusStr(int s) => s == 1 ? 'Validé' : s == 2 ? 'Rejeté' : 'En attente';
    final rows = clients.map((c) => [
      c.id,
      c.nomEntreprise ?? '',
      c.nom ?? '',
      c.prenom ?? '',
      c.email ?? '',
      c.contact ?? '',
      c.adresse ?? '',
      c.ninea ?? '',
      c.numeroContribuable ?? '',
      statusStr(c.status ?? 0),
      c.createdAt ?? '',
    ]).toList();
    final base = 'clients_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    try {
      if (format == 'excel') {
        await ExportService.exportExcel(headers: headers, rows: rows, filenameBase: base, sheetName: 'Clients');
      } else {
        await ExportService.exportCsv(headers: headers, rows: rows, filenameBase: base);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export réussi')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Widget _buildClientList(int status, ClientState clientState, ClientNotifier notifier) {
    if (clientState.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    final clientList = clientState.clients
        .where((c) => c.status == status)
        .toList();

    if (clientList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 0
                  ? Icons.access_time
                  : status == 1
                  ? Icons.check_circle
                  : Icons.cancel,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              status == 0
                  ? 'Aucun client en attente'
                  : status == 1
                  ? 'Aucun client validé'
                  : 'Aucun client rejeté',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return PaginatedListView(
      scrollController: _scrollController,
      onLoadMore: notifier.loadMore,
      hasNextPage: clientState.hasNextPage,
      isLoadingMore: clientState.isLoadingMore,
      itemCount: clientList.length,
      itemBuilder: (context, index) {
        final client = clientList[index];
        return _buildClientCard(client);
      },
    );
  }

  Widget _buildClientCard(Client client) {
    final status = client.status ?? 0;
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/clients/${client.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom entreprise (prioritaire) et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      client.nomEntreprise?.isNotEmpty == true
                          ? client.nomEntreprise!
                          : "${client.prenom ?? ''} ${client.nom ?? ''}"
                              .trim()
                              .isNotEmpty
                          ? "${client.prenom ?? ''} ${client.nom ?? ''}".trim()
                          : 'Client #${client.id}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Informations client
              if (client.nomEntreprise?.isNotEmpty == true &&
                  "${client.prenom ?? ''} ${client.nom ?? ''}"
                      .trim()
                      .isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${client.prenom ?? ''} ${client.nom ?? ''}".trim(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      client.email.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(client.contact.toString()),
                ],
              ),

              // Raison du rejet
              if (status == 2 &&
                  (client.commentaire != null &&
                      client.commentaire!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison du rejet: ${client.commentaire}',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

              // Modifier : autorisé en attente (0) et validé (1)
              if (status == 0 || status == 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/clients/${client.id}/edit'),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                  ),
                ),
              ],
              // Actions selon le statut et le rôle (valider/rejeter uniquement en attente)
              if (status == 0) ...[
                const SizedBox(height: 8),
                RoleBasedWidget(
                  allowedRoles: [Roles.ADMIN, Roles.PATRON],
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(client),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Valider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectionDialog(client),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Rejeter'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showValidationDialog(Client client) {
    final notifier = ref.read(clientProvider.notifier);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider le client'),
        content: const Text('Êtes-vous sûr de vouloir valider ce client ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final id = client.id;
              if (id != null) {
                try {
                  await notifier.approveClient(id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Client validé avec succès')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
                notifier.loadByStatus(_tabController.index);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(Client client) {
    final notifier = ref.read(clientProvider.notifier);
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir rejeter ce client ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir une raison')),
                );
                return;
              }
              final id = client.id;
              if (id == null) return;
              Navigator.of(ctx).pop();
              try {
                await notifier.rejectClient(id, reasonController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client rejeté avec succès')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
              notifier.loadByStatus(_tabController.index);
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
