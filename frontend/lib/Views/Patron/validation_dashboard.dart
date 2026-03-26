import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ValidationDashboard extends StatelessWidget {
  const ValidationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord des Validations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildValidationCard(
              context: context,
              title: 'Clients',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => context.push('/clients/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Devis',
              icon: Icons.description,
              color: Colors.green,
              onTap: () => context.push('/devis/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Bordereaux',
              icon: Icons.description,
              color: Colors.green,
              onTap: () => context.push('/bordereaux/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Bons de Commande',
              icon: Icons.shopping_cart,
              color: Colors.orange,
              onTap: () => context.push('/bon-commandes/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Factures',
              icon: Icons.receipt,
              color: Colors.red,
              onTap: () => context.push('/factures/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Paiements',
              icon: Icons.payment,
              color: Colors.teal,
              onTap: () => context.push('/paiements/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Stock',
              icon: Icons.inventory,
              color: Colors.deepPurple,
              onTap: () => context.push('/stock/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Interventions',
              icon: Icons.build,
              color: Colors.indigo,
              onTap: () => context.push('/interventions/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Salaires',
              icon: Icons.account_balance_wallet,
              color: Colors.amber,
              onTap: () => context.push('/salaires/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Recrutement',
              icon: Icons.person_add,
              color: Colors.cyan,
              onTap: () => context.push('/recrutement/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Pointage',
              icon: Icons.access_time,
              color: Colors.brown,
              onTap: () => context.push('/pointage/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Taxes et Impôts',
              icon: Icons.account_balance,
              color: Colors.deepOrange,
              onTap: () => context.push('/taxes/validation'),
            ),
            _buildValidationCard(
              context: context,
              title: 'Reporting',
              icon: Icons.analytics,
              color: Colors.pink,
              onTap: () => context.push('/reporting/validation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Validation',
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
