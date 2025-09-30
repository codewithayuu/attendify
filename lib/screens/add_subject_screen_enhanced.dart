import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../models/subject.dart';
import '../providers/subject_provider.dart' as subjects;
import '../services/schedule_service.dart';
import '../utils/app_theme.dart';

class AddSubjectScreenEnhanced extends ConsumerStatefulWidget {
  final Subject? subject; // For editing existing subject

  const AddSubjectScreenEnhanced({super.key, this.subject});

  @override
  ConsumerState<AddSubjectScreenEnhanced> createState() => _AddSubjectScreenEnhancedState();
}

class _AddSubjectScreenEnhancedState extends ConsumerState<AddSubjectScreenEnhanced> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Schedule fields
  List<int> _selectedWeekdays = [];
  String _startTime = '09:00';
  String _endTime = '10:00';
  DateTime _semesterStart = DateTime.now();
  DateTime _semesterEnd = DateTime.now().add(const Duration(days: 90));
  String _selectedColor = '#2196F3';
  
  bool _isLoading = false;

  final List<String> _colors = [
    '#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0',
    '#00BCD4', '#FF5722', '#795548', '#607D8B', '#E91E63',
  ];

  final List<String> _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _loadSubjectData();
    }
  }

  void _loadSubjectData() {
    final subject = widget.subject!;
    _nameController.text = subject.name;
    _descriptionController.text = subject.description ?? '';
    _selectedWeekdays = List.from(subject.weekdays);
    _startTime = subject.startTime;
    _endTime = subject.endTime;
    _semesterStart = subject.semesterStart;
    _semesterEnd = subject.semesterEnd;
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
                    
                    _buildTimeSelector(),
                    const SizedBox(height: 16),
                    
                    _buildSemesterDateSelector(),
                    
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
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideX();
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
                    title: const Text('Start Time'),
                    subtitle: Text(_startTime),
                    leading: const Icon(Icons.schedule),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectStartTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(_endTime),
                    leading: const Icon(Icons.schedule),
                    trailing: const Icon(Icons.chevron_right),
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

  Widget _buildSemesterDateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semester Period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text('${_semesterStart.day}/${_semesterStart.month}/${_semesterStart.year}'),
                    leading: const Icon(Icons.calendar_today),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectSemesterStart,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text('${_semesterEnd.day}/${_semesterEnd.month}/${_semesterEnd.year}'),
                    leading: const Icon(Icons.calendar_today),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectSemesterEnd,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 600.ms).slideX();
  }

  Widget _buildPreviewSection() {
    final classDates = ScheduleService.generateClassDates(
      _semesterStart,
      _semesterEnd,
      _selectedWeekdays,
    );

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
                        _nameController.text.isEmpty ? 'Subject Name' : _nameController.text,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedWeekdays.isNotEmpty)
                        Text(
                          'Days: ${_selectedWeekdays.map((day) => _weekdayNames[day - 1]).join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      Text(
                        'Time: $_startTime - $_endTime',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Total Classes: ${classDates.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
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
      initialTime: _parseTimeString(_startTime),
    );
    if (time != null) {
      setState(() {
        _startTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _parseTimeString(_endTime),
    );
    if (time != null) {
      setState(() {
        _endTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _selectSemesterStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _semesterStart,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _semesterStart = date;
        if (_semesterEnd.isBefore(_semesterStart)) {
          _semesterEnd = _semesterStart.add(const Duration(days: 90));
        }
      });
    }
  }

  void _selectSemesterEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _semesterEnd,
      firstDate: _semesterStart,
      lastDate: DateTime.now().add(const Duration(days: 500)),
    );
    if (date != null) {
      setState(() {
        _semesterEnd = date;
      });
    }
  }

  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
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

  void _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate schedule
    final errors = ScheduleService.validateSchedule(
      weekdays: _selectedWeekdays,
      startTime: _startTime,
      endTime: _endTime,
      semesterStart: _semesterStart,
      semesterEnd: _semesterEnd,
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
      final classDates = ScheduleService.generateClassDates(
        _semesterStart,
        _semesterEnd,
        _selectedWeekdays,
      );

      final attendanceRecords = ScheduleService.generateAttendanceRecords(
        widget.subject?.id ?? const Uuid().v4(),
        classDates,
      );

      final subject = Subject(
        id: widget.subject?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        colorHex: _selectedColor,
        weekdays: _selectedWeekdays,
        startTime: _startTime,
        endTime: _endTime,
        semesterStart: _semesterStart,
        semesterEnd: _semesterEnd,
        totalClasses: classDates.length,
        attendanceRecords: attendanceRecords,
      );

      if (widget.subject != null) {
        await ref.read(subjects.subjectListProvider.notifier).updateSubject(subject);
      } else {
        await ref.read(subjects.subjectListProvider.notifier).addSubject(subject);
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
        content: Text('Are you sure you want to delete "${widget.subject?.name}"? This will also delete all attendance records.'),
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
      await ref.read(subjects.subjectListProvider.notifier).deleteSubject(widget.subject!.id);
      
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
}
