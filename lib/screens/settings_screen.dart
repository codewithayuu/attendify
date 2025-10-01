import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _buildSettingsContent(context, ref, settings),
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetRef ref, settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Appearance section
        _buildSectionHeader(context, 'Appearance')
            .animate()
            .fadeIn(duration: 300.ms)
            .slideX(),

        _buildThemeModeTile(context, ref, settings)
            .animate()
            .fadeIn(duration: 300.ms, delay: 100.ms)
            .slideX(),

        _buildShowPercentageTile(context, ref, settings)
            .animate()
            .fadeIn(duration: 300.ms, delay: 200.ms)
            .slideX(),

        _buildDefaultColorTile(context, ref, settings)
            .animate()
            .fadeIn(duration: 300.ms, delay: 300.ms)
            .slideX(),

        const SizedBox(height: 24),

        // Notifications section
        _buildSectionHeader(context, 'Notifications')
            .animate()
            .fadeIn(duration: 300.ms, delay: 400.ms)
            .slideX(),

        _buildNotificationToggleTile(context, ref, settings)
            .animate()
            .fadeIn(duration: 300.ms, delay: 500.ms)
            .slideX(),

        if (settings.enableNotifications)
          _buildNotificationTimeTile(context, ref, settings)
              .animate()
              .fadeIn(duration: 300.ms, delay: 600.ms)
              .slideX(),

        const SizedBox(height: 24),

        // Attendance section
        _buildSectionHeader(context, 'Semester & Attendance')
            .animate()
            .fadeIn(duration: 300.ms, delay: 700.ms)
            .slideX(),

        _buildSemesterStartTile(context, ref, settings)
            .animate()
            .fadeIn(duration: 300.ms, delay: 750.ms)
            .slideX(),

        _buildSemesterEndTile(context, ref, settings)
            .animate()
            .fadeIn(duration: 300.ms, delay: 800.ms)
            .slideX(),

        _buildGlobalThresholdTile(context, ref, settings)
            .animate()
            .fadeIn(duration: 300.ms, delay: 850.ms)
            .slideX(),

        const SizedBox(height: 24),

        // Sync section
        _buildSectionHeader(context, 'Sync & Backup')
            .animate()
            .fadeIn(duration: 300.ms, delay: 900.ms)
            .slideX(),

        _buildFirebaseSyncTile(context, ref, settings)
            .animate()
            .fadeIn(duration: 300.ms, delay: 1000.ms)
            .slideX(),

        const SizedBox(height: 24),

        // Subjects section
        _buildSectionHeader(context, 'Subjects')
            .animate()
            .fadeIn(duration: 300.ms, delay: 1100.ms)
            .slideX(),

        _buildManageSubjectsTile(context)
            .animate()
            .fadeIn(duration: 300.ms, delay: 1200.ms)
            .slideX(),

        const SizedBox(height: 24),

        // Data section
        _buildSectionHeader(context, 'Data Management')
            .animate()
            .fadeIn(duration: 300.ms, delay: 1300.ms)
            .slideX(),

        _buildExportDataTile(context, ref)
            .animate()
            .fadeIn(duration: 300.ms, delay: 1400.ms)
            .slideX(),

        _buildImportDataTile(context, ref)
            .animate()
            .fadeIn(duration: 300.ms, delay: 1500.ms)
            .slideX(),

        _buildClearDataTile(context, ref)
            .animate()
            .fadeIn(duration: 300.ms, delay: 1600.ms)
            .slideX(),

        const SizedBox(height: 24),

        // About section
        _buildSectionHeader(context, 'About')
            .animate()
            .fadeIn(duration: 300.ms, delay: 1700.ms)
            .slideX(),

        _buildAboutTile(context)
            .animate()
            .fadeIn(duration: 300.ms, delay: 1800.ms)
            .slideX(),

        const SizedBox(height: 100), // Bottom padding
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _buildThemeModeTile(BuildContext context, WidgetRef ref, settings) {
    final themeMode = ref.watch(themeModeProvider);

    return Card(
      child: ListTile(
        title: const Text('Theme Mode'),
        subtitle: Text(_getThemeModeText(themeMode)),
        leading: Icon(_getThemeModeIcon(themeMode)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showThemeModeDialog(context, ref),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light Mode'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).toggleTheme(false);
                  ref.read(settingsProvider.notifier).toggleDarkMode();
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Mode'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).toggleTheme(true);
                  ref.read(settingsProvider.notifier).toggleDarkMode();
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              subtitle: const Text('Follow system theme'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setSystemTheme();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildShowPercentageTile(
      BuildContext context, WidgetRef ref, settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Show Percentage on Cards'),
        subtitle: const Text('Display attendance percentage on subject cards'),
        value: settings.showPercentageOnCards,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).toggleShowPercentageOnCards();
        },
        secondary: const Icon(Icons.percent),
      ),
    );
  }

  Widget _buildDefaultColorTile(BuildContext context, WidgetRef ref, settings) {
    return Card(
      child: ListTile(
        title: const Text('Default Subject Color'),
        subtitle: const Text('Choose default color for new subjects'),
        leading: const Icon(Icons.palette),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _parseColor(settings.defaultSubjectColor),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
        onTap: () {
          _showColorPicker(context, ref, settings);
        },
      ),
    );
  }

  Widget _buildNotificationToggleTile(
      BuildContext context, WidgetRef ref, settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Enable Notifications'),
        subtitle: const Text('Receive daily attendance reminders'),
        value: settings.enableNotifications,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).toggleNotifications();
        },
        secondary: const Icon(Icons.notifications),
      ),
    );
  }

  Widget _buildNotificationTimeTile(
      BuildContext context, WidgetRef ref, settings) {
    return Card(
      child: ListTile(
        title: const Text('Notification Time'),
        subtitle: Text('Daily reminder at ${settings.notificationTime}'),
        leading: const Icon(Icons.schedule),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showTimePicker(context, ref, settings);
        },
      ),
    );
  }

  Widget _buildSemesterStartTile(
      BuildContext context, WidgetRef ref, settings) {
    final semesterStart = settings.semesterStart;
    return Card(
      child: ListTile(
        title: const Text('Semester Start Date'),
        subtitle: Text(semesterStart != null 
            ? '${semesterStart.day}/${semesterStart.month}/${semesterStart.year}'
            : 'Not set'),
        leading: const Icon(Icons.calendar_today),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showSemesterStartPicker(context, ref, settings);
        },
      ),
    );
  }

  Widget _buildSemesterEndTile(
      BuildContext context, WidgetRef ref, settings) {
    final semesterEnd = settings.semesterEnd;
    return Card(
      child: ListTile(
        title: const Text('Semester End Date'),
        subtitle: Text(semesterEnd != null 
            ? '${semesterEnd.day}/${semesterEnd.month}/${semesterEnd.year}'
            : 'Not set'),
        leading: const Icon(Icons.calendar_today),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showSemesterEndPicker(context, ref, settings);
        },
      ),
    );
  }

  Widget _buildGlobalThresholdTile(
      BuildContext context, WidgetRef ref, settings) {
    return Card(
      child: ListTile(
        title: const Text('Global Attendance Threshold'),
        subtitle: Text('Default required percentage: ${settings.defaultRequiredPercent}%'),
        leading: const Icon(Icons.percent),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showGlobalThresholdPicker(context, ref, settings);
        },
      ),
    );
  }


  Widget _buildFirebaseSyncTile(BuildContext context, WidgetRef ref, settings) {
    return const Card(
      child: SwitchListTile(
        title: Text('Cloud Sync'),
        subtitle: Text('Firebase sync (Coming soon)'),
        value: false, // Disabled for now
        onChanged: null, // Disabled for now
        secondary: Icon(Icons.cloud_sync),
      ),
    );
  }

  Widget _buildExportDataTile(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: const Text('Export Data'),
        subtitle: const Text('Export your data to CSV or Excel'),
        leading: const Icon(Icons.download),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Implement export functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export functionality coming soon!')),
          );
        },
      ),
    );
  }

  Widget _buildImportDataTile(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: const Text('Import Data'),
        subtitle: const Text('Import data from CSV or Excel'),
        leading: const Icon(Icons.upload),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Implement import functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import functionality coming soon!')),
          );
        },
      ),
    );
  }

  Widget _buildClearDataTile(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: const Text('Clear All Data'),
        subtitle: const Text('Delete all subjects and attendance records'),
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showClearDataDialog(context, ref);
        },
      ),
    );
  }

  Widget _buildManageSubjectsTile(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Manage Subjects'),
        subtitle: const Text('Add, edit, or remove subjects'),
        leading: const Icon(Icons.school),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(context, '/manage-subjects');
        },
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('About'),
        subtitle: const Text('Attendance Tracker v1.0.0'),
        leading: const Icon(Icons.info),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showAboutDialog(context);
        },
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

  void _showColorPicker(BuildContext context, WidgetRef ref, settings) {
    final colors = [
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Default Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = settings.defaultSubjectColor == color;
            return GestureDetector(
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .updateDefaultSubjectColor(color);
                Navigator.of(context).pop();
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
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(BuildContext context, WidgetRef ref, settings) {
    final timeParts = settings.notificationTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    showTimePicker(
      context: context,
      initialTime: initialTime,
    ).then((time) {
      if (time != null) {
        final timeString =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        ref.read(settingsProvider.notifier).updateNotificationTime(timeString);
      }
    });
  }

  void _showThresholdPicker(BuildContext context, WidgetRef ref, settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current threshold: ${settings.attendanceThreshold}%'),
            const SizedBox(height: 16),
            Slider(
              value: settings.attendanceThreshold,
              min: 50,
              max: 95,
              divisions: 9,
              label: '${settings.attendanceThreshold}%',
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .updateAttendanceThreshold(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSignInDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text(
            'Please sign in to enable cloud sync. This feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'Are you sure you want to delete all subjects and attendance records? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement clear data functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Clear data functionality coming soon!')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Attendance Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48),
      children: [
        const Text(
            'A comprehensive attendance tracking app with offline-first approach.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Offline-first data storage'),
        const Text('• Beautiful charts and analytics'),
        const Text('• Daily reminders'),
        const Text('• Dark mode support'),
        const Text('• Data export/import'),
      ],
    );
  }

  void _showSemesterStartPicker(BuildContext context, WidgetRef ref, settings) {
    final currentDate = settings.semesterStart ?? DateTime.now();
    showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        ref.read(settingsProvider.notifier).updateSemesterStart(date);
      }
    });
  }

  void _showSemesterEndPicker(BuildContext context, WidgetRef ref, settings) {
    final currentDate = settings.semesterEnd ?? DateTime.now().add(const Duration(days: 90));
    final semesterStart = settings.semesterStart ?? DateTime.now();
    
    showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: semesterStart,
      lastDate: DateTime.now().add(const Duration(days: 500)),
    ).then((date) {
      if (date != null) {
        ref.read(settingsProvider.notifier).updateSemesterEnd(date);
      }
    });
  }

  void _showGlobalThresholdPicker(BuildContext context, WidgetRef ref, settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Global Attendance Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current threshold: ${settings.defaultRequiredPercent}%'),
            const SizedBox(height: 16),
            Slider(
              value: settings.defaultRequiredPercent,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${settings.defaultRequiredPercent}%',
              onChanged: (value) {
                ref.read(settingsProvider.notifier).updateDefaultRequiredPercent(value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'This is the default required attendance percentage for all subjects. Individual subjects can override this value.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
