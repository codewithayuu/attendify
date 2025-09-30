import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../utils/app_theme.dart';

class AttendanceTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trendData;

  const AttendanceTrendChart({super.key, required this.trendData});

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text('No data to display'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '30-Day Attendance Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return Text(
                              'Day ${value.toInt()}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  minX: 0,
                  maxX: 29,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildSpots(),
                      isCurved: true,
                      gradient: AppTheme.primaryGradient,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.3),
                            AppTheme.primaryColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    final spots = <FlSpot>[];

    for (int i = 0; i < trendData.length; i++) {
      final data = trendData[i];
      spots.add(
        FlSpot(
          i.toDouble(),
          data['percentage'] as double,
        ),
      );
    }

    return spots;
  }

  Widget _buildStatsRow() {
    if (trendData.isEmpty) return const SizedBox.shrink();

    final totalDays = trendData.length;
    final daysWithAttendance = trendData.where((d) => d['total'] > 0).length;
    final averagePercentage = trendData
            .where((d) => d['total'] > 0)
            .map((d) => d['percentage'] as double)
            .fold(0.0, (sum, p) => sum + p) /
        (daysWithAttendance > 0 ? daysWithAttendance : 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Total Days', totalDays.toString()),
        _buildStatItem('Days with Attendance', daysWithAttendance.toString()),
        _buildStatItem('Average', '${averagePercentage.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
