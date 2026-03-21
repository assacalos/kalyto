import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/intervention_notifier.dart';
import 'package:easyconnect/providers/intervention_state.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:intl/intl.dart';

class InterventionDetail extends ConsumerWidget {
  final Intervention intervention;

  const InterventionDetail({super.key, required this.intervention});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interventionProvider);
    final notifier = ref.read(interventionProvider.notifier);
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy à HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(intervention.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (state.canManageInterventions &&
              intervention.status == 'pending')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push(
                '/interventions/${intervention.id}/edit',
                extra: intervention,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareIntervention(context),
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
              _buildInfoRow(Icons.title, 'Titre', intervention.title),
              _buildInfoRow(Icons.category, 'Type', intervention.typeText),
              _buildInfoRow(
                Icons.priority_high,
                'Priorité',
                intervention.priorityText,
              ),
              _buildInfoRow(
                Icons.description,
                'Description',
                intervention.description,
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Planification', [
              _buildInfoRow(
                Icons.calendar_today,
                'Date programmée',
                DateFormat('dd/MM/yyyy').format(intervention.scheduledDate),
              ),
              if (intervention.startDate != null)
                _buildInfoRow(
                  Icons.play_arrow,
                  'Date de début',
                  formatDate.format(intervention.startDate!),
                ),
              if (intervention.endDate != null)
                _buildInfoRow(
                  Icons.stop,
                  'Date de fin',
                  formatDate.format(intervention.endDate!),
                ),
              if (intervention.estimatedDuration != null)
                _buildInfoRow(
                  Icons.schedule,
                  'Durée estimée',
                  '${intervention.estimatedDuration!.toStringAsFixed(1)}h',
                ),
              if (intervention.actualDuration != null)
                _buildInfoRow(
                  Icons.timer,
                  'Durée réelle',
                  '${intervention.actualDuration!.toStringAsFixed(1)}h',
                ),
            ]),
            if (intervention.clientName != null ||
                intervention.location != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Informations client', [
                if (intervention.clientName != null)
                  _buildInfoRow(Icons.person, 'Nom', intervention.clientName!),
                if (intervention.clientPhone != null)
                  _buildInfoRow(
                    Icons.phone,
                    'Téléphone',
                    intervention.clientPhone!,
                  ),
                if (intervention.clientEmail != null)
                  _buildInfoRow(
                    Icons.email,
                    'Email',
                    intervention.clientEmail!,
                  ),
                if (intervention.location != null)
                  _buildInfoRow(
                    Icons.location_on,
                    'Localisation',
                    intervention.location!,
                  ),
              ]),
            ],
            if (intervention.equipment != null ||
                intervention.problemDescription != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Informations techniques', [
                if (intervention.equipment != null)
                  _buildInfoRow(
                    Icons.build,
                    'Équipement',
                    intervention.equipment!,
                  ),
                if (intervention.problemDescription != null)
                  _buildInfoRow(
                    Icons.warning,
                    'Problème',
                    intervention.problemDescription!,
                  ),
                if (intervention.solution != null)
                  _buildInfoRow(
                    Icons.check_circle,
                    'Solution',
                    intervention.solution!,
                  ),
              ]),
            ],
            if (intervention.cost != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Coût', [
                _buildInfoRow(
                  Icons.euro,
                  'Coût',
                  formatCurrency.format(intervention.cost!),
                ),
              ]),
            ],
            if (intervention.notes != null &&
                intervention.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes', [
                _buildInfoRow(Icons.note, 'Notes', intervention.notes!),
              ]),
            ],
            if (intervention.status == 'rejected' &&
                intervention.rejectionReason != null &&
                intervention.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Motif du rejet', [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    intervention.rejectionReason!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ]),
            ],
            if (intervention.completionNotes != null &&
                intervention.completionNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes de fin', [
                _buildInfoRow(
                  Icons.done_all,
                  'Notes de fin',
                  intervention.completionNotes!,
                ),
              ]),
            ],
            if (intervention.attachments != null &&
                intervention.attachments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Pièces jointes', [
                for (String attachment in intervention.attachments!)
                  _buildInfoRow(Icons.attach_file, 'Fichier', attachment),
              ]),
            ],
            const SizedBox(height: 16),
            _buildHistoryCard(),
            const SizedBox(height: 16),
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
              backgroundColor: intervention.statusColor.withOpacity(0.1),
              child: Icon(
                intervention.statusIcon,
                size: 30,
                color: intervention.statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intervention.title,
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
                        intervention.typeIcon,
                        size: 16,
                        color: intervention.typeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        intervention.typeText,
                        style: TextStyle(
                          color: intervention.typeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        intervention.priorityIcon,
                        size: 16,
                        color: intervention.priorityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        intervention.priorityText,
                        style: TextStyle(
                          color: intervention.priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(intervention.createdAt)}',
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
        color: intervention.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: intervention.statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            intervention.statusIcon,
            size: 16,
            color: intervention.statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            intervention.statusText,
            style: TextStyle(
              color: intervention.statusColor,
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
              'Créée',
              DateFormat('dd/MM/yyyy à HH:mm').format(intervention.createdAt),
              Colors.blue,
            ),
            if (intervention.status == 'approved' &&
                intervention.approvedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Approuvée',
                DateFormat(
                  'dd/MM/yyyy à HH:mm',
                ).format(DateTime.parse(intervention.approvedAt!)),
                Colors.green,
              ),
            if (intervention.status == 'rejected')
              _buildHistoryItem(
                Icons.cancel,
                'Rejetée',
                DateFormat('dd/MM/yyyy à HH:mm').format(intervention.updatedAt),
                Colors.red,
              ),
            if (intervention.status == 'in_progress' &&
                intervention.startDate != null)
              _buildHistoryItem(
                Icons.play_arrow,
                'Démarrée',
                DateFormat(
                  'dd/MM/yyyy à HH:mm',
                ).format(intervention.startDate!),
                Colors.purple,
              ),
            if (intervention.status == 'completed' &&
                intervention.endDate != null)
              _buildHistoryItem(
                Icons.done_all,
                'Terminée',
                DateFormat('dd/MM/yyyy à HH:mm').format(intervention.endDate!),
                Colors.green,
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
    InterventionState state,
    InterventionNotifier notifier,
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
                if (intervention.status == 'pending' &&
                    state.canManageInterventions) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      onPressed: () => context.push(
                        '/interventions/${intervention.id}/edit',
                        extra: intervention,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (intervention.status == 'approved' &&
                    state.canManageInterventions) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Démarrer'),
                      onPressed: () => _showStartDialog(context, intervention, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (intervention.status == 'in_progress' &&
                    state.canManageInterventions) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text('Terminer'),
                      onPressed: () => _showCompleteDialog(context, intervention, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (intervention.status == 'pending' &&
                    state.canApproveInterventions) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(context, intervention, notifier),
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
                      onPressed: () => _showRejectDialog(context, intervention, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (intervention.status == 'completed') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir détails'),
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
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

  void _shareIntervention(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à implémenter'),
      ),
    );
  }

  void _showStartDialog(
    BuildContext context,
    Intervention intervention,
    InterventionNotifier notifier,
  ) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Démarrer l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir démarrer cette intervention ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
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
              notifier.startIntervention(intervention,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Intervention démarrée'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    Intervention intervention,
    InterventionNotifier notifier,
  ) {
    final solutionController = TextEditingController();
    final completionNotesController = TextEditingController();
    final actualDurationController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer l\'intervention'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: solutionController,
                decoration: const InputDecoration(
                  labelText: 'Solution appliquée *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: completionNotesController,
                decoration: const InputDecoration(
                  labelText: 'Notes de fin (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: actualDurationController,
                decoration: const InputDecoration(
                  labelText: 'Durée réelle (heures)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Coût (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              notifier.completeIntervention(
                intervention,
                solution: solutionController.text.trim(),
                completionNotes: completionNotesController.text.trim().isEmpty
                    ? null
                    : completionNotesController.text.trim(),
                actualDuration: double.tryParse(actualDurationController.text),
                cost: double.tryParse(costController.text),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Intervention terminée'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    Intervention intervention,
    InterventionNotifier notifier,
  ) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir approuver cette intervention ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.approveIntervention(intervention,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Intervention approuvée'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    Intervention intervention,
    InterventionNotifier notifier,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet :'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
                border: OutlineInputBorder(),
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
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez indiquer la raison du rejet'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectIntervention(
                    intervention, reasonController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Intervention rejetée'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
