import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_record.dart';
import '../providers/subject_provider.dart';
import '../providers/attendance_provider.dart';

class QuickActions extends ConsumerWidget {
  final List<AttendanceRecord> todayAttendance;

  const QuickActions({
    super.key,
    required this.todayAttendance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectListProvider);
    final unmarkedSubjects = subjects
        .where((subject) => !todayAttendance
            .any((record) => record.subjectId == subject.id && record.isToday))
        .toList();

    if (unmarkedSubjects.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All caught up!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'You\'ve marked attendance for all subjects today',
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
                const Icon(
                  Icons.flash_on,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '${unmarkedSubjects.length} subject(s) need attendance marking',
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
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quick mark buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unmarkedSubjects.take(3).map((subject) {
                return _buildQuickActionChip(
                  context,
                  ref,
                  subject,
                );
              }).toList(),
            ),

            if (unmarkedSubjects.length > 3) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Show all unmarked subjects
                  _showAllUnmarkedSubjects(context, ref, unmarkedSubjects);
                },
                child: Text('+${unmarkedSubjects.length - 3} more'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(BuildContext context, WidgetRef ref, subject) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
        child: Text(
          subject.name[0].toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      label: Text(
        subject.name,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () {
        _showQuickMarkDialog(context, ref, subject);
      },
    );
  }

  void _showQuickMarkDialog(BuildContext context, WidgetRef ref, subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Attendance'),
        content: Text('Mark attendance for ${subject.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              ref.read(attendanceRecordsProvider.notifier).markTodayAttendance(
                    subject.id,
                    AttendanceStatus.Absent,
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Absent'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(attendanceRecordsProvider.notifier).markTodayAttendance(
                    subject.id,
                    AttendanceStatus.Present,
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Present'),
          ),
        ],
      ),
    );
  }

  void _showAllUnmarkedSubjects(
      BuildContext context, WidgetRef ref, List unmarkedSubjects) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mark Attendance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: unmarkedSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = unmarkedSubjects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Text(
                            subject.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(subject.name),
                        subtitle: Text(
                            '${subject.attendancePercentage.toStringAsFixed(1)}% attendance'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                ref
                                    .read(attendanceRecordsProvider.notifier)
                                    .markTodayAttendance(
                                      subject.id,
                                      AttendanceStatus.Absent,
                                    );
                              },
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                ref
                                    .read(attendanceRecordsProvider.notifier)
                                    .markTodayAttendance(
                                      subject.id,
                                      AttendanceStatus.Present,
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
