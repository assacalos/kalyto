import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/comptable_dashboard_notifier.dart';
import 'package:easyconnect/providers/comptable_dashboard_state.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class FinancesPage extends ConsumerWidget {
  const FinancesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(comptableDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finances'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(comptableDashboardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: asyncState.when(
        data: (state) => state.isLoading
            ? const SkeletonPage(listItemCount: 8)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPendingSection(context, state),
                    const SizedBox(height: 24),
                    _buildValidatedSection(context, state),
                    const SizedBox(height: 24),
                    _buildStatisticsSection(context, state),
                  ],
                ),
              ),
        loading: () => const SkeletonPage(listItemCount: 8),
        error: (_, __) => const Center(child: Text('Erreur de chargement')),
      ),
    );
  }

  Widget _buildPendingSection(BuildContext context, ComptableDashboardState state) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Entités en Attente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: width > 800 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _buildPendingCard(
                    title: 'Factures',
                    count: state.pendingFactures,
                    icon: Icons.receipt,
                    color: Colors.red,
                    onTap: () => context.go('/invoices'),
                  ),
                  _buildPendingCard(
                    title: 'Paiements',
                    count: state.pendingPaiements,
                    icon: Icons.payment,
                    color: Colors.teal,
                    onTap: () => context.go('/payments'),
                  ),
                  _buildPendingCard(
                    title: 'Dépenses',
                    count: state.pendingDepenses,
                    icon: Icons.money_off,
                    color: Colors.orange,
                    onTap: () => context.go('/expenses'),
                  ),
                  _buildPendingCard(
                    title: 'Salaires',
                    count: state.pendingSalaires,
                    icon: Icons.account_balance_wallet,
                    color: Colors.purple,
                    onTap: () => context.go('/salaries'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValidatedSection(BuildContext context, ComptableDashboardState state) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Entités Validées',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: width > 800 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _buildValidatedCard(
                    title: 'Factures Validées',
                    count: state.validatedFactures,
                    icon: Icons.receipt,
                    color: Colors.red,
                    subtitle: 'Factures traitées',
                  ),
                  _buildValidatedCard(
                    title: 'Paiements Validés',
                    count: state.validatedPaiements,
                    icon: Icons.payment,
                    color: Colors.teal,
                    subtitle: 'Paiements confirmés',
                  ),
                  _buildValidatedCard(
                    title: 'Dépenses Validées',
                    count: state.validatedDepenses,
                    icon: Icons.money_off,
                    color: Colors.orange,
                    subtitle: 'Dépenses approuvées',
                  ),
                  _buildValidatedCard(
                    title: 'Salaires Validés',
                    count: state.validatedSalaires,
                    icon: Icons.account_balance_wallet,
                    color: Colors.purple,
                    subtitle: 'Salaires payés',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, ComptableDashboardState state) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Statistiques Montants',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: width > 800 ? 3 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _buildStatisticCard(
                    title: 'Chiffre d\'Affaires',
                    value: '${state.totalRevenue.toStringAsFixed(0)} FCFA',
                    icon: Icons.euro,
                    color: Colors.green,
                    subtitle: 'Montant total des factures',
                  ),
                  _buildStatisticCard(
                    title: 'Paiements Reçus',
                    value: '${state.totalPayments.toStringAsFixed(0)} FCFA',
                    icon: Icons.payment,
                    color: Colors.blue,
                    subtitle: 'Montant des paiements reçus',
                  ),
                  _buildStatisticCard(
                    title: 'Dépenses Total',
                    value: '${state.totalExpenses.toStringAsFixed(0)} FCFA',
                    icon: Icons.money_off,
                    color: Colors.red,
                    subtitle: 'Montant total des dépenses',
                  ),
                  _buildStatisticCard(
                    title: 'Salaires Payés',
                    value: '${state.totalSalaries.toStringAsFixed(0)} FCFA',
                    icon: Icons.account_balance_wallet,
                    color: Colors.purple,
                    subtitle: 'Montant des salaires payés',
                  ),
                  _buildStatisticCard(
                    title: 'Bénéfice Net',
                    value: '${state.netProfit.toStringAsFixed(0)} FCFA',
                    icon: Icons.trending_up,
                    color: Colors.green,
                    subtitle: 'Bénéfice après dépenses',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidatedCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
