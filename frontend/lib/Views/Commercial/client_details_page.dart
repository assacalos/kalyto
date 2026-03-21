import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/client_notifier.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class ClientDetailsPage extends ConsumerWidget {
  final int clientId;

  const ClientDetailsPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientState = ref.watch(clientProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/clients'),
        title: const Text('Détails du client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/clients/$clientId/edit'),
          ),
        ],
      ),
      body: clientState.isLoading
          ? const SkeletonPage(listItemCount: 6)
          : _buildBody(context, clientState.clients),
    );
  }

  Widget _buildBody(BuildContext context, List<Client> clients) {
    Client? client;
    final list = clients.where((c) => c.id == clientId).toList();
    if (list.isNotEmpty) client = list.first;
    if (client == null || client.id == null) {
      return const Center(child: Text('Client non trouvé'));
    }
    return SingleChildScrollView(
          child: Column(
            children: [
              // En-tête avec informations principales
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        (client.nomEntreprise?.isNotEmpty == true
                                ? client.nomEntreprise!.substring(0, 1)
                                : client.nom?.substring(0, 1) ?? '?')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      client.nomEntreprise?.isNotEmpty == true
                          ? client.nomEntreprise!
                          : '${client.prenom ?? ''} ${client.nom ?? ''}'
                              .trim()
                              .isNotEmpty
                          ? '${client.prenom ?? ''} ${client.nom ?? ''}'.trim()
                          : 'Client #${client.id}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (client.nomEntreprise?.isNotEmpty == true &&
                        '${client.prenom ?? ''} ${client.nom ?? ''}'
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${client.prenom ?? ''} ${client.nom ?? ''}'.trim(),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: client.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: client.statusColor.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            client.statusIcon,
                            size: 20,
                            color: client.statusColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            client.statusText,
                            style: TextStyle(
                              color: client.statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Informations détaillées
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Informations de contact', [
                      _buildInfoRow(Icons.email, 'Email', client.email ?? ''),
                      _buildInfoRow(
                        Icons.phone,
                        'Contact',
                        client.contact ?? '',
                      ),
                      _buildInfoRow(
                        Icons.location_on,
                        'Adresse',
                        client.adresse ?? '',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Informations entreprise', [
                      _buildInfoRow(
                        Icons.business,
                        'Nom entreprise',
                        client.nomEntreprise ?? '',
                      ),
                      _buildInfoRow(
                        Icons.place,
                        'Situation géographique',
                        client.situationGeographique ?? '',
                      ),
                      if (client.numeroContribuable != null &&
                          client.numeroContribuable!.isNotEmpty)
                        _buildInfoRow(
                          Icons.badge,
                          'Numéro contribuable',
                          client.numeroContribuable ?? '',
                        ),
                      if (client.ninea != null && client.ninea!.isNotEmpty)
                        _buildInfoRow(
                          Icons.fingerprint,
                          'NINEA',
                          client.ninea!,
                        ),
                    ]),
                    if (client.status == 2 && client.commentaire != null) ...[
                      const SizedBox(height: 24),
                      _buildSection('Motif du rejet', [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            client.commentaire ?? '',
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 24),
                    _buildSection('Entités associées', [
                      _buildEntityButtons(context, client.id!),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildEntityButtons(BuildContext context, int clientId) {
    return Column(
      children: [
        // Première ligne : Devis et Bordereaux
        Row(
          children: [
            Expanded(
              child: _buildEntityButton(
                icon: Icons.description,
                label: 'Devis',
                color: Colors.blue,
                onTap: () {
                  context.go('/devis-page?clientId=$clientId');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEntityButton(
                icon: Icons.assignment,
                label: 'Bordereaux',
                color: Colors.purple,
                onTap: () {
                  context.go('/bordereaux?clientId=$clientId');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Deuxième ligne : Factures et Paiements
        Row(
          children: [
            Expanded(
              child: _buildEntityButton(
                icon: Icons.receipt_long,
                label: 'Factures',
                color: Colors.green,
                onTap: () {
                  context.go('/invoices?clientId=$clientId');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEntityButton(
                icon: Icons.payment,
                label: 'Paiements',
                color: Colors.orange,
                onTap: () {
                  context.go('/payments?clientId=$clientId');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Troisième ligne : Interventions
        Row(
          children: [
            Expanded(
              child: _buildEntityButton(
                icon: Icons.build,
                label: 'Interventions',
                color: Colors.teal,
                onTap: () {
                  context.go('/interventions?clientId=$clientId');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEntityButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
