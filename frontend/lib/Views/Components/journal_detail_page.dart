import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Models/journal_entry_model.dart';
import 'package:easyconnect/services/api_service.dart';

class JournalDetailPage extends StatefulWidget {
  final int entryId;

  const JournalDetailPage({super.key, required this.entryId});

  @override
  State<JournalDetailPage> createState() => _JournalDetailPageState();
}

class _JournalDetailPageState extends State<JournalDetailPage> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getJournalShow(widget.entryId);
      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _data = Map<String, dynamic>.from(res['data'] as Map);
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message']?.toString() ?? 'Écriture non trouvée';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static String _formatNumber(num value) {
    return NumberFormat('#,##0', 'fr_FR').format(value);
  }

  String _userDisplay(Map<String, dynamic>? user) {
    if (user == null) return '—';
    final prenom = (user['prenom']?.toString() ?? '').trim();
    final nom = (user['nom']?.toString() ?? '').trim();
    if (prenom.isNotEmpty && nom.isNotEmpty) return '$prenom $nom';
    if (nom.isNotEmpty) return nom;
    if (prenom.isNotEmpty) return prenom;
    return user['email']?.toString() ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détail de l\'écriture'),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _data == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détail de l\'écriture'),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Écriture non trouvée',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = _data!;
    final date = d['date']?.toString() ?? '—';
    final reference = d['reference']?.toString();
    final libelle = d['libelle']?.toString() ?? '—';
    final categorie = d['categorie']?.toString();
    final modePaiement = d['mode_paiement']?.toString() ?? 'especes';
    final modePaiementLibelle = d['mode_paiement_libelle']?.toString() ?? JournalEntryModel.modePaiementLabel(modePaiement);
    final entree = (d['entree'] is num) ? (d['entree'] as num).toDouble() : 0.0;
    final sortie = (d['sortie'] is num) ? (d['sortie'] as num).toDouble() : 0.0;
    final notes = d['notes']?.toString();
    final createdAt = d['created_at']?.toString();
    final updatedAt = d['updated_at']?.toString();
    final user = d['user'] is Map ? Map<String, dynamic>.from(d['user'] as Map) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'écriture'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () async {
              final ok = await context.push<bool>(
                '/journal/form',
                extra: widget.entryId,
              );
              if (ok == true && mounted) _loadEntry();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libelle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (reference != null && reference.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildRow(Icons.tag, 'Référence', reference),
                    ],
                    const SizedBox(height: 12),
                    _buildRow(Icons.calendar_today, 'Date', date),
                    if (categorie != null && categorie.isNotEmpty)
                      _buildRow(Icons.category, 'Catégorie', categorie),
                    _buildRow(Icons.payment, 'Mode de paiement', modePaiementLibelle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Montants', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (entree > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Entrée', style: TextStyle(color: Colors.green.shade700)),
                          Text(
                            '+${_formatNumber(entree)} FCFA',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700, fontSize: 16),
                          ),
                        ],
                      ),
                    if (sortie > 0) ...[
                      if (entree > 0) const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sortie', style: TextStyle(color: Colors.red.shade700)),
                          Text(
                            '-${_formatNumber(sortie)} FCFA',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow(Icons.person, 'Enregistré par', _userDisplay(user)),
                    if (createdAt != null && createdAt.isNotEmpty)
                      _buildRow(Icons.access_time, 'Créé le', _formatDateTime(createdAt)),
                    if (updatedAt != null && updatedAt.isNotEmpty && updatedAt != createdAt)
                      _buildRow(Icons.update, 'Modifié le', _formatDateTime(updatedAt)),
                  ],
                ),
              ),
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text('Notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(notes, style: TextStyle(color: Colors.grey.shade800)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String iso) {
    try {
      final dt = DateTime.tryParse(iso);
      if (dt != null) return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(dt);
    } catch (_) {}
    return iso;
  }
}
