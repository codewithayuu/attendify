import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_record.dart';
import '../providers/subject_provider.dart';
import '../providers/attendance_provider.dart';
import '../services/schedule_service.dart';

class UpcomingClasses extends ConsumerWidget {
  const UpcomingClasses({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectListProvider);
    final upcomingClasses = ScheduleService.getUpcomingClasses(subjects, daysAhead: 7);

    if (upcomingClasses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.schedule,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                'No upcoming classes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add subjects with schedules to see upcoming classes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
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
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Classes (Next 7 Days)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...upcomingClasses.take(5).map((classInfo) => _buildClassTile(
                  context,
                  ref,
                  classInfo,
                )),
            if (upcomingClasses.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'And ${upcomingClasses.length - 5} more classes...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassTile(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> classInfo,
  ) {
    final subjectName = classInfo['subjectName'] as String;
    final time = classInfo['time'] as TimeOfDay;
    final dayName = classInfo['dayName'] as String;
    final isToday = classInfo['isToday'] as bool;
    final isPast = classInfo['isPast'] as bool;
    final subjectId = classInfo['subjectId'] as String;

    // Check if attendance is already marked for this class
    final todayAttendance = ref.watch(todayAttendanceProvider);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          // Date and time info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isToday ? Colors.blue : Colors.grey[600],
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'TODAY',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          if (isToday && !isPast) ...[
            if (!isMarked) ...[
              _buildActionButton(
                context,
                ref,
                subjectId,
                'Present',
                true,
                Colors.green,
                Icons.check,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                context,
                ref,
                subjectId,
                'Absent',
                false,
                Colors.red,
                Icons.close,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPresent ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPresent ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPresent ? 'Present' : 'Absent',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (isPast) ...[
            Text(
              'Past',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ] else ...[
            Text(
              'Upcoming',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    String subjectId,
    String label,
    bool isPresent,
    Color color,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () => _markAttendance(ref, subjectId, isPresent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAttendance(WidgetRef ref, String subjectId, bool isPresent) {
    final attendanceProvider = ref.read(attendanceRecordsProvider.notifier);
    
    final attendanceRecord = AttendanceRecord(
      id: '${subjectId}_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: subjectId,
      date: DateTime.now(),
      status: isPresent ? AttendanceStatus.Present : AttendanceStatus.Absent,
    );

    attendanceProvider.addAttendanceRecord(attendanceRecord);
  }
}
