import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../providers/subject_provider.dart' as subjects;
import '../providers/attendance_provider.dart';
import '../services/schedule_service.dart';

class TodayClassesScreen extends ConsumerStatefulWidget {
  const TodayClassesScreen({super.key});

  @override
  ConsumerState<TodayClassesScreen> createState() => _TodayClassesScreenState();
}

class _TodayClassesScreenState extends ConsumerState<TodayClassesScreen> {
  @override
  Widget build(BuildContext context) {
    final allSubjects = ref.watch(subjects.subjectListProvider);
    final now = DateTime.now();
    final todayClasses = ScheduleService.getClassesOnDate(allSubjects, now);
    final todayAttendance = ref.watch(todayAttendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Classes"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (todayClasses.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _markAllPresent,
              tooltip: 'Mark All Present',
            ),
        ],
      ),
      body: todayClasses.isEmpty
          ? _buildEmptyState(allSubjects)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Classes Header
                  Text(
                    "Today's Classes (${todayClasses.length})",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Classes List
                  ...todayClasses.map((classInfo) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildClassCard(classInfo, todayAttendance),
                      )),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(List<Subject> allSubjects) {
    // Show upcoming classes preview to avoid a blank screen on off-days
    final upcoming =
        ScheduleService.getUpcomingClasses(allSubjects, daysAhead: 7);
    final upcomingPreview = upcoming.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
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
          if (upcomingPreview.isNotEmpty) ...[
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Upcoming',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            ...upcomingPreview.map((c) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(c['subjectName'] as String),
                    subtitle: Text(
                        '${c['dayName']} at ${(c['time'] as TimeOfDay).hour.toString().padLeft(2, '0')}:${(c['time'] as TimeOfDay).minute.toString().padLeft(2, '0')}'),
                  ),
                )),
          ],
          const SizedBox(height: 48),
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

  Widget _buildClassCard(
      Map<String, dynamic> classInfo, List<AttendanceRecord> todayAttendance) {
    final subjectName = classInfo['subjectName'] as String;
    final time = classInfo['time'] as TimeOfDay;
    final subjectId = classInfo['subjectId'] as String;
    final subject = classInfo['subject'] as Subject;

    // Check if attendance is already marked for this class
    AttendanceRecord? existingRecord;
    try {
      existingRecord = todayAttendance.firstWhere(
        (record) => record.subjectId == subjectId && record.isToday,
      );
    } catch (e) {
      existingRecord = null;
    }

    final isMarked = existingRecord != null;
    final isPresent = existingRecord?.status == AttendanceStatus.Present;

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
                        subjectName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${subject.endTime}',
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
                      onPressed: () =>
                          _markAttendanceForClass(classInfo, false),
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
                      onPressed: () => _markAttendanceForClass(classInfo, true),
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

  Future<void> _markAttendanceForClass(
      Map<String, dynamic> classInfo, bool present) async {
    try {
      final subjectId = classInfo['subjectId'] as String;
      final subjectName = classInfo['subjectName'] as String;

      final attendanceRecord = AttendanceRecord(
        id: '${subjectId}_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: subjectId,
        date: DateTime.now(),
        status: present ? AttendanceStatus.Present : AttendanceStatus.Absent,
      );

      final attendanceProvider = ref.read(attendanceRecordsProvider.notifier);
      await attendanceProvider.addAttendanceRecord(attendanceRecord);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Marked $subjectName as ${present ? 'Present' : 'Absent'}'),
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
    final allSubjects = ref.read(subjects.subjectListProvider);
    final todayClasses =
        ScheduleService.getClassesOnDate(allSubjects, DateTime.now());
    final todayAttendance = ref.read(todayAttendanceProvider);

    for (final classInfo in todayClasses) {
      final subjectId = classInfo['subjectId'] as String;

      // Check if already marked
      final isAlreadyMarked = todayAttendance.any(
        (record) => record.subjectId == subjectId && record.isToday,
      );

      if (!isAlreadyMarked) {
        await _markAttendanceForClass(classInfo, true);
      }
    }
  }

  void _startMarkingAttendance() {
    // This method can be used for future enhancements
  }
}
