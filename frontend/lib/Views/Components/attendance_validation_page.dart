import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../Models/attendance_punch_model.dart';
import '../../services/attendance_punch_service.dart';
import '../../providers/auth_notifier.dart';
import '../../utils/roles.dart';
import '../../Views/Components/skeleton_loaders.dart';
import '../../utils/map_helper.dart';

class AttendanceValidationPage extends ConsumerStatefulWidget {
  const AttendanceValidationPage({super.key});

  @override
  ConsumerState<AttendanceValidationPage> createState() =>
      _AttendanceValidationPageState();
}

class _AttendanceValidationPageState extends ConsumerState<AttendanceValidationPage> {
  final AttendancePunchService _punchService = AttendancePunchService();

  List<AttendancePunchModel> _attendances = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      List<AttendancePunchModel> attendances;

      if (user.role == Roles.PATRON) {
        attendances = await _punchService.getAttendances();
      } else {
        attendances = await _punchService.getAttendances(userId: user.id);
      }

      setState(() {
        _attendances = attendances;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de charger les pointages: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<AttendancePunchModel> get _filteredAttendances {
    List<AttendancePunchModel> filtered = _attendances;

    // Filtrer par type (check_in/check_out)
    switch (_selectedFilter) {
      case 'check_in':
        filtered = filtered.where((a) => a.isCheckIn).toList();
        break;
      case 'check_out':
        filtered = filtered.where((a) => a.isCheckOut).toList();
        break;
      default:
        // Tous les types
        break;
    }

    // Trier par date (plus récent en premier)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des pointages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/attendance-punch'),
            tooltip: 'Nouveau pointage',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendances,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filtre par type
                Row(
                  children: [
                    const Text('Type: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tous')),
                          DropdownMenuItem(
                            value: 'check_in',
                            child: Text('Arrivées'),
                          ),
                          DropdownMenuItem(
                            value: 'check_out',
                            child: Text('Départs'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des pointages
          Expanded(
            child:
                _isLoading
                    ? const SkeletonSearchResults(itemCount: 6)
                    : _filteredAttendances.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun pointage trouvé',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_attendances.length} pointage(s) au total',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredAttendances.length,
                      itemBuilder: (context, index) {
                        final attendance = _filteredAttendances[index];
                        return _buildAttendanceCard(attendance);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(AttendancePunchModel attendance) {
    final userName = attendance.userName ?? '';
    if (userName.toLowerCase().contains('comptable')) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        final displayName = '${user.prenom ?? ''} ${user.nom ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          return displayName;
        }
      }
    }
    return userName.isNotEmpty ? userName : 'Utilisateur inconnu';
  }

  Widget _buildAttendanceCard(AttendancePunchModel attendance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(attendance),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(attendance.formattedTimestamp),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(attendance.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    attendance.typeLabel,
                    style: TextStyle(
                      color: _getTypeColor(attendance.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Localisation
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attendance.address ?? 'Adresse inconnue',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                if (attendance.latitude != 0.0 && attendance.longitude != 0.0)
                  IconButton(
                    icon: const Icon(Icons.map, size: 20),
                    color: Colors.blue,
                    onPressed: () => _openGoogleMaps(attendance),
                    tooltip: 'Ouvrir dans Google Maps',
                  ),
              ],
            ),

            if (attendance.notes != null && attendance.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attendance.notes!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],

            // Photo
            if (attendance.photoPath != null &&
                attendance.photoPath!.isNotEmpty &&
                attendance.photoUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: attendance.photoUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
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
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            child: Text(
                              attendance.photoUrl,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'check_in':
        return Colors.blue;
      case 'check_out':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openGoogleMaps(AttendancePunchModel attendance) async {
    try {
      await MapHelper.openGoogleMaps(
        latitude: attendance.latitude,
        longitude: attendance.longitude,
        label: attendance.address,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir Google Maps: $e')),
        );
      }
    }
  }
}
