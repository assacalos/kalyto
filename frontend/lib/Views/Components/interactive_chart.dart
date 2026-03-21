import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class InteractiveChart extends StatelessWidget {
  final String title;
  final List<ChartData> data;
  final ChartType type;
  final Permission? requiredPermission;
  final bool isLoading;
  final String? subtitle;
  final Color color;
  final bool enableZoom;
  final bool showTooltips;
  final bool showLegend;
  final Function(ChartData)? onDataPointTap;

  const InteractiveChart({
    super.key,
    required this.title,
    required this.data,
    this.type = ChartType.line,
    this.requiredPermission,
    this.isLoading = false,
    this.subtitle,
    this.color = Colors.blue,
    this.enableZoom = true,
    this.showTooltips = true,
    this.showLegend = true,
    this.onDataPointTap,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                if (showLegend)
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildInteractiveChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveChart() {
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
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: color,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: showTooltips,
              touchTooltipData: LineTouchTooltipData(
                tooltipBorderRadius: BorderRadius.circular(8),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final data = this.data[spot.spotIndex];
                    return LineTooltipItem(
                      '${data.label ?? ''}\n${spot.y.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
              touchCallback:
                  enableZoom
                      ? (FlTouchEvent event, LineTouchResponse? response) {
                        if (response?.lineBarSpots != null &&
                            response!.lineBarSpots!.isNotEmpty &&
                            event is FlTapUpEvent) {
                          final spotIndex = response.lineBarSpots![0].spotIndex;
                          onDataPointTap?.call(data[spotIndex]);
                        }
                      }
                      : null,
            ),
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
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.length) {
                      return Text(
                        data[index].label ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups:
                data
                    .asMap()
                    .entries
                    .map(
                      (entry) => BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.y.toDouble(),
                            color: color,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    )
                    .toList(),
            barTouchData: BarTouchData(
              enabled: showTooltips,
              touchTooltipData: BarTouchTooltipData(
                tooltipBorderRadius: BorderRadius.circular(8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${data[groupIndex].label ?? ''}\n${rod.toY.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
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
                        title: showLegend ? d.label ?? '' : '',
                        color: color,
                        radius: 100,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                    .toList(),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(
              enabled: showTooltips,
              touchCallback:
                  enableZoom
                      ? (FlTouchEvent event, PieTouchResponse? response) {
                        if (response?.touchedSection != null &&
                            event is FlTapUpEvent) {
                          final index =
                              response!.touchedSection!.touchedSectionIndex;
                          onDataPointTap?.call(data[index]);
                        }
                      }
                      : null,
            ),
          ),
        );
    }
  }
}
