import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/bon_commande_notifier.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class BonCommandeValidationPage extends ConsumerStatefulWidget {
  const BonCommandeValidationPage({super.key});

  @override
  ConsumerState<BonCommandeValidationPage> createState() =>
      _BonCommandeValidationPageState();
}

class _BonCommandeValidationPageState extends ConsumerState<BonCommandeValidationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) _loadBonCommandes();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBonCommandes(forceRefresh: true));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBonCommandes({bool forceRefresh = false}) async {
    int? status;
    switch (_tabController.index) {
      case 0: status = null; break;
      case 1: status = 1; break;
      case 2: status = 2; break;
      case 3: status = 3; break;
    }
    await ref.read(bonCommandeProvider.notifier).loadBonCommandes(status: status, forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bonCommandeProvider);
    final notifier = ref.read(bonCommandeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Bons de Commande'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBonCommandes(forceRefresh: true),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const SkeletonSearchResults(itemCount: 6)
                : _buildBonCommandeList(state.bonCommandes, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildBonCommandeList(List<BonCommande> bonCommandes, BonCommandeNotifier notifier) {
    final filtered = _searchQuery.isEmpty
        ? bonCommandes
        : bonCommandes
            .where(
              (bon) =>
                  bon.id.toString().contains(_searchQuery) ||
                  bon.clientId.toString().contains(_searchQuery),
            )
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun bon de commande trouvé'
                  : 'Aucun bon de commande correspondant à "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
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
      itemCount: filtered.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final bonCommande = filtered[index];
        return _buildBonCommandeCard(context, ref, bonCommande, notifier);
      },
    );
  }

  Widget _buildBonCommandeCard(BuildContext context, WidgetRef ref, BonCommande bonCommande, BonCommandeNotifier notifier) {
    final statusColor = _getStatusColor(bonCommande.status);
    final statusIcon = _getStatusIcon(bonCommande.status);
    final statusText = _getStatusText(bonCommande.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bonCommande.clientNomEntreprise?.isNotEmpty == true
                  ? bonCommande.clientNomEntreprise!
                  : 'Client #${bonCommande.clientId}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text('Bon de commande #${bonCommande.id ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Fichiers: ${bonCommande.fichiers.length}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informations générales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
                      Text('ID: ${bonCommande.id ?? 'N/A'}'),
                      Text('Client ID: ${bonCommande.clientId}'),
                      Text('Commercial ID: ${bonCommande.commercialId}'),
                      Text('Fichiers: ${bonCommande.fichiers.length}'),
                      if (bonCommande.fichiers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Liste des fichiers:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bonCommande.fichiers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.attach_file, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(bonCommande.fichiers[index])),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(context, ref, bonCommande, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, BonCommande bonCommande, BonCommandeNotifier notifier) {
    switch (bonCommande.status) {
      case 1:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showApproveConfirmation(context, ref, bonCommande, notifier),
              icon: const Icon(Icons.check),
              label: const Text('Valider'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: () => _showRejectDialog(context, ref, bonCommande, notifier),
              icon: const Icon(Icons.close),
              label: const Text('Rejeter'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            Container(
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
                  Text('Bon de commande validé', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _generatePdf(context, ref, bonCommande.id!, notifier),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Générer PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        );
      case 3:
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
              Text('Bon de commande rejeté', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
            ],
          ),
        );
      default:
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
              Text('Statut: ${bonCommande.status}', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ],
          ),
        );
    }
  }

  Future<void> _generatePdf(BuildContext context, WidgetRef ref, int id, BonCommandeNotifier notifier) async {
    try {
      await notifier.generatePDF(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF généré avec succès'), backgroundColor: Colors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1: return Colors.orange;
      case 2: return Colors.green;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1: return Icons.pending;
      case 2: return Icons.check_circle;
      case 3: return Icons.cancel;
      default: return Icons.help;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1: return 'En attente';
      case 2: return 'Validé';
      case 3: return 'Rejeté';
      default: return 'Inconnu';
    }
  }

  void _showApproveConfirmation(BuildContext context, WidgetRef ref, BonCommande bonCommande, BonCommandeNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider ce bon de commande ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.approveBonCommande(bonCommande.id!);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bon de commande approuvé avec succès'), backgroundColor: Colors.green));
                _loadBonCommandes();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, BonCommande bonCommande, BonCommandeNotifier notifier) {
    final commentController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le bon de commande'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(labelText: 'Motif du rejet', hintText: 'Entrez le motif du rejet'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer un motif de rejet'), backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectBonCommande(bonCommande.id!, commentController.text.trim());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bon de commande rejeté avec succès'), backgroundColor: Colors.orange));
                _loadBonCommandes();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
