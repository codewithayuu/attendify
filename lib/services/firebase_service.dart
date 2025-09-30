import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../models/app_settings.dart';

class FirebaseService {
  // Use lazy getters instead of static variables
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Authentication
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;
  static bool get isSignedIn => _auth.currentUser != null;

  // Subjects sync
  static Future<void> syncSubjectsToCloud(List<Subject> subjects) async {
    if (!isSignedIn) return;

    final userId = currentUser!.uid;
    final batch = _firestore.batch();

    for (final subject in subjects) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subject.id);
      
      batch.set(docRef, {
        'id': subject.id,
        'name': subject.name,
        'totalClasses': subject.totalClasses,
        'attendedClasses': subject.attendedClasses,
        'description': subject.description,
        'createdAt': subject.createdAt,
        'updatedAt': subject.updatedAt,
        'colorHex': subject.colorHex,
      });
    }

    await batch.commit();
  }

  static Future<List<Subject>> syncSubjectsFromCloud() async {
    if (!isSignedIn) return [];

    final userId = currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Subject(
        id: data['id'],
        name: data['name'],
        totalClasses: data['totalClasses'],
        attendedClasses: data['attendedClasses'],
        description: data['description'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        colorHex: data['colorHex'],
      );
    }).toList();
  }

  // Attendance records sync
  static Future<void> syncAttendanceRecordsToCloud(List<AttendanceRecord> records) async {
    if (!isSignedIn) return;

    final userId = currentUser!.uid;
    final batch = _firestore.batch();

    for (final record in records) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc(record.id);
      
      batch.set(docRef, {
        'id': record.id,
        'subjectId': record.subjectId,
        'date': record.date,
        'status': record.status.index,
        'createdAt': record.createdAt,
        'notes': record.notes,
      });
    }

    await batch.commit();
  }

  static Future<List<AttendanceRecord>> syncAttendanceRecordsFromCloud() async {
    if (!isSignedIn) return [];

    final userId = currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AttendanceRecord(
        id: data['id'],
        subjectId: data['subjectId'],
        date: (data['date'] as Timestamp).toDate(),
        status: AttendanceStatus.values[data['status']],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        notes: data['notes'],
      );
    }).toList();
  }

  // Settings sync
  static Future<void> syncSettingsToCloud(AppSettings settings) async {
    if (!isSignedIn) return;

    final userId = currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('default')
        .set({
      'isDarkMode': settings.isDarkMode,
      'enableNotifications': settings.enableNotifications,
      'notificationTime': settings.notificationTime,
      'enableFirebaseSync': settings.enableFirebaseSync,
      'attendanceThreshold': settings.attendanceThreshold,
      'showPercentageOnCards': settings.showPercentageOnCards,
      'defaultSubjectColor': settings.defaultSubjectColor,
      'enableHapticFeedback': settings.enableHapticFeedback,
      'languageCode': settings.languageCode,
      'lastSyncTime': settings.lastSyncTime,
    });
  }

  static Future<AppSettings?> syncSettingsFromCloud() async {
    if (!isSignedIn) return null;

    final userId = currentUser!.uid;
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('default')
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return AppSettings(
      isDarkMode: data['isDarkMode'],
      enableNotifications: data['enableNotifications'],
      notificationTime: data['notificationTime'],
      enableFirebaseSync: data['enableFirebaseSync'],
      attendanceThreshold: data['attendanceThreshold'],
      showPercentageOnCards: data['showPercentageOnCards'],
      defaultSubjectColor: data['defaultSubjectColor'],
      enableHapticFeedback: data['enableHapticFeedback'],
      languageCode: data['languageCode'],
      lastSyncTime: (data['lastSyncTime'] as Timestamp).toDate(),
    );
  }

  // Full sync
  static Future<void> syncAllDataToCloud({
    required List<Subject> subjects,
    required List<AttendanceRecord> records,
    required AppSettings settings,
  }) async {
    if (!isSignedIn) return;

    await Future.wait([
      syncSubjectsToCloud(subjects),
      syncAttendanceRecordsToCloud(records),
      syncSettingsToCloud(settings),
    ]);
  }

  static Future<Map<String, dynamic>?> syncAllDataFromCloud() async {
    if (!isSignedIn) return null;

    final subjects = await syncSubjectsFromCloud();
    final records = await syncAttendanceRecordsFromCloud();
    final settings = await syncSettingsFromCloud();

    return {
      'subjects': subjects,
      'records': records,
      'settings': settings,
    };
  }

  // Real-time listeners
  static Stream<List<Subject>> getSubjectsStream() {
    if (!isSignedIn) return Stream.value([]);

    final userId = currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return Subject(
            id: data['id'],
            name: data['name'],
            totalClasses: data['totalClasses'],
            attendedClasses: data['attendedClasses'],
            description: data['description'],
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            updatedAt: (data['updatedAt'] as Timestamp).toDate(),
            colorHex: data['colorHex'],
          );
        }).toList());
  }

  static Stream<List<AttendanceRecord>> getAttendanceRecordsStream() {
    if (!isSignedIn) return Stream.value([]);

    final userId = currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return AttendanceRecord(
            id: data['id'],
            subjectId: data['subjectId'],
            date: (data['date'] as Timestamp).toDate(),
            status: AttendanceStatus.values[data['status']],
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            notes: data['notes'],
          );
        }).toList());
  }

  // Delete user data
  static Future<void> deleteUserData() async {
    if (!isSignedIn) return;

    final userId = currentUser!.uid;
    final batch = _firestore.batch();

    // Delete subjects
    final subjectsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .get();
    
    for (final doc in subjectsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete attendance records
    final attendanceSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance')
        .get();
    
    for (final doc in attendanceSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete settings
    final settingsDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('default');
    batch.delete(settingsDoc);

    await batch.commit();
  }
}
