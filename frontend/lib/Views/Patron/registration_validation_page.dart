import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/company_model.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/company_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';

/// Page patron/admin : liste des inscriptions en attente, attribution du rôle (et société si admin), validation ou rejet.
class RegistrationValidationPage extends ConsumerStatefulWidget {
  const RegistrationValidationPage({super.key});

  @override
  ConsumerState<RegistrationValidationPage> createState() =>
      _RegistrationValidationPageState();
}

class _RegistrationValidationPageState extends ConsumerState<RegistrationValidationPage> {
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  String? _error;
  final Map<int, int> _selectedRole = {}; // userId -> role
  final Map<int, int?> _selectedCompanyId = {}; // userId -> companyId (pour admin uniquement)
  List<Company> _companies = [];
  bool _companiesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _load();
  }

  Future<void> _loadCompanies() async {
    try {
      final list = await CompanyService.getCompanies();
      if (mounted) setState(() {
        _companies = list;
        _companiesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _companiesLoading = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getPendingRegistrations();
      if (res['success'] == true && res['data'] != null) {
        final list = (res['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _pending = list;
          for (final u in list) {
            final id = u['id'] as int?;
            if (id != null) _selectedRole[id] = u['role'] as int? ?? Roles.COMMERCIAL;
          }
          _loading = false;
        });
      } else {
        setState(() {
          _pending = [];
          _loading = false;
          _error = res['message']?.toString() ?? 'Erreur de chargement';
        });
      }
    } catch (e) {
      setState(() {
        _pending = [];
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _approve(int userId) async {
    final role = _selectedRole[userId] ?? Roles.COMMERCIAL;
    final isAdmin = ref.read(authProvider).user?.role == Roles.ADMIN;
    final companyId = isAdmin ? _selectedCompanyId[userId] : null;
    try {
      final res = await ApiService.approveRegistration(userId, role, companyId: companyId);
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription validée'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _load();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ?? 'Validation impossible'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reject(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter l\'inscription'),
        content: const Text(
          'L\'utilisateur en attente sera supprimé. Confirmer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rejeter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await ApiService.rejectRegistration(userId);
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription rejetée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _load();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ?? 'Rejet impossible'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des inscriptions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _pending.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune inscription en attente',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pending.length,
                        itemBuilder: (context, index) {
                          final u = _pending[index];
                          final id = u['id'] as int? ?? 0;
                          final nom = u['nom']?.toString() ?? '';
                          final prenom = u['prenom']?.toString() ?? '';
                          final email = u['email']?.toString() ?? '';
                          final createdAt = u['created_at']?.toString();
                          String dateStr = '';
                          if (createdAt != null && createdAt.isNotEmpty) {
                            try {
                              dateStr = DateFormat('dd/MM/yyyy HH:mm')
                                  .format(DateTime.parse(createdAt));
                            } catch (_) {
                              dateStr = createdAt;
                            }
                          }
                          final role = _selectedRole[id] ?? Roles.COMMERCIAL;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        child: Text(
                                          (prenom.isNotEmpty
                                                  ? prenom[0]
                                                  : nom.isNotEmpty
                                                      ? nom[0]
                                                      : '?')
                                              .toUpperCase(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$prenom $nom',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              email,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (dateStr.isNotEmpty)
                                              Text(
                                                'Inscription : $dateStr',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Attribuer le rôle :',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: role,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: Roles.getRolesList()
                                        .map((r) => DropdownMenuItem<int>(
                                              value: r['id'] as int,
                                              child: Text(r['name'] as String),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _selectedRole[id] = v);
                                      }
                                    },
                                  ),
                                  if (ref.watch(authProvider).user?.role == Roles.ADMIN) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Société (optionnel) :',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _companiesLoading
                                        ? const SizedBox(
                                            height: 48,
                                            child: Center(
                                                child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(strokeWidth: 2))),
                                          )
                                        : DropdownButtonFormField<int>(
                                            value: _selectedCompanyId[id],
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            hint: const Text('Aucune société'),
                                            items: [
                                              const DropdownMenuItem<int>(
                                                value: null,
                                                child: Text('Aucune société'),
                                              ),
                                              ..._companies.map(
                                                (c) => DropdownMenuItem<int>(
                                                  value: c.id,
                                                  child: Text(c.name),
                                                ),
                                              ),
                                            ],
                                            onChanged: (v) {
                                              setState(() => _selectedCompanyId[id] = v);
                                            },
                                          ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _reject(id),
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text('Rejeter'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.icon(
                                        onPressed: () => _approve(id),
                                        icon: const Icon(Icons.check, size: 18),
                                        label: const Text('Valider'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
