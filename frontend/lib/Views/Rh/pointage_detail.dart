import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easyconnect/Models/attendance_punch_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/utils/map_helper.dart';

class PointageDetail extends StatelessWidget {
  final AttendancePunchModel pointage;

  const PointageDetail({super.key, required this.pointage});

  @override
  Widget build(BuildContext context) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final formatTime = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/attendance-punch', iconColor: Colors.white),
        title: Text('Pointage - ${pointage.typeLabel}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePointage(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(formatDate, formatTime),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoCard('Informations de base', [
              _buildInfoRow(
                Icons.person,
                'Employé',
                pointage.userName ?? 'Non spécifié',
              ),
              _buildInfoRow(Icons.access_time, 'Type', pointage.typeLabel),
              _buildInfoRow(
                Icons.calendar_today,
                'Date',
                formatDate.format(pointage.timestamp),
              ),
              _buildInfoRow(
                Icons.schedule,
                'Heure',
                formatTime.format(pointage.timestamp),
              ),
              _buildInfoRow(Icons.info, 'Statut', pointage.statusLabel),
            ]),

            // Localisation
            const SizedBox(height: 16),
            _buildInfoCard('Localisation', [
              _buildInfoRow(
                Icons.location_on,
                'Adresse',
                pointage.address ?? 'Non spécifiée',
              ),
              _buildInfoRow(
                Icons.map,
                'Coordonnées GPS',
                '${pointage.latitude.toStringAsFixed(6)}, ${pointage.longitude.toStringAsFixed(6)}',
              ),
              if (pointage.accuracy != null)
                _buildInfoRow(
                  Icons.gps_fixed,
                  'Précision',
                  '${pointage.accuracy!.toStringAsFixed(2)} mètres',
                ),
              if (pointage.latitude != 0.0 && pointage.longitude != 0.0) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openGoogleMaps(context),
                    icon: const Icon(Icons.map),
                    label: const Text('Ouvrir dans Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ]),

            // Photo si disponible
            if (pointage.photoPath != null &&
                pointage.photoPath!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Photo', [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: pointage.photoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      ),
                    ),
                  ),
                ),
              ]),
            ],

            // Notes si disponibles
            if (pointage.notes != null && pointage.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes', [
                _buildInfoRow(Icons.note, 'Notes', pointage.notes!),
              ]),
            ],

            // Validation
            if (pointage.approvedBy != null || pointage.approvedAt != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Validation', [
                if (pointage.approverName != null)
                  _buildInfoRow(
                    Icons.verified_user,
                    'Validé par',
                    pointage.approverName!,
                  ),
                if (pointage.approvedAt != null)
                  _buildInfoRow(
                    Icons.check_circle,
                    'Date de validation',
                    '${formatDate.format(pointage.approvedAt!)} à ${formatTime.format(pointage.approvedAt!)}',
                  ),
              ]),
            ],

            // Raison du rejet si rejeté
            if (pointage.status == 'rejected' &&
                pointage.rejectionReason != null &&
                pointage.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRejectionCard(),
            ],

            // Historique
            const SizedBox(height: 16),
            _buildHistoryCard(formatDate, formatTime),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(DateFormat formatDate, DateFormat formatTime) {
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
                    pointage.typeLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    '${formatDate.format(pointage.timestamp)} à ${formatTime.format(pointage.timestamp)}',
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
            pointage.statusLabel,
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

  Widget _buildRejectionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  'Motif du rejet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                pointage.rejectionReason!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DateFormat formatDate, DateFormat formatTime) {
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
              '${formatDate.format(pointage.createdAt)} à ${formatTime.format(pointage.createdAt)}',
              Colors.blue,
            ),
            if (pointage.approvedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Approuvé',
                '${formatDate.format(pointage.approvedAt!)} à ${formatTime.format(pointage.approvedAt!)}',
                Colors.green,
              ),
            if (pointage.status == 'rejected')
              _buildHistoryItem(
                Icons.cancel,
                'Rejeté',
                '${formatDate.format(pointage.updatedAt)} à ${formatTime.format(pointage.updatedAt)}',
                Colors.red,
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

  Color _getStatusColor() {
    switch (pointage.status.toLowerCase()) {
      case 'approved':
      case 'valide':
        return Colors.green;
      case 'rejected':
      case 'rejete':
        return Colors.red;
      case 'pending':
      case 'en_attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (pointage.status.toLowerCase()) {
      case 'approved':
      case 'valide':
        return Icons.check_circle;
      case 'rejected':
      case 'rejete':
        return Icons.cancel;
      case 'pending':
      case 'en_attente':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  void _sharePointage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    try {
      await MapHelper.openGoogleMaps(
        latitude: pointage.latitude,
        longitude: pointage.longitude,
        label: pointage.address,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir Google Maps: $e')),
        );
      }
    }
  }
}
