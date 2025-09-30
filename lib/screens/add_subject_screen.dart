import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../utils/app_theme.dart';

class AddSubjectScreen extends ConsumerStatefulWidget {
  final Subject? subject; // For editing existing subject

  const AddSubjectScreen({super.key, this.subject});

  @override
  ConsumerState<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends ConsumerState<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedColor = AppTheme.primaryColor.toString();
  bool _isLoading = false;

  final List<String> _colorOptions = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#F44336', // Red
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
    '#E91E63', // Pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _descriptionController.text = widget.subject!.description ?? '';
      _selectedColor = widget.subject!.colorHex ?? AppTheme.primaryColor.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subject != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Subject' : 'Add Subject'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _saveSubject,
              child: Text(
                isEditing ? 'Update' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject name field
              Text(
                'Subject Name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(),
              
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter subject name',
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideX(),
              
              const SizedBox(height: 24),
              
              // Description field
              Text(
                'Description (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideX(),
              
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Enter subject description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideX(),
              
              const SizedBox(height: 24),
              
              // Color selection
              Text(
                'Choose Color',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideX(),
              
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorOptions.map((color) {
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
                                  color: _parseColor(color).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(duration: 300.ms, delay: 500.ms).slideY(),
              
              const SizedBox(height: 32),
              
              // Preview card
              Text(
                'Preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 600.ms).slideX(),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _parseColor(_selectedColor),
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
                              _nameController.text.isEmpty ? 'Subject Name' : _nameController.text,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_descriptionController.text.isNotEmpty)
                              Text(
                                _descriptionController.text,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          '0.0%',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 700.ms).slideY(),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveSubject,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(isEditing ? Icons.update : Icons.save),
                  label: Text(isEditing ? 'Update Subject' : 'Add Subject'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 800.ms).slideY(),
            ],
          ),
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

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final subject = Subject(
        id: widget.subject?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        colorHex: _selectedColor,
        totalClasses: widget.subject?.totalClasses ?? 0,
        attendedClasses: widget.subject?.attendedClasses ?? 0,
        createdAt: widget.subject?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.subject != null) {
        await ref.read(subjectListProvider.notifier).updateSubject(subject);
      } else {
        await ref.read(subjectListProvider.notifier).addSubject(subject);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.subject != null 
                  ? 'Subject updated successfully!' 
                  : 'Subject added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

