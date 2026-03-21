import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/employee_notifier.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:intl/intl.dart';

class EmployeeDetail extends ConsumerWidget {
  final Employee employee;

  const EmployeeDetail({super.key, required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(employeeProvider.notifier);
    const canManage = true;
    const canApprove = true;
    final formatDate = DateFormat('dd/MM/yyyy à HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(employee.fullName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.go('/employees/${employee.id}/edit', extra: employee),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareEmployee(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec photo et statut
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Informations personnelles
            _buildInfoCard('Informations personnelles', [
              _buildInfoRow(Icons.person, 'Nom complet', employee.fullName),
              _buildInfoRow(Icons.email, 'Email', employee.email),
              if (employee.phone != null)
                _buildInfoRow(Icons.phone, 'Téléphone', employee.phone!),
              if (employee.address != null)
                _buildInfoRow(Icons.location_on, 'Adresse', employee.address!),
              if (employee.birthDate != null)
                _buildInfoRow(
                  Icons.cake,
                  'Date de naissance',
                  formatDate.format(employee.birthDate!),
                ),
              if (employee.age != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Âge',
                  '${employee.age} ans',
                ),
              if (employee.gender != null)
                _buildInfoRow(
                  Icons.person_outline,
                  'Genre',
                  _getGenderText(employee.gender!),
                ),
              if (employee.maritalStatus != null)
                _buildInfoRow(
                  Icons.favorite,
                  'Statut matrimonial',
                  _getMaritalStatusText(employee.maritalStatus!),
                ),
              if (employee.nationality != null)
                _buildInfoRow(
                  Icons.flag,
                  'Nationalité',
                  _getNationalityText(employee.nationality!),
                ),
            ]),

            // Informations professionnelles
            const SizedBox(height: 16),
            _buildInfoCard('Informations professionnelles', [
              if (employee.position != null)
                _buildInfoRow(Icons.work, 'Poste', employee.position!),
              if (employee.department != null)
                _buildInfoRow(
                  Icons.business,
                  'Département',
                  employee.department!,
                ),
              if (employee.manager != null)
                _buildInfoRow(
                  Icons.supervisor_account,
                  'Manager',
                  employee.manager!,
                ),
              if (employee.hireDate != null)
                _buildInfoRow(
                  Icons.event,
                  'Date d\'embauche',
                  formatDate.format(employee.hireDate!),
                ),
              if (employee.contractType != null)
                _buildInfoRow(
                  Icons.description,
                  'Type de contrat',
                  _getContractTypeText(employee.contractType!),
                ),
              if (employee.contractStartDate != null)
                _buildInfoRow(
                  Icons.play_arrow,
                  'Début du contrat',
                  formatDate.format(employee.contractStartDate!),
                ),
              if (employee.contractEndDate != null)
                _buildInfoRow(
                  Icons.stop,
                  'Fin du contrat',
                  formatDate.format(employee.contractEndDate!),
                  isWarning: employee.isContractExpiring,
                  isError: employee.isContractExpired,
                ),
              if (employee.workSchedule != null)
                _buildInfoRow(
                  Icons.schedule,
                  'Horaires',
                  _getWorkScheduleText(employee.workSchedule!),
                ),
            ]),

            // Informations financières
            const SizedBox(height: 16),
            _buildInfoCard('Informations financières', [
              _buildInfoRow(
                Icons.euro,
                'Salaire',
                employee.formattedSalary,
                isHighlight: true,
              ),
              _buildInfoRow(
                Icons.info,
                'Statut',
                employee.statusText,
                isWarning: employee.status == 'inactive',
                isError: employee.status == 'terminated',
              ),
            ]),

            // Documents
            if (employee.documents != null &&
                employee.documents!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDocumentsCard(),
            ],

            // Congés
            if (employee.leaves != null && employee.leaves!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLeavesCard(),
            ],

            // Performances
            if (employee.performances != null &&
                employee.performances!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPerformancesCard(),
            ],

            // Notes
            if (employee.notes != null && employee.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes', [
                _buildInfoRow(Icons.note, 'Notes', employee.notes!),
              ]),
            ],

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(context, notifier, canManage, canApprove),
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
              radius: 40,
              backgroundColor: _getStatusColor(
                employee.statusColor,
              ).withOpacity(0.1),
              child: Text(
                employee.initials,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(employee.statusColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    employee.email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (employee.position != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      employee.position!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
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
        color: _getStatusColor(employee.statusColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(employee.statusColor).withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(employee.statusIcon),
            size: 16,
            color: _getStatusColor(employee.statusColor),
          ),
          const SizedBox(width: 4),
          Text(
            employee.statusText,
            style: TextStyle(
              color: _getStatusColor(employee.statusColor),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool? isWarning,
    bool? isError,
    bool? isHighlight,
  }) {
    Color? textColor;
    if (isError == true) {
      textColor = Colors.red;
    } else if (isWarning == true) {
      textColor = Colors.orange;
    } else if (isHighlight == true) {
      textColor = Colors.green;
    }

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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isHighlight == true ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...employee.documents!
                .take(5)
                .map((doc) => _buildDocumentItem(doc)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(EmployeeDocument document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _getDocumentIcon(document.type),
            color: _getDocumentColor(document.type),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  document.typeText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (document.expiryDate != null)
                  Text(
                    'Expire le ${DateFormat('dd/MM/yyyy').format(document.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          document.isExpired
                              ? Colors.red
                              : document.isExpiring
                              ? Colors.orange
                              : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          if (document.isExpired || document.isExpiring)
            Icon(
              document.isExpired ? Icons.error : Icons.warning,
              color: document.isExpired ? Colors.red : Colors.orange,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildLeavesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Congés récents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...employee.leaves!.take(3).map((leave) => _buildLeaveItem(leave)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveItem(EmployeeLeave leave) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _getLeaveIcon(leave.type),
            color: _getLeaveColor(leave.type),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.typeText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(leave.startDate)} - ${DateFormat('dd/MM/yyyy').format(leave.endDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (leave.reason != null)
                  Text(
                    leave.reason!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getLeaveStatusColor(leave.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              leave.statusText,
              style: TextStyle(
                color: _getLeaveStatusColor(leave.status),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performances récentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...employee.performances!
                .take(3)
                .map((perf) => _buildPerformanceItem(perf)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(EmployeePerformance performance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: _getPerformanceColor(performance.rating),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performance.period,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Note: ${performance.rating.toStringAsFixed(1)}/5',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (performance.comments != null)
                  Text(
                    performance.comments!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPerformanceStatusColor(
                performance.status,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              performance.statusText,
              style: TextStyle(
                color: _getPerformanceStatusColor(performance.status),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, EmployeeNotifier notifier, bool canManage, bool canApprove) {
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
                if (canManage) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      onPressed: () => context.go(
                          '/employees/${employee.id}/edit', extra: employee),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Soumettre'),
                      onPressed: () => _showSubmitDialog(context, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (canApprove) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(context, notifier),
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
                      onPressed: () => _showRejectDialog(context, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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

  // Méthodes utilitaires
  Color _getStatusColor(String statusColor) {
    switch (statusColor) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String statusIcon) {
    switch (statusIcon) {
      case 'check_circle':
        return Icons.check_circle;
      case 'pause_circle':
        return Icons.pause_circle;
      case 'cancel':
        return Icons.cancel;
      case 'event':
        return Icons.event;
      default:
        return Icons.help;
    }
  }

  String _getGenderText(String gender) {
    switch (gender) {
      case 'male':
        return 'Homme';
      case 'female':
        return 'Femme';
      case 'other':
        return 'Autre';
      default:
        return gender;
    }
  }

  String _getMaritalStatusText(String status) {
    switch (status) {
      case 'single':
        return 'Célibataire';
      case 'married':
        return 'Marié(e)';
      case 'divorced':
        return 'Divorcé(e)';
      case 'widowed':
        return 'Veuf/Veuve';
      default:
        return status;
    }
  }

  String _getNationalityText(String nationality) {
    switch (nationality) {
      case 'cameroon':
        return 'Camerounais(e)';
      case 'french':
        return 'Français(e)';
      case 'nigerian':
        return 'Nigérian(e)';
      case 'other':
        return 'Autre';
      default:
        return nationality;
    }
  }

  String _getContractTypeText(String type) {
    switch (type) {
      case 'permanent':
        return 'CDI';
      case 'temporary':
        return 'CDD';
      case 'internship':
        return 'Stage';
      case 'consultant':
        return 'Consultant';
      default:
        return type;
    }
  }

  String _getWorkScheduleText(String schedule) {
    switch (schedule) {
      case 'full_time':
        return 'Temps plein';
      case 'part_time':
        return 'Temps partiel';
      case 'flexible':
        return 'Flexible';
      case 'shift':
        return 'Par équipes';
      default:
        return schedule;
    }
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'contract':
        return Icons.description;
      case 'id_card':
        return Icons.credit_card;
      case 'passport':
        return Icons.card_travel;
      case 'diploma':
        return Icons.school;
      case 'certificate':
        return Icons.verified;
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.attach_file;
    }
  }

  Color _getDocumentColor(String type) {
    switch (type) {
      case 'contract':
        return Colors.blue;
      case 'id_card':
        return Colors.green;
      case 'passport':
        return Colors.purple;
      case 'diploma':
        return Colors.orange;
      case 'certificate':
        return Colors.teal;
      case 'medical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getLeaveIcon(String type) {
    switch (type) {
      case 'annual':
        return Icons.beach_access;
      case 'sick':
        return Icons.medical_services;
      case 'maternity':
        return Icons.child_care;
      case 'paternity':
        return Icons.family_restroom;
      case 'personal':
        return Icons.person;
      case 'unpaid':
        return Icons.money_off;
      default:
        return Icons.event;
    }
  }

  Color _getLeaveColor(String type) {
    switch (type) {
      case 'annual':
        return Colors.blue;
      case 'sick':
        return Colors.red;
      case 'maternity':
        return Colors.pink;
      case 'paternity':
        return Colors.cyan;
      case 'personal':
        return Colors.orange;
      case 'unpaid':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getLeaveStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPerformanceColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  Color _getPerformanceStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _shareEmployee(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à implémenter'),
      ),
    );
  }

  void _showSubmitDialog(BuildContext context, EmployeeNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Soumettre pour approbation'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Êtes-vous sûr de vouloir soumettre cet employé pour approbation par le Patron ?',
              style: TextStyle(color: Colors.grey),
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
                await notifier.submitEmployeeForApproval(employee);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Employé soumis pour approbation'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, EmployeeNotifier notifier) {
    final commentsController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver l\'employé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir approuver cet employé ?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Commentaires (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Ajoutez des commentaires...',
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
                await notifier.approveEmployee(
                  employee,
                  comments: commentsController.text.trim().isEmpty
                      ? null
                      : commentsController.text.trim(),
                );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Employé approuvé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text('Erreur: $e'), backgroundColor: Colors.red),
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

  void _showRejectDialog(BuildContext context, EmployeeNotifier notifier) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter l\'employé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir rejeter cet employé ?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet *',
                border: OutlineInputBorder(),
                hintText: 'Expliquez la raison du rejet...',
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
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Le motif du rejet est obligatoire'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectEmployee(
                  employee,
                  reason: reasonController.text.trim(),
                );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Employé rejeté'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text('Erreur: $e'), backgroundColor: Colors.red),
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
