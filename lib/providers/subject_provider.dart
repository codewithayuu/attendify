import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../models/app_settings.dart';
import '../services/hive_service.dart';
import '../services/firebase_service.dart';

// Subject list provider
final subjectListProvider =
    StateNotifierProvider<SubjectListNotifier, List<Subject>>((ref) {
  return SubjectListNotifier();
});

class SubjectListNotifier extends StateNotifier<List<Subject>> {
  SubjectListNotifier() : super([]) {
    loadSubjects();
  }

  // Load subjects from local database
  Future<void> loadSubjects() async {
    final subjects = HiveService.getAllSubjects();
    state = subjects;
    // If empty, do NOT repopulate here; defaults are handled only at init
  }

  // Add new subject
  Future<void> addSubject(Subject subject) async {
    await HiveService.addSubject(subject);
    state = [...state, subject];

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncSubjectsToCloud(state);
    }
  }

  // Update subject
  Future<void> updateSubject(Subject subject) async {
    await HiveService.updateSubject(subject);
    state = state.map((s) => s.id == subject.id ? subject : s).toList();

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncSubjectsToCloud(state);
    }
  }

  // Delete subject
  Future<void> deleteSubject(String subjectId) async {
    await HiveService.deleteSubject(subjectId);
    state = state.where((s) => s.id != subjectId).toList();

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncSubjectsToCloud(state);
    }
  }

  // Batch delete subjects
  Future<void> deleteSubjectsBatch(Iterable<String> subjectIds) async {
    // Delete exact ids only; no other data manipulation
    for (final id in subjectIds) {
      await HiveService.deleteSubject(id);
    }
    final idSet = subjectIds.toSet();
    state = state.where((s) => !idSet.contains(s.id)).toList();

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncSubjectsToCloud(state);
    }
  }

  // Mark attendance for a subject
  Future<void> markAttendance(String subjectId, bool isPresent) async {
    final subjectIndex = state.indexWhere((s) => s.id == subjectId);
    if (subjectIndex == -1) return;

    final subject = state[subjectIndex];
    final updatedSubject = subject.markAttendance(isPresent: isPresent);

    await HiveService.updateSubject(updatedSubject);
    state = state.map((s) => s.id == subjectId ? updatedSubject : s).toList();

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncSubjectsToCloud(state);
    }
  }

  // Undo last attendance for a subject
  Future<void> undoLastAttendance(String subjectId, bool wasPresent) async {
    final subjectIndex = state.indexWhere((s) => s.id == subjectId);
    if (subjectIndex == -1) return;

    final subject = state[subjectIndex];
    final updatedSubject = subject.undoLastAttendance(wasPresent: wasPresent);

    await HiveService.updateSubject(updatedSubject);
    state = state.map((s) => s.id == subjectId ? updatedSubject : s).toList();

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncSubjectsToCloud(state);
    }
  }

  // Adjust attended count only (do not change totalClasses)
  Future<void> adjustAttendedOnly(String subjectId, int delta) async {
    final subjectIndex = state.indexWhere((s) => s.id == subjectId);
    if (subjectIndex == -1 || delta == 0) return;

    final subject = state[subjectIndex];
    final nextAttended =
        (subject.attendedClasses + delta).clamp(0, subject.totalClasses);
    final updatedSubject = subject.copyWith(attendedClasses: nextAttended);

    await HiveService.updateSubject(updatedSubject);
    state = state.map((s) => s.id == subjectId ? updatedSubject : s).toList();

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncSubjectsToCloud(state);
    }
  }

  // Sync with cloud
  Future<void> syncWithCloud() async {
    if (!FirebaseService.isSignedIn) return;

    try {
      final cloudSubjects = await FirebaseService.syncSubjectsFromCloud();
      if (cloudSubjects.isNotEmpty) {
        // Merge local and cloud data (cloud takes precedence for conflicts)
        final localSubjects = {for (var s in state) s.id: s};

        // Update local subjects with cloud data
        for (final cloudSubject in cloudSubjects) {
          await HiveService.updateSubject(cloudSubject);
        }

        // Add new subjects from cloud
        for (final cloudSubject in cloudSubjects) {
          if (!localSubjects.containsKey(cloudSubject.id)) {
            await HiveService.addSubject(cloudSubject);
          }
        }

        state = cloudSubjects;
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }
}

// Individual subject provider
final subjectProvider = Provider.family<Subject?, String>((ref, subjectId) {
  final subjects = ref.watch(subjectListProvider);
  return subjects.firstWhere((s) => s.id == subjectId,
      orElse: () => throw StateError('Subject not found'));
});

// Subjects with low attendance provider
final lowAttendanceSubjectsProvider = Provider<List<Subject>>((ref) {
  final subjects = ref.watch(subjectListProvider);
  final settings = ref.watch(settingsProvider);

  return subjects
      .where((s) => s.attendancePercentage < settings.attendanceThreshold)
      .toList();
});

// Overall attendance statistics provider
final overallStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final subjects = ref.watch(subjectListProvider);

  if (subjects.isEmpty) {
    return {
      'totalClasses': 0,
      'attendedClasses': 0,
      'percentage': 0.0,
      'totalSubjects': 0,
    };
  }

  final totalClasses = subjects.fold(0, (sum, s) => sum + s.totalClasses);
  final attendedClasses = subjects.fold(0, (sum, s) => sum + s.attendedClasses);
  final percentage =
      totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0.0;

  return {
    'totalClasses': totalClasses,
    'attendedClasses': attendedClasses,
    'percentage': percentage,
    'totalSubjects': subjects.length,
  };
});

// Settings provider (imported from settings_provider.dart)
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(HiveService.getSettings());

  Future<void> updateSettings(AppSettings newSettings) async {
    await HiveService.updateSettings(newSettings);
    state = newSettings;

    // Sync to cloud if enabled
    if (newSettings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncSettingsToCloud(newSettings);
    }
  }

  Future<void> toggleDarkMode() async {
    final newSettings = state.copyWith(isDarkMode: !state.isDarkMode);
    await updateSettings(newSettings);
  }

  Future<void> toggleNotifications() async {
    final newSettings =
        state.copyWith(enableNotifications: !state.enableNotifications);
    await updateSettings(newSettings);
  }

  Future<void> toggleFirebaseSync() async {
    final newSettings =
        state.copyWith(enableFirebaseSync: !state.enableFirebaseSync);
    await updateSettings(newSettings);
  }

  Future<void> updateNotificationTime(String time) async {
    final newSettings = state.copyWith(notificationTime: time);
    await updateSettings(newSettings);
  }

  Future<void> updateAttendanceThreshold(double threshold) async {
    final newSettings = state.copyWith(attendanceThreshold: threshold);
    await updateSettings(newSettings);
  }
}
