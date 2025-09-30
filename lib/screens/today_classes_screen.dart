import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/subject.dart';
import '../providers/today_classes_provider.dart';
import '../providers/subject_provider.dart' as subjects;
import '../services/schedule_service.dart';

class TodayClassesScreen extends ConsumerStatefulWidget {
  const TodayClassesScreen({super.key});

  @override
  ConsumerState<TodayClassesScreen> createState() => _TodayClassesScreenState();
}

class _TodayClassesScreenState extends ConsumerState<TodayClassesScreen> {
  @override
  Widget build(BuildContext context) {
    final todaySubjects = ref.watch(todayClassesProvider);
    final todayStats = ref.watch(todayAttendanceStatsProvider);
    final unmarkedSubjects = ref.watch(unmarkedAttendanceProvider);
    final nextClass = ref.watch(nextClassProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Classes"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (unmarkedSubjects.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _markAllPresent,
              tooltip: 'Mark All Present',
            ),
        ],
      ),
      body: todaySubjects.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Stats
                  _buildTodayStats(todayStats),

                  const SizedBox(height: 24),

                  // Next Class Info
                  if (nextClass != null) ...[
                    _buildNextClassCard(nextClass),
                    const SizedBox(height: 24),
                  ],

                  // Today's Classes Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Classes (${todaySubjects.length})",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (unmarkedSubjects.isNotEmpty)
                        TextButton.icon(
                          onPressed: _startMarkingAttendance,
                          icon: const Icon(Icons.edit),
                          label: const Text('Mark Attendance'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Classes List
                  ...todaySubjects.map((subject) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildSubjectCard(subject),
                      )),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Classes Today',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free day!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add-subject'),
            icon: const Icon(Icons.add),
            label: const Text('Add Subject'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Summary",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Classes',
                    stats['totalClasses'].toString(),
                    Icons.school,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Present',
                    stats['presentCount'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Absent',
                    stats['absentCount'].toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Unmarked',
                    stats['unmarkedAttendance'].toString(),
                    Icons.help_outline,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats['totalClasses'] > 0
                  ? stats['markedAttendance'] / stats['totalClasses']
                  : 0.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                stats['unmarkedAttendance'] > 0 ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats['markedAttendance']}/${stats['totalClasses']} classes marked',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX();
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNextClassCard(Subject nextClass) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _parseColor(nextClass.colorHex ?? '#2196F3'),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.schedule,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Class',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    nextClass.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${nextClass.nextClassDate?.day}/${nextClass.nextClassDate?.month} at ${nextClass.startTime}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideX();
  }

  Widget _buildSubjectCard(Subject subject) {
    final attendance = ScheduleService.getAttendanceForToday(subject);
    final isMarked = attendance != null;
    final isPresent = attendance?.present ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(subject.colorHex ?? '#2196F3'),
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
                    children: [
                      Text(
                        subject.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '${subject.startTime} - ${subject.endTime}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                if (isMarked)
                  Icon(
                    isPresent ? Icons.check_circle : Icons.cancel,
                    color: isPresent ? Colors.green : Colors.red,
                    size: 24,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Attendance Status
            if (isMarked) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPresent
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    color: isPresent ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              // Mark Attendance Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAttendance(subject, false),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Absent'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAttendance(subject, true),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Present'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX();
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
    return Colors.blue;
  }

  Future<void> _markAttendance(Subject subject, bool present) async {
    try {
      final attendance =
          ScheduleService.markAttendanceForToday(subject, present);

      // Update the subject with the new attendance record
      final updatedSubject = Subject(
        id: subject.id,
        name: subject.name,
        description: subject.description,
        colorHex: subject.colorHex,
        weekdays: subject.weekdays,
        startTime: subject.startTime,
        endTime: subject.endTime,
        semesterStart: subject.semesterStart,
        semesterEnd: subject.semesterEnd,
        totalClasses: subject.totalClasses,
        attendanceRecords: [
          ...subject.attendanceRecords
              .where((a) => !a.isForDate(DateTime.now())),
          attendance,
        ],
      );

      await ref
          .read(subjects.subjectListProvider.notifier)
          .updateSubject(updatedSubject);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Marked ${subject.name} as ${present ? 'Present' : 'Absent'}'),
            backgroundColor: present ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllPresent() async {
    final unmarkedSubjects = ref.read(unmarkedAttendanceProvider);

    for (final subject in unmarkedSubjects) {
      await _markAttendance(subject, true);
    }
  }

  void _startMarkingAttendance() {
    // This method can be used for future enhancements
  }
}
