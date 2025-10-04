import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../providers/subject_provider.dart' as subjects;
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';
import '../services/schedule_service.dart';
import '../utils/app_theme.dart';

class AddSubjectScreenEnhanced extends ConsumerStatefulWidget {
  final Subject? subject; // For editing existing subject

  const AddSubjectScreenEnhanced({super.key, this.subject});

  @override
  ConsumerState<AddSubjectScreenEnhanced> createState() =>
      _AddSubjectScreenEnhancedState();
}

class _AddSubjectScreenEnhancedState
    extends ConsumerState<AddSubjectScreenEnhanced> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Schedule fields
  List<int> _selectedWeekdays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _recurringWeekly = true; // true = Regular weekly, false = One-time
  String _selectedColor = '#2196F3';

  bool _isLoading = false;

  final List<String> _colors = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#F44336',
    '#9C27B0',
    '#00BCD4',
    '#FF5722',
    '#795548',
    '#607D8B',
    '#E91E63',
  ];

  final List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  String _weekdayAbbrev(int weekday) {
    // weekday: 1=Mon ... 7=Sun
    final name = _weekdayNames[weekday - 1];
    return name.substring(0, 3);
  }

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _loadSubjectData();
    }
  }

  void _loadSubjectData() {
    final subject = widget.subject!;

    // Validate that subject is actually a Subject object
    if (subject is! Subject) {
      print('❌ Error: subject is not a Subject object: ${subject.runtimeType}');
      // Use default values if subject is not a proper Subject object
      _nameController.text = 'Unknown Subject';
      _descriptionController.text = '';
      _selectedWeekdays = [1, 3, 5]; // Default weekdays
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      _recurringWeekly = true;
      _selectedColor = '#2196F3';
      return;
    }

    _nameController.text = subject.name;
    _descriptionController.text = subject.description ?? '';
    _selectedWeekdays = List.from(subject.weekdays);

    // Parse time strings to TimeOfDay with error handling
    try {
      final startTimeParts = subject.startTime.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      );
    } catch (e) {
      print('❌ Error parsing startTime: $e');
      _startTime = const TimeOfDay(hour: 9, minute: 0);
    }

    try {
      final endTimeParts = subject.endTime.split(':');
      _endTime = TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      );
    } catch (e) {
      print('❌ Error parsing endTime: $e');
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    }

    _recurringWeekly = subject.recurringWeekly;
    _selectedColor = subject.colorHex ?? '#2196F3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject != null ? 'Edit Subject' : 'Add Subject'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.subject != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),

                    _buildNameField(),
                    const SizedBox(height: 16),

                    _buildDescriptionField(),
                    const SizedBox(height: 16),

                    _buildColorSelector(),

                    const SizedBox(height: 32),

                    // Schedule Section
                    _buildSectionHeader('Schedule'),
                    const SizedBox(height: 16),

                    _buildWeekdaySelector(),
                    const SizedBox(height: 16),

                    _buildRecurrenceSelector(),
                    const SizedBox(height: 16),

                    _buildTimeSelector(),

                    const SizedBox(height: 32),

                    // Preview Section
                    _buildPreviewSection(),

                    const SizedBox(height: 32),

                    // Action Buttons
                    _buildActionButtons(),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
    ).animate().fadeIn(duration: 300.ms).slideX();
  }

  Widget _buildNameField() {
    return Card(
      child: TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Subject Name',
          hintText: 'e.g., Mathematics, Physics',
          prefixIcon: Icon(Icons.school),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a subject name';
          }
          return null;
        },
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideX();
  }

  Widget _buildDescriptionField() {
    return Card(
      child: TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Description (Optional)',
          hintText: 'Brief description of the subject',
          prefixIcon: Icon(Icons.description),
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideX();
  }

  Widget _buildColorSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Color',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _parseColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _parseColor(color).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideX();
  }

  Widget _buildWeekdaySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final isSelected = _selectedWeekdays.contains(weekday);
                return FilterChip(
                  label: Text(_weekdayNames[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedWeekdays.add(weekday);
                      } else {
                        _selectedWeekdays.remove(weekday);
                      }
                    });
                  },
                  selectedColor:
                      Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideX();
  }

  Widget _buildRecurrenceSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recurrence',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: -2, vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      'Regular weekly',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text(
                      'Repeats every week',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: true,
                    groupValue: _recurringWeekly,
                    onChanged: (value) {
                      setState(() {
                        _recurringWeekly = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: -2, vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      'One-time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text(
                      'Single occurrence',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: false,
                    groupValue: _recurringWeekly,
                    onChanged: (value) {
                      setState(() {
                        _recurringWeekly = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 450.ms).slideX();
  }

  Widget _buildTimeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: -2, vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    horizontalTitleGap: 8,
                    minLeadingWidth: 24,
                    title: const Text(
                      'Start Time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatTimeOfDay(_startTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: const Icon(Icons.schedule),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: _selectStartTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: -2, vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    horizontalTitleGap: 8,
                    minLeadingWidth: 24,
                    title: const Text(
                      'End Time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatTimeOfDay(_endTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: const Icon(Icons.schedule),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: _selectEndTime,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 500.ms).slideX();
  }

  Widget _buildPreviewSection() {
    // Get semester dates from settings for preview
    final settings = ref.watch(settingsProvider);
    final semesterStart = settings.semesterStart ?? DateTime.now();
    final semesterEnd =
        settings.semesterEnd ?? DateTime.now().add(const Duration(days: 90));

    // Create a temporary subject-like object for preview
    final tempSubject = {
      'weekdays': _selectedWeekdays,
      'startTime': _formatTimeOfDay(_startTime),
    };

    final classDates = ScheduleService.generateClassDates(
      tempSubject,
      semesterStart,
      semesterEnd,
    );

    final startStr = MaterialLocalizations.of(context)
        .formatTimeOfDay(_startTime, alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat);
    final endStr = MaterialLocalizations.of(context)
        .formatTimeOfDay(_endTime, alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _parseColor(_selectedColor),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isEmpty
                            ? 'Subject Name'
                            : _nameController.text,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (_selectedWeekdays.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedWeekdays
                              .map((d) => Chip(
                                    label: Text(_weekdayAbbrev(d)),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 0),
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: '$startStr - $endStr',
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.calendar_month,
                        label: 'Total Classes: ${classDates.length}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 700.ms).slideX();
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveSubject,
            child: Text(widget.subject != null ? 'Update' : 'Create'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 800.ms).slideX();
  }

  void _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  void _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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

  void _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    // Get semester dates from settings
    final settings = ref.read(settingsProvider);
    final semesterStart = settings.semesterStart ?? DateTime.now();
    final semesterEnd =
        settings.semesterEnd ?? DateTime.now().add(const Duration(days: 90));

    // Validate schedule
    final errors = ScheduleService.validateSchedule(
      weekdays: _selectedWeekdays,
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      semesterStart: semesterStart,
      semesterEnd: semesterEnd,
    );

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.join('\n')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Require at least one weekday
      if (_selectedWeekdays.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one class day'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Generate class dates using ScheduleService
      final classDates = ScheduleService.generateOccurrences(
        start: semesterStart,
        end: semesterEnd,
        weekdays: _selectedWeekdays,
        startTime: _startTime,
      );

      final subjectId = widget.subject?.id ?? const Uuid().v4();

      final subject = Subject(
        id: subjectId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        colorHex: _selectedColor,
        weekdays: _selectedWeekdays,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        semesterStart: semesterStart,
        semesterEnd: semesterEnd,
        totalClasses: classDates.length,
        recurringWeekly: _recurringWeekly,
        requiredPercent: null, // Use global default
      );

      if (widget.subject != null) {
        await ref
            .read(subjects.subjectListProvider.notifier)
            .updateSubject(subject);
      } else {
        await ref
            .read(subjects.subjectListProvider.notifier)
            .addSubject(subject);

        // Generate attendance records for new recurring subjects
        if (subject.recurringWeekly && classDates.isNotEmpty) {
          await _generateAttendanceRecords(subjectId, classDates);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.subject != null
                ? 'Subject updated successfully!'
                : 'Subject created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving subject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
            'Are you sure you want to delete "${widget.subject?.name}"? This will also delete all attendance records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSubject();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject() async {
    if (widget.subject == null) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(subjects.subjectListProvider.notifier)
          .deleteSubject(widget.subject!.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting subject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Generate attendance records for a subject's scheduled classes
  Future<void> _generateAttendanceRecords(
      String subjectId, List<DateTime> classDates) async {
    try {
      final attendanceProvider = ref.read(attendanceRecordsProvider.notifier);

      for (final classDate in classDates) {
        final attendanceRecord = AttendanceRecord(
          id: '${subjectId}_${classDate.millisecondsSinceEpoch}',
          subjectId: subjectId,
          date: classDate,
          status: AttendanceStatus.Unmarked,
        );

        await attendanceProvider.addAttendanceRecord(attendanceRecord);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${classDates.length} attendance records'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating attendance records: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
