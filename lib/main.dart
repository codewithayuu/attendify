import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';

import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'models/subject.dart';
import 'screens/home_screen.dart';
import 'screens/add_subject_screen_enhanced.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/manage_subjects_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - app works without it)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase Initialized Successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed (optional): $e');
  }

  // Initialize timezone data
  tz.initializeTimeZones();
  print('✅ Timezone data initialized');

  // Initialize services
  await HiveService.init();
  print('✅ Hive Initialized Successfully (AttendanceAdapter registered)');
  
  // Initialization complete

  await NotificationService.initialize();
  print('✅ Notification Service Initialized Successfully');

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('🚀 Attendance Tracker App Starting...');
  runApp(
    const ProviderScope(
      child: AttendanceTrackerApp(),
    ),
  );
}

class AttendanceTrackerApp extends ConsumerWidget {
  const AttendanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appTheme = ref.watch(appThemeProvider);

    return MaterialApp(
      title: 'Attendance Tracker',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
      routes: {
        '/add-subject': (context) => const AddSubjectScreenEnhanced(),
        '/edit-subject': (context) {
          final subject =
              ModalRoute.of(context)!.settings.arguments as Subject?;
          return AddSubjectScreenEnhanced(subject: subject);
        },
        '/analytics': (context) => const AnalyticsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/manage-subjects': (context) => const ManageSubjectsScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Prevent text scaling
          ),
          child: child!,
        );
      },
    );
  }
}
