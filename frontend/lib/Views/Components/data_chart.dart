import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class DataChart extends StatelessWidget {
  final String title;
  final List<ChartData> data;
  final ChartType type;
  final Permission? requiredPermission;
  final bool isLoading;
  final String? subtitle;
  final Color color;

  const DataChart({
    super.key,
    required this.title,
    required this.data,
    this.type = ChartType.line,
    this.requiredPermission,
    this.isLoading = false,
    this.subtitle,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: const SkeletonCard(height: 300),
        ),
      );
    }

    return Card(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 16),
            Expanded(child: _buildChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    switch (type) {
      case ChartType.line:
        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots:
                    data
                        .map((d) => FlSpot(d.x.toDouble(), d.y.toDouble()))
                        .toList(),
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );

      case ChartType.bar:
        return BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups:
                data
                    .map(
                      (d) => BarChartGroupData(
                        x: d.x,
                        barRods: [
                          BarChartRodData(
                            toY: d.y.toDouble(),
                            color: color,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    )
                    .toList(),
          ),
        );

      case ChartType.pie:
        return PieChart(
          PieChartData(
            sections:
                data
                    .map(
                      (d) => PieChartSectionData(
                        value: d.y.toDouble(),
                        title: d.label ?? '',
                        color: color,
                        radius: 100,
                      ),
                    )
                    .toList(),
          ),
        );
    }
  }
}

enum ChartType { line, bar, pie }

class ChartData {
  final int x;
  final num y;
  final String? label;

  const ChartData(this.x, this.y, [this.label]);
}
