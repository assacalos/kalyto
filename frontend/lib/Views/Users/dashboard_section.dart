import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tableau de bord",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),

          /// --- Cartes Statistiques
          GridView.count(
            crossAxisCount: isLargeScreen ? 4 : 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _DashboardCard(title: "Utilisateurs actifs", value: "128"),
              _DashboardCard(title: "Nouveaux inscrits", value: "12"),
              _DashboardCard(title: "Logs enregistrés", value: "523"),
              _DashboardCard(title: "Incidents sécurité", value: "3"),
            ],
          ),
          const SizedBox(height: 30),

          /// --- Graphiques
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Graphique courbes
              Expanded(flex: 2, child: _LineChartCard()),
              const SizedBox(width: 16),

              /// Graphique camembert
              Expanded(flex: 1, child: _PieChartCard()),
            ],
          ),
        ],
      ),
    );
  }
}

/// --- Carte Statistique
class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  const _DashboardCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- Carte Graphique Courbes
class _LineChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Évolution des utilisateurs",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            "Jan",
                            "Fév",
                            "Mar",
                            "Avr",
                            "Mai",
                            "Juin",
                          ];
                          if (value.toInt() < months.length) {
                            return Text(months[value.toInt()]);
                          }
                          return const Text("");
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: const [
                        FlSpot(0, 20),
                        FlSpot(1, 40),
                        FlSpot(2, 25),
                        FlSpot(3, 60),
                        FlSpot(4, 50),
                        FlSpot(5, 70),
                      ],
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- Carte Graphique Camembert
class _PieChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Répartition des rôles",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: 50,
                      title: "Admins",
                      radius: 50,
                      titleStyle: const TextStyle(color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: 30,
                      title: "Commerciaux",
                      radius: 50,
                      titleStyle: const TextStyle(color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: 20,
                      title: "RH",
                      radius: 50,
                      titleStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
