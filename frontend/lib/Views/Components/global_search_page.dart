import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/global_search_notifier.dart';
import 'package:easyconnect/providers/global_search_state.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalSearchProvider);
    final notifier = ref.read(globalSearchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche globale'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher dans toute l\'application...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                          notifier.clearResults();
                        },
                      )
                    : const SizedBox.shrink(),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                notifier.setSearchQuery(value);
                if (value.isNotEmpty) {
                  notifier.performSearch(value);
                } else {
                  notifier.clearResults();
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) notifier.performSearch(value);
              },
            ),
          ),
        ),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, GlobalSearchState state) {
    if (state.isSearching) {
      return const SkeletonSearchResults(itemCount: 6);
    }
    if (state.searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Recherchez dans toute l\'application',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tapez votre recherche ci-dessus',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    if (state.hasNoResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        _SearchSection(
          list: state.clientsResults,
          title: 'Clients',
          buildHeader: _buildSectionHeader,
          buildCard: _buildClientCard,
        ),
        _SearchSection(
          list: state.invoicesResults,
          title: 'Factures',
          buildHeader: _buildSectionHeader,
          buildCard: _buildInvoiceCard,
        ),
        _SearchSection(
          list: state.paymentsResults,
          title: 'Paiements',
          buildHeader: _buildSectionHeader,
          buildCard: _buildPaymentCard,
        ),
        _SearchSection(
          list: state.employeesResults,
          title: 'Employés',
          buildHeader: _buildSectionHeader,
          buildCard: _buildEmployeeCard,
        ),
        _SearchSection(
          list: state.suppliersResults,
          title: 'Fournisseurs',
          buildHeader: _buildSectionHeader,
          buildCard: _buildSupplierCard,
        ),
        _SearchSection(
          list: state.stocksResults,
          title: 'Stocks',
          buildHeader: _buildSectionHeader,
          buildCard: _buildStockCard,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(BuildContext context, dynamic client) {
    final clientName =
        client.nomEntreprise?.isNotEmpty == true
            ? client.nomEntreprise!
            : '${client.nom ?? ''} ${client.prenom ?? ''}'.trim().isNotEmpty
                ? '${client.nom ?? ''} ${client.prenom ?? ''}'.trim()
                : 'Client #${client.id}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(clientName),
        subtitle: Text(client.email ?? client.contact ?? ''),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go('/clients/${client.id}'),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, dynamic invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: const Icon(Icons.receipt, color: Colors.green),
        ),
        title: Text('Facture ${invoice.invoiceNumber}'),
        subtitle: Text('Client: ${invoice.clientName}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go('/invoices'),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, dynamic payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: const Icon(Icons.payment, color: Colors.orange),
        ),
        title: Text('Paiement ${payment.reference ?? payment.id}'),
        subtitle: Text('Montant: ${payment.amount ?? 0} FCFA'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.push('/payments/detail', extra: payment.id),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, dynamic employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.1),
          child: const Icon(Icons.person_outline, color: Colors.purple),
        ),
        title: Text('${employee.firstName ?? ''} ${employee.lastName ?? ''}'),
        subtitle: Text(employee.email ?? ''),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go('/employees/${employee.id}'),
      ),
    );
  }

  Widget _buildSupplierCard(BuildContext context, dynamic supplier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.1),
          child: const Icon(Icons.business, color: Colors.teal),
        ),
        title: Text(supplier.nom),
        subtitle: Text('${supplier.email} | ${supplier.telephone}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go('/suppliers/${supplier.id}'),
      ),
    );
  }

  Widget _buildStockCard(BuildContext context, dynamic stock) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: const Icon(Icons.inventory, color: Colors.indigo),
        ),
        title: Text(stock.name),
        subtitle: Text('SKU: ${stock.sku} | Catégorie: ${stock.category}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go('/stocks/${stock.id}'),
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  final List<dynamic> list;
  final String title;
  final Widget Function(String, int) buildHeader;
  final Widget Function(BuildContext, dynamic) buildCard;

  const _SearchSection({
    required this.list,
    required this.title,
    required this.buildHeader,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: buildHeader(title, list.length),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => buildCard(context, list[index]),
              childCount: list.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}
