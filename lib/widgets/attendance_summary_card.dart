import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AttendanceSummaryCard extends StatelessWidget {
  final int totalSubjects;
  final int totalClasses;
  final int attendedClasses;
  final double overallPercentage;

  const AttendanceSummaryCard({
    super.key,
    required this.totalSubjects,
    required this.totalClasses,
    required this.attendedClasses,
    required this.overallPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _getGradientForPercentage(overallPercentage),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Attendance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${overallPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress bar
            LinearProgressIndicator(
              value: totalClasses > 0 ? attendedClasses / totalClasses : 0,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
            
            const SizedBox(height: 16),
            
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Subjects',
                    totalSubjects.toString(),
                    Icons.school,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Classes',
                    totalClasses.toString(),
                    Icons.event,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Attended',
                    attendedClasses.toString(),
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  LinearGradient _getGradientForPercentage(double percentage) {
    if (percentage >= 75.0) {
      return AppTheme.successGradient;
    } else if (percentage >= 60.0) {
      return AppTheme.warningGradient;
    } else {
      return AppTheme.errorGradient;
    }
  }
}

