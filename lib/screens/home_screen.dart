import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/subject_provider.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_record.dart';
import '../models/subject.dart';
import '../services/notification_service.dart';
import '../widgets/subject_card_enhanced.dart';
import 'today_classes_screen.dart';
import '../widgets/attendance_summary_card.dart';
import '../widgets/upcoming_classes.dart';
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
      bottomNavigationBar: _AttendifyNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
    final selection = ref.watch(_selectionProvider);
    final subjects = ref.watch(subjectListProvider);
    final overallStats = ref.watch(overallStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: selection.isSelecting
            ? Text('${selection.selectedIds.length} selected')
            : const Text('Attendify'),
        leading: selection.isSelecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => ref.read(_selectionProvider.notifier).clear(),
              )
            : null,
        actions: [
          if (selection.isSelecting) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select all',
              onPressed: () =>
                  ref.read(_selectionProvider.notifier).selectAll(subjects),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete selected',
              onPressed: selection.selectedIds.isEmpty
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Subjects'),
                          content: Text(
                              'Delete ${selection.selectedIds.length} selected subject(s)? This will also remove their attendance records.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(subjectListProvider.notifier)
                            .deleteSubjectsBatch(selection.selectedIds);
                        ref.read(_selectionProvider.notifier).clear();
                      }
                    },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(subjectListProvider.notifier).loadSubjects();
                ref
                    .read(attendanceRecordsProvider.notifier)
                    .loadAttendanceRecords();
              },
            ),
          ]
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
                child: const UpcomingClasses()
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 300.ms)
                    .slideY(),
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
                      final isSelected =
                          selection.selectedIds.contains(subject.id);
                      return ProviderScope(
                        overrides: const [
                          // Override providers for this specific card to avoid global rebuilds
                        ],
                        child: GestureDetector(
                          onLongPress: () => ref
                              .read(_selectionProvider.notifier)
                              .startOrToggle(subject.id),
                          onTap: () {
                            if (selection.isSelecting) {
                              ref
                                  .read(_selectionProvider.notifier)
                                  .toggle(subject.id);
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/edit-subject',
                                arguments: subject,
                              );
                            }
                          },
                          child: Stack(
                            children: [
                              SubjectCardEnhanced(
                                key: ValueKey(subject.id),
                                subject: subject,
                                showScheduleInfo: true,
                              ),
                              if (isSelected)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: isSelected
                                      ? const Icon(Icons.check_circle,
                                          key: ValueKey('sel'),
                                          color: Colors.green)
                                      : const SizedBox.shrink(
                                          key: ValueKey('nosel')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: subjects.length,
                    // Performance optimizations
                    addAutomaticKeepAlives:
                        false, // Don't keep alive for better memory usage
                    addRepaintBoundaries:
                        true, // Add repaint boundaries for better performance
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

// ------------------ Selection State ------------------

class _SelectionState {
  final Set<String> selectedIds;
  final bool isSelecting;
  const _SelectionState(
      {this.selectedIds = const {}, this.isSelecting = false});

  _SelectionState copyWith({Set<String>? selectedIds, bool? isSelecting}) =>
      _SelectionState(
        selectedIds: selectedIds ?? this.selectedIds,
        isSelecting: isSelecting ?? this.isSelecting,
      );
}

class _SelectionNotifier extends StateNotifier<_SelectionState> {
  _SelectionNotifier() : super(const _SelectionState());

  void startOrToggle(String id) {
    if (!state.isSelecting) {
      state = _SelectionState(selectedIds: {id}, isSelecting: true);
    } else {
      toggle(id);
    }
  }

  void toggle(String id) {
    final set = {...state.selectedIds};
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    state = state.copyWith(selectedIds: set, isSelecting: set.isNotEmpty);
  }

  void selectAll(List<Subject> subjects) {
    state = state.copyWith(
      selectedIds: subjects.map((s) => s.id).toSet(),
      isSelecting: true,
    );
  }

  void clear() {
    state = const _SelectionState();
  }
}

final _selectionProvider =
    StateNotifierProvider<_SelectionNotifier, _SelectionState>((ref) {
  return _SelectionNotifier();
});

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

// Test dialog removed for production

// ------------------ Bottom Navigation ------------------

class _AttendifyNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _AttendifyNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.9),
        border:
            Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.transparent,
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today),
              label: "Today",
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
