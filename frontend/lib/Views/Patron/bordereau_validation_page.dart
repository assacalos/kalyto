import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/bordereau_notifier.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class BordereauValidationPage extends ConsumerStatefulWidget {
  const BordereauValidationPage({super.key});

  @override
  ConsumerState<BordereauValidationPage> createState() =>
      _BordereauValidationPageState();
}

class _BordereauValidationPageState extends ConsumerState<BordereauValidationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBordereaux(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadBordereaux();
    }
  }

  Future<void> _loadBordereaux({bool forceRefresh = false}) async {
    int? status;
    switch (_tabController.index) {
      case 0:
        status = null;
        break;
      case 1:
        status = 1;
        break;
      case 2:
        status = 2;
        break;
      case 3:
        status = 3;
        break;
    }
    await ref.read(bordereauProvider.notifier).loadBordereaux(status: status, forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    final bordereauState = ref.watch(bordereauProvider);
    final notifier = ref.read(bordereauProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Bordereaux'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBordereaux(forceRefresh: true),
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
                hintText: 'Rechercher par référence...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
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
            child: bordereauState.isLoading
                ? const SkeletonSearchResults(itemCount: 6)
                : _buildBordereauList(bordereauState.bordereaux, _searchQuery, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildBordereauList(List<Bordereau> bordereaux, String searchQuery, BordereauNotifier notifier) {
    final filteredBordereaux = searchQuery.isEmpty
        ? bordereaux
        : bordereaux
            .where(
              (bordereau) => bordereau.reference.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
            )
            .toList();

    if (filteredBordereaux.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'Aucun bordereau trouvé'
                  : 'Aucun bordereau correspondant à "$searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (searchQuery.isNotEmpty) ...[
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
      itemCount: filteredBordereaux.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final bordereau = filteredBordereaux[index];
        return _buildBordereauCard(context, ref, bordereau, notifier);
      },
    );
  }

  Widget _buildBordereauCard(BuildContext context, WidgetRef ref, Bordereau bordereau, BordereauNotifier notifier) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
    );
    final statusColor = _getStatusColor(bordereau.status);
    final statusIcon = _getStatusIcon(bordereau.status);
    final statusText = _getStatusText(bordereau.status);

    // Calculer le total
    double totalHT = 0;
    for (final item in bordereau.items) {
      totalHT += item.montantTotal;
    }
    final totalTTC = totalHT;

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
              bordereau.clientNomEntreprise?.isNotEmpty == true
                  ? bordereau.clientNomEntreprise!
                  : 'Client #${bordereau.clientId}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              bordereau.reference,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${formatDate.format(bordereau.dateCreation)}'),
            Text('Total: ${formatCurrency.format(totalTTC)}'),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                const Text(
                  'Informations générales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                      Text('Référence: ${bordereau.reference}'),
                      Text('Client ID: ${bordereau.clientId}'),
                      Text('Commercial ID: ${bordereau.commercialId}'),
                      if (bordereau.devisId != null)
                        Text('Devis ID: ${bordereau.devisId}'),
                      Text(
                        'Date création: ${formatDate.format(bordereau.dateCreation)}',
                      ),
                      if (bordereau.dateValidation != null)
                        Text(
                          'Date validation: ${formatDate.format(bordereau.dateValidation!)}',
                        ),
                      if (bordereau.notes != null)
                        Text('Notes: ${bordereau.notes}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Détails des articles
                const Text(
                  'Détails des articles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (bordereau.items.isEmpty)
                  const Text('Aucun article')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bordereau.items.length,
                    itemBuilder: (context, index) {
                      return _buildItemDetails(bordereau.items[index]);
                    },
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sous-total HT:'),
                          Text(formatCurrency.format(totalHT)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total TTC:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatCurrency.format(totalTTC),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(context, ref, bordereau, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetails(BordereauItem item) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.designation,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.description != null)
                  Text(
                    item.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Expanded(child: Text('${item.quantite} ${item.unite}')),
          Expanded(
            child: Text(
              formatCurrency.format(item.montantTotal),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Bordereau bordereau, BordereauNotifier notifier) {
    switch (bordereau.status) {
      case 1: // En attente - Afficher boutons Valider/Rejeter
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showApproveConfirmation(context, ref, bordereau, notifier),
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRejectDialog(context, ref, bordereau, notifier),
                  icon: const Icon(Icons.close),
                  label: const Text('Rejeter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      case 2: // Validé - Afficher info et bouton PDF
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
                  Text(
                    'Bordereau validé',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _generatePdf(context, ref, bordereau.id!, notifier),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Générer PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      case 3: // Rejeté - Afficher motif du rejet
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
                'Bordereau rejeté',
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
                'Statut: ${bordereau.status}',
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
      case 1: // En attente
        return Colors.orange;
      case 2: // Validé
        return Colors.green;
      case 3: // Rejeté
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1: // En attente
        return Icons.pending;
      case 2: // Validé
        return Icons.check_circle;
      case 3: // Rejeté
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1: // En attente
        return 'En attente';
      case 2: // Validé
        return 'Validé';
      case 3: // Rejeté
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  Future<void> _generatePdf(BuildContext context, WidgetRef ref, int id, BordereauNotifier notifier) async {
    try {
      await notifier.generatePDF(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF généré avec succès'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showApproveConfirmation(BuildContext context, WidgetRef ref, Bordereau bordereau, BordereauNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider ce bordereau ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await notifier.approveBordereau(bordereau.id!);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bordereau approuvé avec succès'), backgroundColor: Colors.green),
                );
                _loadBordereaux();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, Bordereau bordereau, BordereauNotifier notifier) {
    final commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le bordereau'),
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
                  const SnackBar(content: Text('Veuillez entrer un motif de rejet'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.of(ctx).pop();
              try {
                await notifier.rejectBordereau(bordereau.id!, commentController.text.trim());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bordereau rejeté avec succès'), backgroundColor: Colors.orange),
                );
                _loadBordereaux();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
