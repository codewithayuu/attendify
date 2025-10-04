import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/hive_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

// Settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(HiveService.getSettings());

  Future<void> updateSettings(AppSettings newSettings) async {
    await HiveService.updateSettings(newSettings);
    state = newSettings;

    // Update notification settings (with error handling)
    try {
      await NotificationService.updateNotificationSettings(newSettings);
    } catch (e) {
      print('⚠️ Failed to update notification settings: $e');
    }

    // Sync to cloud if enabled (with error handling)
    if (newSettings.enableFirebaseSync && FirebaseService.isSignedIn) {
      try {
        await FirebaseService.syncSettingsToCloud(newSettings);
      } catch (e) {
        print('⚠️ Failed to sync settings to cloud: $e');
      }
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

  Future<void> toggleShowPercentageOnCards() async {
    final newSettings =
        state.copyWith(showPercentageOnCards: !state.showPercentageOnCards);
    await updateSettings(newSettings);
  }

  Future<void> updateDefaultSubjectColor(String color) async {
    final newSettings = state.copyWith(defaultSubjectColor: color);
    await updateSettings(newSettings);
  }

  Future<void> toggleHapticFeedback() async {
    final newSettings =
        state.copyWith(enableHapticFeedback: !state.enableHapticFeedback);
    await updateSettings(newSettings);
  }

  Future<void> updateLanguageCode(String languageCode) async {
    final newSettings = state.copyWith(languageCode: languageCode);
    await updateSettings(newSettings);
  }

  Future<void> updateLastSyncTime(DateTime syncTime) async {
    final newSettings = state.copyWith(lastSyncTime: syncTime);
    await updateSettings(newSettings);
  }

  Future<void> updateSemesterStart(DateTime? semesterStart) async {
    final newSettings = state.copyWith(semesterStart: semesterStart);
    await updateSettings(newSettings);
  }

  Future<void> updateSemesterEnd(DateTime? semesterEnd) async {
    final newSettings = state.copyWith(semesterEnd: semesterEnd);
    await updateSettings(newSettings);
  }

  Future<void> updateDefaultRequiredPercent(
      double defaultRequiredPercent) async {
    final newSettings =
        state.copyWith(defaultRequiredPercent: defaultRequiredPercent);
    await updateSettings(newSettings);
  }

  // Sync settings with cloud
  Future<void> syncWithCloud() async {
    if (!FirebaseService.isSignedIn) return;

    try {
      final cloudSettings = await FirebaseService.syncSettingsFromCloud();
      if (cloudSettings != null) {
        await updateSettings(cloudSettings);
      }
    } catch (e) {
      print('Settings sync error: $e');
    }
  }

  // Reset to default settings
  Future<void> resetToDefaults() async {
    final defaultSettings = AppSettings();
    await updateSettings(defaultSettings);
  }
}

// Theme provider
final themeProvider = Provider<AppSettings>((ref) {
  return ref.watch(settingsProvider);
});

// Notification settings provider
final notificationSettingsProvider = Provider<Map<String, dynamic>>((ref) {
  final settings = ref.watch(settingsProvider);

  return {
    'enabled': settings.enableNotifications,
    'time': settings.notificationTime,
    'threshold': settings.attendanceThreshold,
  };
});

// Firebase sync status provider
final firebaseSyncStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final settings = ref.watch(settingsProvider);

  return {
    'enabled': settings.enableFirebaseSync,
    'signedIn': FirebaseService.isSignedIn,
    'lastSync': settings.lastSyncTime,
  };
});

// UI preferences provider
final uiPreferencesProvider = Provider<Map<String, dynamic>>((ref) {
  final settings = ref.watch(settingsProvider);

  return {
    'darkMode': settings.isDarkMode,
    'showPercentageOnCards': settings.showPercentageOnCards,
    'defaultSubjectColor': settings.defaultSubjectColor,
    'hapticFeedback': settings.enableHapticFeedback,
    'language': settings.languageCode,
  };
});

// Semester settings provider
final semesterSettingsProvider = Provider<Map<String, dynamic>>((ref) {
  final settings = ref.watch(settingsProvider);

  return {
    'semesterStart': settings.semesterStart,
    'semesterEnd': settings.semesterEnd,
    'defaultRequiredPercent': settings.defaultRequiredPercent,
  };
});
