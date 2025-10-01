import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/subject_provider.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_record.dart';
import '../services/notification_service.dart';
import '../widgets/subject_card_enhanced.dart';
import 'today_classes_screen.dart';
import '../widgets/attendance_summary_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/empty_state_widget.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const TodayClassesTab(),
    const AnalyticsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: "Today's Classes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/add-subject');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
            )
          : null,
    );
  }
}

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectListProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final todayAttendance = ref.watch(todayAttendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(subjectListProvider.notifier).loadSubjects();
              ref
                  .read(attendanceRecordsProvider.notifier)
                  .loadAttendanceRecords();
            },
          ),
          // Test button for attendance functionality
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showTestDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(subjectListProvider.notifier).loadSubjects();
          await ref
              .read(attendanceRecordsProvider.notifier)
              .loadAttendanceRecords();
        },
        child: CustomScrollView(
          slivers: [
            // Welcome section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ).animate().fadeIn(duration: 300.ms).slideX(),
                    const SizedBox(height: 8),
                    Text(
                      'Track your attendance and stay on top of your studies',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 100.ms)
                        .slideX(),
                  ],
                ),
              ),
            ),

            // Overall stats card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AttendanceSummaryCard(
                  totalSubjects: overallStats['totalSubjects'],
                  totalClasses: overallStats['totalClasses'],
                  attendedClasses: overallStats['attendedClasses'],
                  overallPercentage: overallStats['percentage'],
                ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuickActions(
                  todayAttendance: todayAttendance,
                ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Subjects section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Subjects',
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 400.ms)
                        .slideX(),
                    if (subjects.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/add-subject');
                        },
                        child: const Text('Add New'),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 500.ms)
                          .slideX(),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Subjects list
            if (subjects.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.school_outlined,
                  title: 'No Subjects Yet',
                  subtitle:
                      'Add your first subject to start tracking attendance',
                  actionText: 'Add Subject',
                  onAction: () {
                    Navigator.pushNamed(context, '/add-subject');
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subject = subjects[index];
                      return SubjectCardEnhanced(
                        key: ValueKey(subject.id),
                        subject: subject,
                        onTap: () {
                          // Navigate to subject details
                        },
                        showScheduleInfo: true,
                      );
                    },
                    childCount: subjects.length,
                    // Add cache extent for better performance
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                  ),
                ),
              ),

            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnalyticsScreen();
  }
}

class TodayClassesTab extends StatelessWidget {
  const TodayClassesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TodayClassesScreen();
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}

// Test dialog for verifying core functionality
void _showTestDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('🧪 Test Core Features'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () async {
              // Test 1: Add test attendance record
              try {
                final subjects = ref.read(subjectListProvider);
                if (subjects.isNotEmpty) {
                  final testSubject = subjects.first;
                  await ref
                      .read(attendanceRecordsProvider.notifier)
                      .markTodayAttendance(
                        testSubject.id,
                        AttendanceStatus.Present,
                      );
                  print('✅ Test Attendance Added for ${testSubject.name}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '✅ Test attendance added for ${testSubject.name}')),
                  );
                } else {
                  print('⚠️ No subjects available for testing');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            '⚠️ No subjects available. Add a subject first.')),
                  );
                }
              } catch (e) {
                print('❌ Error adding test attendance: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error: $e')),
                );
              }
            },
            child: const Text('Test Add Attendance'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              // Test 2: Fetch attendance records
              try {
                final records = ref.read(attendanceRecordsProvider);
                print('📊 Total attendance records: ${records.length}');
                for (var record in records.take(3)) {
                  print('📅 ${record.date} - Status: ${record.status}');
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '📊 Found ${records.length} attendance records')),
                );
              } catch (e) {
                print('❌ Error fetching attendance: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error: $e')),
                );
              }
            },
            child: const Text('Test Fetch Attendance'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              // Test 3: Test notifications
              try {
                final subjects = ref.read(subjectListProvider);
                if (subjects.isNotEmpty) {
                  final testSubject = subjects.first;
                  await NotificationService.sendAttendanceMarkedConfirmation(
                    testSubject,
                    AttendanceStatus.Present,
                  );
                  print('✅ Test notification sent for ${testSubject.name}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '✅ Test notification sent for ${testSubject.name}')),
                  );
                } else {
                  print('⚠️ No subjects available for testing notifications');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            '⚠️ No subjects available. Add a subject first.')),
                  );
                }
              } catch (e) {
                print('❌ Error sending notification: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error: $e')),
                );
              }
            },
            child: const Text('Test Notifications'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
