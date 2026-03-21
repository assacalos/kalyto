import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/providers/reporting_notifier.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:intl/intl.dart';

class ReportingDetail extends ConsumerStatefulWidget {
  final ReportingModel reporting;

  const ReportingDetail({super.key, required this.reporting});

  @override
  ConsumerState<ReportingDetail> createState() => _ReportingDetailState();
}

class _ReportingDetailState extends ConsumerState<ReportingDetail> {
  late final TextEditingController _patronNoteController;

  @override
  void initState() {
    super.initState();
    _patronNoteController = TextEditingController(
      text: widget.reporting.patronNote ?? '',
    );
  }

  @override
  void dispose() {
    _patronNoteController.dispose();
    super.dispose();
  }

  ReportingModel get reporting => widget.reporting;

  @override
  Widget build(BuildContext context) {
    final formatDate = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/reporting', iconColor: Colors.white),
        title: Text('Rapport - ${formatDate.format(reporting.reportDate)}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Modifier : autorisé pour soumis (backend n'autorise que submitted)
          if (reporting.status == 'submitted')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/reporting/new', extra: reporting),
              tooltip: 'Modifier',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReporting(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(formatDate),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoCard('Informations générales', [
              _buildInfoRow(Icons.person, 'Employé', reporting.userName),
              _buildInfoRow(Icons.badge, 'Rôle', reporting.userRole),
              _buildInfoRow(
                Icons.calendar_today,
                'Date du rapport',
                formatDate.format(reporting.reportDate),
              ),
              _buildInfoRow(Icons.info, 'Statut', _getStatusText()),
            ]),

            // Détail du rapport (nouvelles informations)
            if (_hasNewInfo()) ...[
              const SizedBox(height: 16),
              _buildNewInfoCard(formatDate),
            ],

            // Relance (type + date/heure de rappel)
            if (reporting.typeRelance != null &&
                reporting.typeRelance!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Relance', [
                _buildInfoRow(
                  Icons.notifications_active,
                  'Type',
                  reporting.typeRelanceLibelle,
                ),
                if (reporting.relanceDateHeure != null)
                  _buildInfoRow(
                    Icons.schedule,
                    'Date et heure de rappel',
                    DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR')
                        .format(reporting.relanceDateHeure!),
                  ),
              ]),
            ],

            // Commentaire
            if (reporting.commentaire != null &&
                reporting.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Commentaire', [
                _buildInfoRow(
                  Icons.comment,
                  'Commentaire',
                  reporting.commentaire!,
                ),
              ]),
            ],

            // Note du patron (affichée si déjà renseignée)
            if (reporting.patronNote != null &&
                reporting.patronNote!.isNotEmpty &&
                !_isPatron()) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Note du patron', [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    reporting.patronNote!,
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              ]),
            ],

            // Note du patron (champ éditable pour le patron avant validation)
            if (_isPatron() && reporting.status == 'submitted') ...[
              const SizedBox(height: 16),
              _buildPatronNoteCard(),
            ],

            // Historique
            const SizedBox(height: 16),
            _buildHistoryCard(formatDate),

            // Boutons d'action pour le patron (si le rapport est soumis)
            if (_isPatron() && reporting.status == 'submitted') ...[
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatronNoteCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Votre note (optionnel)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez un commentaire avant de valider ce rapport.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _patronNoteController,
              decoration: const InputDecoration(
                hintText: 'Saisir votre note...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              minLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  bool _isPatron() {
    final userRole = SessionService.getUserRole();
    return userRole == Roles.PATRON;
  }

  Widget _buildActionButtons() {
    final notifier = ref.read(reportingProvider.notifier);
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveConfirmation(notifier),
                    icon: const Icon(Icons.check),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(notifier),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  void _showApproveConfirmation(ReportingNotifier notifier) {
    final note = _patronNoteController.text.trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(
          'Voulez-vous valider ce rapport ?${note.isNotEmpty ? '\n\nVotre note sera enregistrée.' : ''}',
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
                await notifier.approveReport(
                  reporting.id,
                  patronNote: note.isEmpty ? null : note,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rapport approuvé avec succès')),
                );
                context.pop();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(ReportingNotifier notifier) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le rapport'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            labelText: 'Motif du rejet',
            hintText: 'Entrez le motif du rejet',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un motif de rejet')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectReport(
                  reporting.id,
                  reason: commentController.text,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rapport rejeté avec succès')),
                );
                context.pop();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(DateFormat formatDate) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _getStatusColor().withOpacity(0.1),
              child: Icon(_getStatusIcon(), size: 30, color: _getStatusColor()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rapport du ${formatDate.format(reporting.reportDate)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    'Par ${reporting.userName}',
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
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor().withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
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

  bool _hasNewInfo() {
    return (reporting.nature != null && reporting.nature!.isNotEmpty) ||
        (reporting.nomSociete != null && reporting.nomSociete!.isNotEmpty) ||
        (reporting.contactSociete != null && reporting.contactSociete!.isNotEmpty) ||
        (reporting.nomPersonne != null && reporting.nomPersonne!.isNotEmpty) ||
        (reporting.contactPersonne != null && reporting.contactPersonne!.isNotEmpty) ||
        (reporting.moyenContact != null && reporting.moyenContact!.isNotEmpty) ||
        (reporting.produitDemarche != null && reporting.produitDemarche!.isNotEmpty);
  }

  Widget _buildNewInfoCard(DateFormat formatDate) {
    final children = <Widget>[];
    if (reporting.nature != null && reporting.nature!.isNotEmpty) {
      children.add(_buildInfoRow(Icons.category, 'Nature', reporting.natureLibelle));
    }
    if (reporting.nomSociete != null && reporting.nomSociete!.isNotEmpty) {
      children.add(_buildInfoRow(Icons.business, 'Nom société', reporting.nomSociete!));
    }
    if (reporting.contactSociete != null && reporting.contactSociete!.isNotEmpty) {
      children.add(_buildInfoRow(Icons.contact_phone, 'Contact société', reporting.contactSociete!));
    }
    if (reporting.nomPersonne != null && reporting.nomPersonne!.isNotEmpty) {
      children.add(_buildInfoRow(Icons.person, 'Nom personne', reporting.nomPersonne!));
    }
    if (reporting.contactPersonne != null && reporting.contactPersonne!.isNotEmpty) {
      children.add(_buildInfoRow(Icons.contact_mail, 'Contact personne', reporting.contactPersonne!));
    }
    if (reporting.moyenContact != null && reporting.moyenContact!.isNotEmpty) {
      children.add(_buildInfoRow(Icons.link, 'Moyen de contact', reporting.moyenContactLibelle));
    }
    if (reporting.produitDemarche != null && reporting.produitDemarche!.isNotEmpty) {
      children.add(_buildInfoRow(Icons.description, 'Produit / démarche', reporting.produitDemarche!));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return _buildInfoCard('Détail du rapport', children);
  }

  Widget _buildHistoryCard(DateFormat formatDate) {
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
              formatDate.format(reporting.createdAt),
              Colors.blue,
            ),
            if (reporting.submittedAt != null)
              _buildHistoryItem(
                Icons.send,
                'Soumis',
                formatDate.format(reporting.submittedAt!),
                Colors.orange,
              ),
            if (reporting.approvedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Approuvé',
                formatDate.format(reporting.approvedAt!),
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

  String _getStatusText() {
    switch (reporting.status.toLowerCase()) {
      case 'submitted':
        return 'Soumis';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return reporting.status;
    }
  }

  Color _getStatusColor() {
    switch (reporting.status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'submitted':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (reporting.status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'submitted':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  void _shareReporting() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
    );
  }
}
