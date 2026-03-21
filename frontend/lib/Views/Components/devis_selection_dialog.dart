import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class DevisSelectionDialog extends StatefulWidget {
  final List<Devis> devis;
  final Future<void> Function(Devis) onDevisSelected;
  final bool isLoading;

  const DevisSelectionDialog({
    super.key,
    required this.devis,
    required this.onDevisSelected,
    this.isLoading = false,
  });

  @override
  State<DevisSelectionDialog> createState() => _DevisSelectionDialogState();
}

class _DevisSelectionDialogState extends State<DevisSelectionDialog> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Devis> _filteredDevis = [];

  @override
  void initState() {
    super.initState();
    _filteredDevis = widget.devis;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        setState(() {
          _filteredDevis = widget.devis;
        });
      } else {
        final filtered =
            widget.devis.where((devis) {
              final searchLower = query.toLowerCase();
              final referenceLower = devis.reference.toLowerCase();
              return referenceLower.contains(searchLower);
            }).toList();
        setState(() {
          _filteredDevis = filtered;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Sélectionner un devis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Text(
                    'Validés uniquement',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher par référence',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  widget.isLoading
                      ? const SkeletonSearchResults(itemCount: 4)
                      : _filteredDevis.isEmpty
                      ? const Center(child: Text('Aucun devis trouvé'))
                      : ListView.builder(
                        itemCount: _filteredDevis.length,
                        itemBuilder: (context, index) {
                          final devis = _filteredDevis[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.description,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                'Devis ${devis.reference}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date: ${devis.dateCreation.day}/${devis.dateCreation.month}/${devis.dateCreation.year}',
                                  ),
                                  Text('Articles: ${devis.items.length}'),
                                  Text(
                                    'Total HT: ${devis.totalHT.toStringAsFixed(2)} FCFA',
                                  ),
                                  Text('Statut: ${devis.statusText}'),
                                ],
                              ),
                              onTap: () async {
                                await widget.onDevisSelected(devis);
                                if (context.mounted) Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
