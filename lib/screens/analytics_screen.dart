import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/subject_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_chart.dart';
import '../widgets/attendance_trend_chart.dart';
import '../utils/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectListProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final monthlyStats = ref.watch(monthlyStatsProvider);
    final attendanceTrend = ref.watch(attendanceTrendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(subjectListProvider.notifier).loadSubjects();
              ref
                  .read(attendanceRecordsProvider.notifier)
                  .loadAttendanceRecords();
            },
          ),
        ],
      ),
      body: subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Data Available',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some subjects and mark attendance to see analytics',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(subjectListProvider.notifier).loadSubjects();
                await ref
                    .read(attendanceRecordsProvider.notifier)
                    .loadAttendanceRecords();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall stats card
                    _buildOverallStatsCard(context, overallStats),

                    const SizedBox(height: 24),

                    // Subject-wise attendance chart
                    Text(
                      'Subject-wise Attendance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    const SizedBox(height: 16),

                    AttendanceChart(subjects: subjects),

                    const SizedBox(height: 24),

                    // Weekly stats
                    Text(
                      'This Week',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    const SizedBox(height: 16),

                    _buildWeeklyStatsCard(context, weeklyStats),

                    const SizedBox(height: 24),

                    // Monthly stats
                    Text(
                      'This Month',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    const SizedBox(height: 16),

                    _buildMonthlyStatsCard(context, monthlyStats),

                    const SizedBox(height: 24),

                    // Attendance trend
                    Text(
                      '30-Day Trend',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    const SizedBox(height: 16),

                    AttendanceTrendChart(trendData: attendanceTrend),

                    const SizedBox(height: 24),

                    // Detailed subject breakdown
                    Text(
                      'Subject Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    const SizedBox(height: 16),

                    ...subjects
                        .map((subject) =>
                            _buildSubjectBreakdownCard(context, subject))
                        .toList(),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverallStatsCard(
      BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _getGradientForPercentage(stats['percentage']),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatItem(
                  context,
                  'Subjects',
                  stats['totalSubjects'].toString(),
                  Icons.school,
                ),
                _buildStatItem(
                  context,
                  'Total Classes',
                  stats['totalClasses'].toString(),
                  Icons.event,
                ),
                _buildStatItem(
                  context,
                  'Attended',
                  stats['attendedClasses'].toString(),
                  Icons.check_circle,
                ),
                _buildStatItem(
                  context,
                  'Percentage',
                  '${stats['percentage'].toStringAsFixed(1)}%',
                  Icons.percent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildWeeklyStatsCard(
      BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${stats['totalRecords']} records',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats['subjects'].isEmpty)
              Center(
                child: Text(
                  'No attendance records this week',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              )
            else
              ...stats['subjects'].entries.map((entry) {
                final subjectName = entry.key;
                final subjectStats = entry.value as Map<String, int>;
                final total = subjectStats['total']!;
                final present = subjectStats['present']!;
                final percentage = total > 0 ? (present / total) * 100 : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          subjectName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: total > 0 ? present / total : 0,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(percentage),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _getStatusColor(percentage),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyStatsCard(
      BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'This Month',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${stats['totalRecords']} records',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats['subjects'].isEmpty)
              Center(
                child: Text(
                  'No attendance records this month',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              )
            else
              ...stats['subjects'].entries.map((entry) {
                final subjectName = entry.key;
                final subjectStats = entry.value as Map<String, int>;
                final total = subjectStats['total']!;
                final present = subjectStats['present']!;
                final percentage = total > 0 ? (present / total) * 100 : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          subjectName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: total > 0 ? present / total : 0,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(percentage),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _getStatusColor(percentage),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectBreakdownCard(BuildContext context, subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(
                        subject.colorHex ?? AppTheme.primaryColor.toString()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subject.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '${subject.attendedClasses}/${subject.totalClasses} classes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(subject.attendancePercentage)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(subject.attendancePercentage)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${subject.attendancePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _getStatusColor(subject.attendancePercentage),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: subject.totalClasses > 0
                  ? subject.attendedClasses / subject.totalClasses
                  : 0,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(subject.attendancePercentage),
              ),
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      String cleanColor = colorString.replaceAll('#', '');
      if (cleanColor.length == 6) {
        return Color(int.parse('FF$cleanColor', radix: 16));
      }
    } catch (e) {
      // Fallback to primary color
    }
    return AppTheme.primaryColor;
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 75.0) return Colors.green;
    if (percentage >= 60.0) return Colors.orange;
    return Colors.red;
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
