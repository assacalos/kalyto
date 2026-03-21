import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/contract_notifier.dart';
import 'package:easyconnect/providers/contract_state.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class ContractValidationPage extends ConsumerStatefulWidget {
  const ContractValidationPage({super.key});

  @override
  ConsumerState<ContractValidationPage> createState() =>
      _ContractValidationPageState();
}

class _ContractValidationPageState extends ConsumerState<ContractValidationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContracts());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) _loadContracts();
  }

  Future<void> _loadContracts() async {
    String? status;
    switch (_tabController.index) {
      case 0:
        status = null;
        break;
      case 1:
        status = 'pending';
        break;
      case 2:
        status = 'active';
        break;
      case 3:
        status = 'cancelled';
        break;
    }
    final notifier = ref.read(contractProvider.notifier);
    notifier.filterByStatus(status ?? 'all');
    await notifier.loadContracts();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contractProvider);
    final notifier = ref.read(contractProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Contrats'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContracts,
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
            Tab(text: 'Actifs', icon: Icon(Icons.check_circle)),
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
                hintText: 'Rechercher par employé, département...',
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
                : _buildContractList(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildContractList(
      ContractState state, ContractNotifier notifier) {
    List<Contract> filteredContracts = List.from(state.contracts);
    switch (_tabController.index) {
      case 1:
        filteredContracts =
            state.contracts.where((c) => c.status == 'pending').toList();
        break;
      case 2:
        filteredContracts =
            state.contracts.where((c) => c.status == 'active').toList();
        break;
      case 3:
        filteredContracts =
            state.contracts.where((c) => c.status == 'cancelled').toList();
        break;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredContracts = filteredContracts.where((c) {
        return c.employeeName.toLowerCase().contains(q) ||
            c.department.toLowerCase().contains(q) ||
            c.jobTitle.toLowerCase().contains(q);
      }).toList();
    }

    if (filteredContracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun contrat trouvé'
                  : 'Aucun contrat correspondant à "$_searchQuery"',
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
      itemCount: filteredContracts.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final contract = filteredContracts[index];
        return _buildContractCard(context, contract, notifier);
      },
    );
  }

  Widget _buildContractCard(BuildContext context, Contract contract,
      ContractNotifier notifier) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(contract.status);
    final statusIcon = _getStatusIcon(contract.status);
    final statusText = _getStatusText(contract.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          contract.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Poste: ${contract.jobTitle}'),
            Text('Département: ${contract.department}'),
            Text(
              'Du ${formatDate.format(contract.startDate)}${contract.endDate != null ? ' au ${formatDate.format(contract.endDate!)}' : ''}',
            ),
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
                const Text(
                  'Informations du contrat',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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
                      Text('Numéro: ${contract.contractNumber}'),
                      Text('Employé: ${contract.employeeName}'),
                      Text('Email: ${contract.employeeEmail}'),
                      if (contract.employeePhone != null)
                        Text('Téléphone: ${contract.employeePhone}'),
                      Text('Type: ${contract.contractType}'),
                      Text('Poste: ${contract.jobTitle}'),
                      Text('Département: ${contract.department}'),
                      Text(
                        'Salaire brut: ${contract.grossSalary.toStringAsFixed(0)} ${contract.salaryCurrency}',
                      ),
                      Text(
                        'Salaire net: ${contract.netSalary.toStringAsFixed(0)} ${contract.salaryCurrency}',
                      ),
                      Text('Fréquence: ${contract.paymentFrequency}'),
                      Text('Horaire: ${contract.workSchedule}'),
                      Text('Heures/semaine: ${contract.weeklyHours}'),
                      Text(
                        'Date début: ${formatDate.format(contract.startDate)}',
                      ),
                      if (contract.endDate != null)
                        Text(
                          'Date fin: ${formatDate.format(contract.endDate!)}',
                        ),
                      if (contract.workLocation.isNotEmpty)
                        Text('Lieu: ${contract.workLocation}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(context, contract, statusColor, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Contract contract,
      Color statusColor, ContractNotifier notifier) {
    if (contract.status == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showApproveConfirmation(context, contract, notifier),
            icon: const Icon(Icons.check),
            label: const Text('Valider'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showRejectDialog(context, contract, notifier),
            icon: const Icon(Icons.close),
            label: const Text('Rejeter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    } else if (contract.status == 'active') {
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
              'Contrat validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (contract.status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Contrat rejeté',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (contract.rejectionReason != null &&
                contract.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Motif: ${contract.rejectionReason}',
                style: TextStyle(
                    color: Colors.red[700], fontSize: 12),
              ),
            ],
          ],
        ),
      );
    }
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
            'Statut: ${contract.status}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.blue;
      case 'terminated':
        return Colors.red;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'active':
        return Icons.check_circle;
      case 'expired':
        return Icons.event_busy;
      case 'terminated':
        return Icons.block;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'active':
        return 'Actif';
      case 'expired':
        return 'Expiré';
      case 'terminated':
        return 'Résilié';
      case 'cancelled':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  void _showApproveConfirmation(BuildContext context, Contract contract,
      ContractNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider ce contrat ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.approveContract(contract);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Contrat validé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _loadContracts();
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Contract contract,
      ContractNotifier notifier) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le contrat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un motif de rejet'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              notifier.rejectContract(
                  contract, reasonController.text.trim());
              _loadContracts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contrat rejeté'),
                  backgroundColor: Colors.orange,
                ),
              );
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
}
