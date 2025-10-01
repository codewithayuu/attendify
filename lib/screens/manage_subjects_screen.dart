import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subject_provider.dart' as subjects;
import '../providers/settings_provider.dart' as settings;
import '../services/default_subjects_service.dart';
import '../models/subject.dart';
import '../widgets/subject_card.dart';

class ManageSubjectsScreen extends ConsumerStatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  ConsumerState<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends ConsumerState<ManageSubjectsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final subjectsList = ref.watch(subjects.subjectListProvider);
    final settingsData = ref.watch(settings.settingsProvider);
    final defaultSubjects = DefaultSubjectsService.getDefaultSubjects();
    final customSubjects = DefaultSubjectsService.getCustomSubjects();
    final missingDefaults = DefaultSubjectsService.getMissingDefaultSubjects();
    final stats = DefaultSubjectsService.getSubjectStatistics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSubjectStats(context, stats),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Settings Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Default Subjects Settings',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text('Show Default Subjects'),
                            subtitle: const Text('Display default subjects in the main list'),
                            value: settingsData.showDefaultSubjects,
                            onChanged: (value) {
                              ref.read(settings.settingsProvider.notifier).updateSettings(
                                settingsData.copyWith(showDefaultSubjects: value),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quick Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: missingDefaults.isNotEmpty ? _addMissingDefaults : null,
                                icon: const Icon(Icons.add_circle_outline),
                                label: Text('Add Missing (${missingDefaults.length})'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _resetToDefaults,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reset to Defaults'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _clearAllSubjects,
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Default Subjects Section
                  if (settingsData.showDefaultSubjects) ...[
                    Text(
                      'Default Subjects (${defaultSubjects.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: defaultSubjects.length * 120.0, // Approximate height per card
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: defaultSubjects.length,
                        itemBuilder: (context, index) {
                          final subjectData = defaultSubjects[index];
                          final existingSubject = subjectsList.firstWhere(
                            (s) => s.name == subjectData['name'],
                            orElse: () => Subject(
                              name: subjectData['name'],
                              description: subjectData['description'],
                              colorHex: subjectData['colorHex'],
                              totalClasses: 0,
                              attendedClasses: 0,
                            ),
                          );
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SubjectCard(
                              key: ValueKey('default_${existingSubject.id}'),
                              subject: existingSubject,
                              onTap: () => _showSubjectDetails(context, existingSubject),
                              showActions: true,
                              onEdit: () => _editSubject(existingSubject),
                              onDelete: () => _deleteSubject(existingSubject),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                  
                  // Custom Subjects Section
                  if (customSubjects.isNotEmpty) ...[
                    Text(
                      'Custom Subjects (${customSubjects.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: customSubjects.length * 120.0, // Approximate height per card
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: customSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = customSubjects[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SubjectCard(
                              key: ValueKey('custom_${subject.id}'),
                              subject: subject,
                              onTap: () => _showSubjectDetails(context, subject),
                              showActions: true,
                              onEdit: () => _editSubject(subject),
                              onDelete: () => _deleteSubject(subject),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  // Empty State
                  if (subjectsList.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subjects found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add default subjects or create custom ones',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomSubject,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addMissingDefaults() async {
    setState(() => _isLoading = true);
    
    try {
      await DefaultSubjectsService.addMissingDefaultSubjects();
      ref.invalidate(subjects.subjectListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing default subjects added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding subjects: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Reset to Default Subjects',
      'This will remove all existing subjects and replace them with default ones. This action cannot be undone.',
    );
    
    if (confirmed) {
      setState(() => _isLoading = true);
      
      try {
        await DefaultSubjectsService.resetToDefaultSubjects();
        ref.invalidate(subjects.subjectListProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subjects reset to defaults successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting subjects: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearAllSubjects() async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Clear All Subjects',
      'This will remove all subjects and their attendance records. This action cannot be undone.',
    );
    
    if (confirmed) {
      setState(() => _isLoading = true);
      
      try {
        final subjectsList = ref.read(subjects.subjectListProvider);
        for (final subject in subjectsList) {
          await ref.read(subjects.subjectListProvider.notifier).deleteSubject(subject.id);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All subjects cleared successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing subjects: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addCustomSubject() {
    Navigator.pushNamed(context, '/add-subject');
  }

  void _editSubject(Subject subject) {
    Navigator.pushNamed(
      context,
      '/add-subject',
      arguments: subject,
    );
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Subject',
      'Are you sure you want to delete "${subject.name}"? This will also delete all attendance records for this subject.',
    );
    
    if (confirmed) {
      try {
        await ref.read(subjects.subjectListProvider.notifier).deleteSubject(subject.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${subject.name} deleted successfully'),
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
      }
    }
  }

  void _showSubjectDetails(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(subject.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((subject.description ?? '').isNotEmpty) ...[
              Text('Description: ${subject.description}'),
              const SizedBox(height: 8),
            ],
            Text('Total Classes: ${subject.totalClasses}'),
            Text('Attended Classes: ${subject.attendedClasses}'),
            Text('Attendance: ${subject.attendancePercentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(int.parse((subject.colorHex ?? '#2196F3').replaceFirst('#', '0xff'))),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSubjectStats(BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subject Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Subjects: ${stats['totalSubjects']}'),
            Text('Default Subjects: ${stats['defaultSubjects']}'),
            Text('Custom Subjects: ${stats['customSubjects']}'),
            Text('Missing Defaults: ${stats['missingDefaults']}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  stats['allDefaultsPresent'] ? Icons.check_circle : Icons.warning,
                  color: stats['allDefaultsPresent'] ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  stats['allDefaultsPresent'] 
                      ? 'All default subjects present' 
                      : 'Some default subjects missing',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}
