import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/leave_notifier.dart';
import 'package:easyconnect/providers/leave_state.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class LeaveValidationPage extends ConsumerStatefulWidget {
  const LeaveValidationPage({super.key});

  @override
  ConsumerState<LeaveValidationPage> createState() =>
      _LeaveValidationPageState();
}

class _LeaveValidationPageState extends ConsumerState<LeaveValidationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLeaves());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadLeaves();
    }
  }

  Future<void> _loadLeaves() async {
    String status;
    switch (_tabController.index) {
      case 0:
        status = 'all';
        break;
      case 1:
        status = 'pending';
        break;
      case 2:
        status = 'approved';
        break;
      case 3:
        status = 'rejected';
        break;
      default:
        status = 'all';
    }
    final notifier = ref.read(leaveProvider.notifier);
    notifier.filterByStatus(status);
    await notifier.loadLeaveRequests();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Congés'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaves,
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
            Tab(text: 'Approuvés', icon: Icon(Icons.check_circle)),
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
                hintText: 'Rechercher par employé, type de congé...',
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
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const SkeletonSearchResults(itemCount: 6)
                : _buildLeaveList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveList(LeaveState state) {
    List<LeaveRequest> filteredLeaves = state.leaveRequests;

    switch (_tabController.index) {
      case 1:
        filteredLeaves =
            filteredLeaves.where((l) => l.status == 'pending').toList();
        break;
      case 2:
        filteredLeaves =
            filteredLeaves.where((l) => l.status == 'approved').toList();
        break;
      case 3:
        filteredLeaves =
            filteredLeaves.where((l) => l.status == 'rejected').toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredLeaves = filteredLeaves
          .where(
            (l) =>
                l.employeeName.toLowerCase().contains(q) ||
                l.leaveType.toLowerCase().contains(q) ||
                l.reason.toLowerCase().contains(q),
          )
          .toList();
    }

    if (filteredLeaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun congé trouvé'
                  : 'Aucun congé correspondant à "$_searchQuery"',
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
      itemCount: filteredLeaves.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final leave = filteredLeaves[index];
        return _buildLeaveCard(context, leave);
      },
    );
  }

  Widget _buildLeaveCard(BuildContext context, LeaveRequest leave) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(leave.status);
    final statusIcon = _getStatusIcon(leave.status);
    final statusText = _getStatusText(leave.status);
    final leaveTypeText = _getLeaveTypeText(leave.leaveType);
    final notifier = ref.read(leaveProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          leave.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Type: $leaveTypeText'),
            Text(
              'Du ${formatDate.format(leave.startDate)} au ${formatDate.format(leave.endDate)}',
            ),
            Text('Durée: ${leave.totalDays} jour(s)'),
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
                  'Informations de la demande',
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
                      Text('Employé: ${leave.employeeName}'),
                      Text('Type de congé: $leaveTypeText'),
                      Text(
                          'Date de début: ${formatDate.format(leave.startDate)}'),
                      Text('Date de fin: ${formatDate.format(leave.endDate)}'),
                      Text('Nombre de jours: ${leave.totalDays}'),
                      Text('Raison: ${leave.reason}'),
                      if (leave.comments != null &&
                          leave.comments!.isNotEmpty)
                        Text('Commentaires: ${leave.comments}'),
                      if (leave.approvedAt != null)
                        Text(
                          'Approuvé le: ${formatDate.format(leave.approvedAt!)}',
                        ),
                      if (leave.approvedByName != null)
                        Text('Approuvé par: ${leave.approvedByName}'),
                      if (leave.rejectionReason != null &&
                          leave.rejectionReason!.isNotEmpty)
                        Text(
                          'Motif du rejet: ${leave.rejectionReason}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      Text('Créé le: ${formatDate.format(leave.createdAt)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(leave, statusColor, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    LeaveRequest leave,
    Color statusColor,
    LeaveNotifier notifier,
  ) {
    if (leave.status == 'pending') {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(leave, notifier),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(leave, notifier),
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
    } else if (leave.status == 'approved') {
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
              'Congé approuvé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (leave.status == 'rejected') {
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
                  'Congé rejeté',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (leave.rejectionReason != null &&
                leave.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Motif: ${leave.rejectionReason}',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ],
          ],
        ),
      );
    } else {
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
              'Statut: ${leave.status}',
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
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
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  String _getLeaveTypeText(String leaveType) {
    switch (leaveType.toLowerCase()) {
      case 'annual':
        return 'Congés payés';
      case 'sick':
        return 'Congé maladie';
      case 'maternity':
        return 'Congé maternité';
      case 'paternity':
        return 'Congé paternité';
      case 'personal':
        return 'Congé personnel';
      case 'emergency':
        return 'Congé d\'urgence';
      case 'unpaid':
        return 'Congé sans solde';
      default:
        return leaveType;
    }
  }

  void _showApproveConfirmation(LeaveRequest leave, LeaveNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Voulez-vous approuver cette demande de congé ?',
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
                await notifier.approveLeaveRequest(leave);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demande approuvée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadLeaves();
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(LeaveRequest leave, LeaveNotifier notifier) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la demande de congé'),
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
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
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
              try {
                await notifier.rejectLeaveRequest(
                  leave,
                  reasonController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demande rejetée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadLeaves();
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
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
