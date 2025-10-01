import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subject.dart';
import '../models/attendance.dart';
import '../models/attendance_record.dart';
import '../services/schedule_service.dart';
import '../services/attendance_service.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class SubjectCardEnhanced extends ConsumerStatefulWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showScheduleInfo;

  const SubjectCardEnhanced({
    super.key,
    required this.subject,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.showScheduleInfo = true,
  });

  @override
  ConsumerState<SubjectCardEnhanced> createState() =>
      _SubjectCardEnhancedState();
}

class _SubjectCardEnhancedState extends ConsumerState<SubjectCardEnhanced> {
  Map<String, dynamic>? _stats;
  Attendance? _attendance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataAsync();
  }

  // Load data asynchronously to avoid blocking main thread
  Future<void> _loadDataAsync() async {
    if (!mounted) return;

    try {
      // Use Future.microtask to move computation off main thread
      final stats = await Future.microtask(() => _calculateAttendanceStats());
      final attendance = await Future.microtask(
          () => ScheduleService.getAttendanceForToday(widget.subject));

      if (mounted) {
        setState(() {
          _stats = stats;
          _attendance = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate attendance stats using the new AttendanceService
  Map<String, dynamic> _calculateAttendanceStats() {
    // Get settings for default required percentage
    final settings = ref.read(settingsProvider);

    // Get all attendance records for this subject
    final attendanceRecords = ref.read(attendanceRecordsProvider);
    final subjectRecords = attendanceRecords
        .where(
          (record) => record.subjectId == widget.subject.id,
        )
        .toList();

    // Count present records
    final attendedClasses = subjectRecords
        .where(
          (record) =>
              record.status == AttendanceStatus.Present ||
              record.status == AttendanceStatus.Late,
        )
        .length;

    // Calculate total classes from schedule until semester end
    final semesterEnd =
        settings.semesterEnd ?? DateTime.now().add(const Duration(days: 90));
    final classDates = ScheduleService.generateOccurrences(
      start: DateTime.now(),
      end: semesterEnd,
      weekdays: widget.subject.weekdays,
      startTime: _parseTimeOfDay(widget.subject.startTime),
    );
    final totalClasses = classDates.length;

    // Use AttendanceService for calculations
    final attendanceStats =
        AttendanceService.getAttendanceStats(widget.subject, settings);

    // Add our calculated values
    attendanceStats['totalClasses'] = totalClasses;
    attendanceStats['attendedClasses'] = attendedClasses;
    attendanceStats['classDates'] = classDates;

    return attendanceStats;
  }

  // Parse time string to TimeOfDay
  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading ? _buildLoadingState() : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _parseColor(
                widget.subject.colorHex ?? AppTheme.primaryColor.toString()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.school, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subject.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final attendance = _attendance;
    final isMarkedToday = attendance != null;
    final isPresentToday = attendance?.present ?? false;
    final stats = _stats ?? {'total': 0, 'present': 0, 'absent': 0};

    return Column(
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
                color: _parseColor(widget.subject.colorHex ??
                    AppTheme.primaryColor.toString()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subject.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (widget.subject.description != null &&
                      widget.subject.description!.isNotEmpty)
                    Text(
                      widget.subject.description!,
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

            // Today's attendance status
            if (widget.subject.hasClassTodayAndActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMarkedToday
                      ? (isPresentToday ? Colors.green : Colors.red)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isMarkedToday
                      ? (isPresentToday ? 'Present' : 'Absent')
                      : 'Not Marked',
                  style: TextStyle(
                    color: isMarkedToday ? Colors.white : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Schedule information
        if (widget.showScheduleInfo) ...[
          _buildScheduleInfo(context),
          const SizedBox(height: 12),
        ],

        // Attendance statistics
        _buildAttendanceStats(context, stats),

        // Action buttons (only show if showActions is true)
        if (widget.showActions) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onEdit != null)
                IconButton(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit Subject',
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              if (widget.onDelete != null)
                IconButton(
                  onPressed: widget.onDelete,
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
    );
  }

  Widget _buildScheduleInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildScheduleItem(
                  context,
                  Icons.calendar_today,
                  widget.subject.weekdaysString,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScheduleItem(
                  context,
                  Icons.access_time,
                  widget.subject.timeRange,
                ),
              ),
            ],
          ),
          if (widget.subject.nextClassDate != null) ...[
            const SizedBox(height: 8),
            _buildScheduleItem(
              context,
              Icons.arrow_forward,
              'Next: ${_formatDate(widget.subject.nextClassDate!)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStats(
      BuildContext context, Map<String, dynamic> stats) {
    final currentPercentage = stats['currentPercentage'] as double? ?? 0.0;
    final totalClasses = stats['totalClasses'] as int? ?? 0;
    final attendedClasses = stats['attendedClasses'] as int? ?? 0;
    final requiredPercentage = stats['requiredPercentage'] as double? ?? 75.0;
    final classesNeeded = stats['classesNeeded'] as int? ?? 0;
    final isOnTrack = stats['isOnTrack'] as bool? ?? false;
    final classDates = stats['classDates'] as List<DateTime>? ?? [];

    // Calculate remaining classes (future classes only)
    final now = DateTime.now();
    final remainingClasses =
        classDates.where((date) => date.isAfter(now)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: totalClasses > 0 ? attendedClasses / totalClasses : 0.0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(currentPercentage),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${currentPercentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(currentPercentage),
                  ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$attendedClasses/$totalClasses classes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            Row(
              children: [
                Icon(
                  isOnTrack ? Icons.check_circle : Icons.warning,
                  size: 16,
                  color: isOnTrack ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  isOnTrack
                      ? 'Above ${requiredPercentage.toInt()}%'
                      : 'Below ${requiredPercentage.toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOnTrack ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),

        // Recommendation badge
        if (classesNeeded > 0 && remainingClasses > 0) ...[
          const SizedBox(height: 8),
          _buildRecommendationBadge(
              context, classesNeeded, remainingClasses, requiredPercentage),
        ],
      ],
    );
  }

  Widget _buildRecommendationBadge(BuildContext context, int classesNeeded,
      int remainingClasses, double requiredPercentage) {
    final canMeetRequirement = classesNeeded <= remainingClasses;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: canMeetRequirement
            ? Colors.blue.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canMeetRequirement
              ? Colors.blue.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            canMeetRequirement ? Icons.info_outline : Icons.warning_amber,
            size: 14,
            color: canMeetRequirement ? Colors.blue : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            canMeetRequirement
                ? 'Attend $classesNeeded of $remainingClasses remaining to reach ${requiredPercentage.toInt()}%'
                : 'Need $classesNeeded more classes (only $remainingClasses remaining)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: canMeetRequirement ? Colors.blue : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
