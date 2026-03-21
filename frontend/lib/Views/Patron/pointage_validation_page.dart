import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/attendance_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/attendance_punch_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/utils/map_helper.dart';

class PointageValidationPage extends ConsumerStatefulWidget {
  const PointageValidationPage({super.key});

  @override
  ConsumerState<PointageValidationPage> createState() =>
      _PointageValidationPageState();
}

class _PointageValidationPageState extends ConsumerState<PointageValidationPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceProvider.notifier).loadAttendanceData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    try {
      await ref.read(attendanceProvider.notifier).loadAttendanceData();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Pointages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom d\'utilisateur...',
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
                : _buildAttendanceList(state.attendanceHistory, user),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(
    List<AttendancePunchModel> pointages,
    dynamic user,
  ) {
    List<AttendancePunchModel> filteredPointages = pointages;
    if (_searchQuery.isNotEmpty) {
      filteredPointages = pointages
          .where(
            (p) =>
                _getDisplayName(p, user)
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    if (filteredPointages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun pointage trouvé'
                  : 'Aucun pointage correspondant à "$_searchQuery"',
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
      itemCount: filteredPointages.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final pointage = filteredPointages[index];
        return _buildPointageCard(context, pointage, user);
      },
    );
  }

  String _getDisplayName(AttendancePunchModel pointage, dynamic user) {
    final userName = pointage.userName ?? '';
    if (userName.toLowerCase().contains('comptable') && user != null) {
      final displayName = '${user.prenom ?? ''} ${user.nom ?? ''}'.trim();
      if (displayName.isNotEmpty) return displayName;
    }
    return userName.isNotEmpty ? userName : 'Utilisateur inconnu';
  }

  Widget _buildPointageCard(
    BuildContext context,
    AttendancePunchModel pointage,
    dynamic user,
  ) {
    final formatDateTime = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () => context.push('/pointage/detail', extra: pointage),
        borderRadius: BorderRadius.circular(8),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(
              pointage.type == 'check_in' ? Icons.login : Icons.logout,
              color: Colors.blue,
            ),
          ),
          title: Text(
            _getDisplayName(pointage, user),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Type: ${pointage.typeLabel}'),
              Text('Date: ${formatDateTime.format(pointage.timestamp)}'),
              Text('Lieu: ${pointage.address ?? 'Non spécifié'}'),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations employé',
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
                        Text('Employé: ${_getDisplayName(pointage, user)}'),
                        Text('ID Employé: ${pointage.userId}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Détails du pointage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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
                            const Text('Type:'),
                            Text(pointage.type),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Heure:'),
                            Text(formatDateTime.format(pointage.timestamp)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Lieu:'),
                            Expanded(
                              child: Text(
                                pointage.address ?? 'Inconnu',
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        if (pointage.latitude != 0.0 &&
                            pointage.longitude != 0.0) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openGoogleMaps(pointage),
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text('Ouvrir dans Google Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (pointage.notes != null &&
                            pointage.notes!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                'Notes:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(pointage.notes!),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (pointage.photoPath != null &&
                      pointage.photoPath!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Photo du pointage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: pointage.photoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Impossible de charger la photo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Future<void> _openGoogleMaps(AttendancePunchModel pointage) async {
    try {
      await MapHelper.openGoogleMaps(
        latitude: pointage.latitude,
        longitude: pointage.longitude,
        label: pointage.address,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir Google Maps: $e'),
        ),
      );
    }
  }
}
