import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';
import '../utils/app_theme.dart';

class SubjectCard extends ConsumerWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final Function(bool isPresent)? onMarkAttendance;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
    this.onMarkAttendance,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAttendance = ref.watch(todayAttendanceProvider);
    final isMarkedToday = todayAttendance
        .any((record) => record.subjectId == subject.id && record.isToday);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Subject icon with color
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _parseColor(
                          subject.colorHex ?? AppTheme.primaryColor.toString()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Subject info
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
                        if (subject.description != null &&
                            subject.description!.isNotEmpty)
                          Text(
                            subject.description!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withOpacity(0.7),
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Attendance percentage
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

              const SizedBox(height: 16),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attendance Progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        '${subject.attendedClasses}/${subject.totalClasses}',
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
                  const SizedBox(height: 8),
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

              const SizedBox(height: 16),

              // Action buttons
              if (!isMarkedToday) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onMarkAttendance?.call(false),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Absent'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onMarkAttendance?.call(true),
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
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Attendance marked for today',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons (only show if showActions is true)
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Edit Subject',
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 20),
                        tooltip: 'Delete Subject',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      // Remove # if present and convert to Color
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
}
