import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/subject.dart';

class AttendanceChart extends StatelessWidget {
  final List<Subject> subjects;

  const AttendanceChart({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return Card(
        child: Container(
          height: 240,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attendance Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: PieChart(
                  PieChartData(
                    sections: _buildSections(),
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final sections = <PieChartSectionData>[];

    // Group subjects by attendance percentage
    final goodAttendance =
        subjects.where((s) => s.attendancePercentage >= 75.0).length;
    final averageAttendance = subjects
        .where((s) =>
            s.attendancePercentage >= 60.0 && s.attendancePercentage < 75.0)
        .length;
    final poorAttendance =
        subjects.where((s) => s.attendancePercentage < 60.0).length;

    final data = [
      {'count': goodAttendance, 'label': 'Good (≥75%)', 'color': Colors.green},
      {
        'count': averageAttendance,
        'label': 'Average (60-75%)',
        'color': Colors.orange
      },
      {'count': poorAttendance, 'label': 'Poor (<60%)', 'color': Colors.red},
    ];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      if (item['count'] as int > 0) {
        sections.add(
          PieChartSectionData(
            color: item['color'] as Color,
            value: (item['count'] as int).toDouble(),
            title: '${item['count']}',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return sections;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Good (≥75%)', Colors.green),
        _buildLegendItem('Average (60-75%)', Colors.orange),
        _buildLegendItem('Poor (<60%)', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
