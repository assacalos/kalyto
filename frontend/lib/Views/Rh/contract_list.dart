import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/contract_notifier.dart';
import 'package:easyconnect/providers/contract_state.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class ContractList extends ConsumerStatefulWidget {
  const ContractList({super.key});

  @override
  ConsumerState<ContractList> createState() => _ContractListState();
}

class _ContractListState extends ConsumerState<ContractList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  static const List<String> _tabStatuses = [
    'pending',
    'active',
    'expired',
    'terminated',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contractProvider.notifier).filterByStatus('all');
      ref.read(contractProvider.notifier).loadContracts(forceRefresh: true);
      ref.read(contractProvider.notifier).loadContractStats();
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
    final state = ref.watch(contractProvider);
    final notifier = ref.read(contractProvider.notifier);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Contrats'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                notifier.filterByStatus('all');
                notifier.loadContracts(forceRefresh: true);
              },
              tooltip: 'Actualiser',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'En attente'),
              Tab(text: 'Actifs'),
              Tab(text: 'Expirés'),
              Tab(text: 'Résiliés'),
              Tab(text: 'Annulés'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: List.generate(5, (i) {
                return _buildContractList(
                  _tabStatuses[i],
                  state,
                  notifier,
                );
              }),
            ),
            Positioned(
              bottom: 80,
              right: 16,
              child: UniformAddButton(
                onPressed: () => context.go('/contracts/new'),
                label: 'Nouveau Contrat',
                icon: Icons.description,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildContractList(
    String status,
    ContractState state,
    ContractNotifier notifier,
  ) {
    if (state.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    final contractList =
        state.contracts.where((c) => c.status == status).toList();

    if (contractList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.loadContracts(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == 'pending'
                        ? Icons.pending
                        : status == 'active'
                            ? Icons.check_circle
                            : status == 'expired'
                                ? Icons.event_busy
                                : status == 'terminated'
                                    ? Icons.block
                                    : Icons.cancel,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == 'pending'
                        ? 'Aucun contrat en attente'
                        : status == 'active'
                            ? 'Aucun contrat actif'
                            : status == 'expired'
                                ? 'Aucun contrat expiré'
                                : status == 'terminated'
                                    ? 'Aucun contrat résilié'
                                    : 'Aucun contrat annulé',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadContracts(forceRefresh: true),
      child: PaginatedListView(
        scrollController: _scrollController,
        onLoadMore: notifier.loadMore,
        hasNextPage: state.hasNextPage,
        isLoadingMore: state.isLoadingMore,
        itemCount: contractList.length,
        itemBuilder: (context, index) {
          final contract = contractList[index];
          return _buildContractCard(context, contract, notifier);
        },
      ),
    );
  }

  Widget _buildContractCard(
    BuildContext context,
    Contract contract,
    ContractNotifier notifier,
  ) {
    final formatDate = DateFormat('dd/MM/yyyy');
    Color statusColor;
    IconData statusIcon;
    String statusText;
    switch (contract.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'En attente';
        break;
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Actif';
        break;
      case 'expired':
        statusColor = Colors.blue;
        statusIcon = Icons.event_busy;
        statusText = 'Expiré';
        break;
      case 'terminated':
        statusColor = Colors.red;
        statusIcon = Icons.block;
        statusText = 'Résilié';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = 'Annulé';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Inconnu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () =>
            context.go('/contracts/${contract.id}', extra: contract),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.contractNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contract.employeeName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.work, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contract.jobTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(contract.department),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${contract.grossSalary.toStringAsFixed(0)} ${contract.salaryCurrency}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Du ${formatDate.format(contract.startDate)}${contract.endDate != null ? ' au ${formatDate.format(contract.endDate!)}' : ''}',
                  ),
                ],
              ),
              if (contract.status == 'active') ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _showTerminateDialog(context, contract, notifier),
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Résilier'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTerminateDialog(
    BuildContext context,
    Contract contract,
    ContractNotifier notifier,
  ) {
    DateTime? selectedDate;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Résilier le contrat'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Veuillez indiquer la date et la raison de résiliation :',
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: contract.startDate,
                      lastDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de résiliation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                          : 'Sélectionner une date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Raison de résiliation',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                if (selectedDate == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner une date'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez indiquer la raison'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await notifier.terminateContract(
                    contract,
                    reasonController.text.trim(),
                    selectedDate!,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contrat résilié'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
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
              child: const Text('Résilier'),
            ),
          ],
        ),
      ),
    );
  }
}
