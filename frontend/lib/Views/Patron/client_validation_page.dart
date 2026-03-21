import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/client_notifier.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class ClientValidationPage extends ConsumerStatefulWidget {
  const ClientValidationPage({super.key});

  @override
  ConsumerState<ClientValidationPage> createState() =>
      _ClientValidationPageState();
}

class _ClientValidationPageState extends ConsumerState<ClientValidationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  int? _lastLoadedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _onTabChanged();
    });
    // Charger toutes les données une fois au démarrage (forceRefresh pour que le patron voie les nouveaux clients)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllClients();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Refaire l’affichage pour appliquer le filtre selon l’onglet
    if (mounted) setState(() {});

    // Ne pas recharger si on est déjà en train de charger
    if (_isLoading) return;

    // Ne pas recharger si on charge le même statut
    final currentStatus = _getStatusForTab(_tabController.index);
    if (_lastLoadedStatus == currentStatus &&
        ref.read(clientProvider).clients.isNotEmpty) {
      return;
    }

    _loadClients();
  }

  // Charger toutes les données une fois (sans filtre)
  Future<void> _loadAllClients() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      // Charger tous les clients une fois, le filtrage se fera côté client
      await ref.read(clientProvider.notifier).loadClients(
            status: null,
            forceRefresh: true,
          );
      _lastLoadedStatus = null; // null = tous les clients
    } catch (e) {
      debugPrint('❌ [CLIENT_VALIDATION] Erreur lors du chargement initial: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadClients() async {
    // Protection contre les appels multiples
    if (_isLoading) return;

    try {
      _isLoading = true;

      // Charger tous les clients une fois, le filtrage se fera côté client
      // Cela évite les rechargements multiples lors du changement d'onglet
      if (_lastLoadedStatus == null &&
          ref.read(clientProvider).clients.isNotEmpty) {
        _isLoading = false;
        return;
      }

      await ref.read(clientProvider.notifier).loadClients(
            status: null,
            forceRefresh: false,
          );
      _lastLoadedStatus = null;
    } catch (e) {
      debugPrint('❌ [CLIENT_VALIDATION] Erreur lors du chargement: $e');
      if (ref.read(clientProvider).clients.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Impossible de charger les clients. Vérifiez votre connexion.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  int? _getStatusForTab(int tabIndex) {
    switch (tabIndex) {
      case 0: // Tous
        return null;
      case 1: // En attente
        return 0;
      case 2: // Validés
        return 1;
      case 3: // Rejetés
        return 2;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Clients'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAllClients();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Contenu des onglets
          Expanded(
            child: ref.watch(clientProvider).isLoading
                ? const SkeletonSearchResults(itemCount: 6)
                : _buildClientList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientList() {
    final statusForTab = _getStatusForTab(_tabController.index);
    var list = statusForTab == null
        ? ref.read(clientProvider).clients
        : ref
            .read(clientProvider)
            .clients
            .where((c) => c.status == statusForTab)
            .toList();
    final filteredClients =
        _searchQuery.isEmpty
            ? list
            : list.where((client) {
              final queryLower = _searchQuery.toLowerCase();
              final nomEntreprise = (client.nomEntreprise ?? '').toLowerCase();
              final nom = (client.nom ?? '').toLowerCase();
              final prenom = (client.prenom ?? '').toLowerCase();
              final email = (client.email ?? '').toLowerCase();
              final contact = (client.contact ?? '').toLowerCase();
              return nomEntreprise.contains(queryLower) ||
                  nom.contains(queryLower) ||
                  prenom.contains(queryLower) ||
                  email.contains(queryLower) ||
                  contact.contains(queryLower);
            }).toList();

    if (filteredClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun client trouvé'
                  : 'Aucun client correspondant à "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredClients.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        return _buildClientCard(context, client);
      },
    );
  }

  Widget _buildClientCard(BuildContext context, Client client) {
    final statusColor = _getStatusColor(client.status ?? 0);
    final statusIcon = _getStatusIcon(client.status ?? 0);
    final statusText = _getStatusText(client.status ?? 0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          client.nomEntreprise?.isNotEmpty == true
              ? client.nomEntreprise!
              : '${client.nom ?? ''} ${client.prenom ?? ''}'.trim().isNotEmpty
              ? '${client.nom ?? ''} ${client.prenom ?? ''}'.trim()
              : 'Client #${client.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Email: ${client.email ?? ''}'),
            Text('Téléphone: ${client.contact ?? ''}'),
            Text('Date création: ${client.createdAt ?? 'N/A'}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations détaillées
                const Text(
                  'Informations détaillées',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nom entreprise: ${client.nomEntreprise ?? 'N/A'}'),
                      if (client.nom != null || client.prenom != null) ...[
                        Text('Nom: ${client.nom ?? ''}'),
                        Text('Prénom: ${client.prenom ?? ''}'),
                      ],
                      Text('Email: ${client.email ?? ''}'),
                      Text('Téléphone: ${client.contact ?? ''}'),
                      if (client.adresse != null)
                        Text('Adresse: ${client.adresse}'),
                      Text('Statut: $statusText'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButtons(client, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Client client, Color statusColor) {
    switch (client.status ?? 0) {
      case 0: // En attente - Afficher boutons Valider/Rejeter
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showApproveConfirmation(client),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Valider', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRejectDialog(client),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rejeter', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
          ],
        );
      case 1: // Validé - Afficher seulement info
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Client validé',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 2: // Rejeté - Afficher motif du rejet
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Client rejeté',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default: // Autres statuts
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Statut: ${client.status ?? 'Inconnu'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.pending;
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'En attente';
      case 1:
        return 'Validé';
      case 2:
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  void _showApproveConfirmation(Client client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider ce client ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = client.id;
              if (id == null) return;
              Navigator.of(ctx).pop();
              try {
                await ref.read(clientProvider.notifier).approveClient(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client validé avec succès')),
                  );
                }
                _loadAllClients().catchError((_) {});
              } catch (e) {
                rethrow;
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Client client) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet',
                hintText: 'Entrez le motif du rejet',
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
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez entrer un motif de rejet')),
                );
                return;
              }
              final id = client.id;
              if (id == null) return;
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(clientProvider.notifier)
                    .rejectClient(id, commentController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client rejeté avec succès')),
                  );
                }
                _loadAllClients().catchError((_) {});
              } catch (e) {
                rethrow;
              }
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
