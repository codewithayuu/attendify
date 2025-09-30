import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 3)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  bool enableNotifications;

  @HiveField(2)
  String notificationTime; // Format: "HH:mm"

  @HiveField(3)
  bool enableFirebaseSync;

  @HiveField(4)
  double attendanceThreshold; // Default: 75.0

  @HiveField(5)
  bool showPercentageOnCards;

  @HiveField(6)
  String defaultSubjectColor;

  @HiveField(7)
  bool enableHapticFeedback;

  @HiveField(8)
  String languageCode;

  @HiveField(9)
  DateTime lastSyncTime;

  @HiveField(10)
  bool showDefaultSubjects;

  AppSettings({
    this.isDarkMode = false,
    this.enableNotifications = true,
    this.notificationTime = '09:00',
    this.enableFirebaseSync = false,
    this.attendanceThreshold = 75.0,
    this.showPercentageOnCards = true,
    this.defaultSubjectColor = '#2196F3',
    this.enableHapticFeedback = true,
    this.languageCode = 'en',
    DateTime? lastSyncTime,
    this.showDefaultSubjects = true,
  }) : lastSyncTime = lastSyncTime ?? DateTime.now();

  // Copy with method for updates
  AppSettings copyWith({
    bool? isDarkMode,
    bool? enableNotifications,
    String? notificationTime,
    bool? enableFirebaseSync,
    double? attendanceThreshold,
    bool? showPercentageOnCards,
    String? defaultSubjectColor,
    bool? enableHapticFeedback,
    String? languageCode,
    DateTime? lastSyncTime,
    bool? showDefaultSubjects,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notificationTime: notificationTime ?? this.notificationTime,
      enableFirebaseSync: enableFirebaseSync ?? this.enableFirebaseSync,
      attendanceThreshold: attendanceThreshold ?? this.attendanceThreshold,
      showPercentageOnCards: showPercentageOnCards ?? this.showPercentageOnCards,
      defaultSubjectColor: defaultSubjectColor ?? this.defaultSubjectColor,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      languageCode: languageCode ?? this.languageCode,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      showDefaultSubjects: showDefaultSubjects ?? this.showDefaultSubjects,
    );
  }

  // Parse notification time to DateTime
  DateTime get notificationDateTime {
    final timeParts = notificationTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Check if notifications should be sent
  bool shouldSendNotification() {
    if (!enableNotifications) return false;
    
    final now = DateTime.now();
    final notificationTime = notificationDateTime;
    
    // Check if it's the notification time (within 1 minute)
    final timeDifference = now.difference(notificationTime).inMinutes.abs();
    return timeDifference <= 1;
  }

  // Save to SharedPreferences for quick access
  Future<void> saveToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setBool('enableNotifications', enableNotifications);
    await prefs.setString('notificationTime', notificationTime);
    await prefs.setBool('enableFirebaseSync', enableFirebaseSync);
    await prefs.setDouble('attendanceThreshold', attendanceThreshold);
    await prefs.setBool('showPercentageOnCards', showPercentageOnCards);
    await prefs.setString('defaultSubjectColor', defaultSubjectColor);
    await prefs.setBool('enableHapticFeedback', enableHapticFeedback);
    await prefs.setString('languageCode', languageCode);
    await prefs.setString('lastSyncTime', lastSyncTime.toIso8601String());
  }

  // Load from SharedPreferences
  static Future<AppSettings> loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    return AppSettings(
      isDarkMode: prefs.getBool('isDarkMode') ?? false,
      enableNotifications: prefs.getBool('enableNotifications') ?? true,
      notificationTime: prefs.getString('notificationTime') ?? '09:00',
      enableFirebaseSync: prefs.getBool('enableFirebaseSync') ?? false,
      attendanceThreshold: prefs.getDouble('attendanceThreshold') ?? 75.0,
      showPercentageOnCards: prefs.getBool('showPercentageOnCards') ?? true,
      defaultSubjectColor: prefs.getString('defaultSubjectColor') ?? '#2196F3',
      enableHapticFeedback: prefs.getBool('enableHapticFeedback') ?? true,
      languageCode: prefs.getString('languageCode') ?? 'en',
      lastSyncTime: prefs.getString('lastSyncTime') != null
          ? DateTime.parse(prefs.getString('lastSyncTime')!)
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppSettings(isDarkMode: $isDarkMode, enableNotifications: $enableNotifications, notificationTime: $notificationTime)';
  }
}
