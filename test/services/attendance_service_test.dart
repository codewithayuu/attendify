import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/services/attendance_service.dart';
import 'package:attendance_tracker/models/subject.dart';
import 'package:attendance_tracker/models/app_settings.dart';

void main() {
  group('AttendanceService', () {
    group('requiredAttended', () {
      test('should calculate required attended classes correctly', () {
        expect(AttendanceService.requiredAttended(75, 10), 8);
        expect(AttendanceService.requiredAttended(75, 20), 15);
        expect(AttendanceService.requiredAttended(80, 10), 8);
        expect(AttendanceService.requiredAttended(70, 10), 7);
        expect(AttendanceService.requiredAttended(100, 10), 10);
        expect(AttendanceService.requiredAttended(0, 10), 0);
      });

      test('should handle edge cases', () {
        expect(AttendanceService.requiredAttended(75, 0), 0);
        expect(AttendanceService.requiredAttended(33.33, 3), 1);
        expect(AttendanceService.requiredAttended(66.67, 3), 3);
      });
    });

    group('classesNeeded', () {
      test('should calculate classes needed correctly', () {
        expect(AttendanceService.classesNeeded(5, 75, 10), 3); // need 3 more
        expect(AttendanceService.classesNeeded(8, 75, 10),
            0); // already met requirement
        expect(AttendanceService.classesNeeded(7, 75, 10), 1); // need 1 more
        expect(AttendanceService.classesNeeded(10, 75, 10),
            0); // exceeded requirement
        expect(
            AttendanceService.classesNeeded(0, 75, 10), 8); // need all classes
      });

      test('should handle edge cases', () {
        expect(AttendanceService.classesNeeded(0, 75, 0), 0);
        expect(AttendanceService.classesNeeded(5, 100, 10), 5);
        expect(AttendanceService.classesNeeded(5, 0, 10), 0);
      });
    });

    group('getRequiredPercentage', () {
      test('should return subject-specific percentage when available', () {
        final subject = Subject(
          name: 'Test Subject',
          requiredPercent: 80.0,
        );
        final settings = AppSettings(defaultRequiredPercent: 75.0);

        expect(
            AttendanceService.getRequiredPercentage(subject, settings), 80.0);
      });

      test('should return default percentage when subject-specific is null',
          () {
        final subject = Subject(
          name: 'Test Subject',
          requiredPercent: null,
        );
        final settings = AppSettings(defaultRequiredPercent: 75.0);

        expect(
            AttendanceService.getRequiredPercentage(subject, settings), 75.0);
      });
    });

    group('getAttendanceStats', () {
      test('should calculate attendance statistics correctly', () {
        final subject = Subject(
          name: 'Test Subject',
          totalClasses: 10,
          attendedClasses: 7,
          requiredPercent: 75.0,
        );
        final settings = AppSettings(defaultRequiredPercent: 80.0);

        final stats = AttendanceService.getAttendanceStats(subject, settings);

        expect(stats['totalClasses'], 10);
        expect(stats['attendedClasses'], 7);
        expect(stats['currentPercentage'], 70.0);
        expect(stats['requiredPercentage'], 75.0);
        expect(stats['requiredAttended'], 8);
        expect(stats['classesNeeded'], 1);
        expect(stats['isOnTrack'], false);
        expect(stats['canStillMeetRequirement'], true);
      });

      test('should handle subject on track', () {
        final subject = Subject(
          name: 'Test Subject',
          totalClasses: 10,
          attendedClasses: 8,
          requiredPercent: 75.0,
        );
        final settings = AppSettings(defaultRequiredPercent: 80.0);

        final stats = AttendanceService.getAttendanceStats(subject, settings);

        expect(stats['isOnTrack'], true);
        expect(stats['classesNeeded'], 0);
      });
    });

    group('getAttendanceRecommendations', () {
      test('should provide appropriate recommendations for on-track subject',
          () {
        final subject = Subject(
          name: 'Test Subject',
          totalClasses: 10,
          attendedClasses: 8,
          requiredPercent: 75.0,
        );
        final settings = AppSettings(defaultRequiredPercent: 80.0);

        final recommendations =
            AttendanceService.getAttendanceRecommendations(subject, settings);

        expect(recommendations.length, 1);
        expect(recommendations[0], contains('✅ You are on track'));
      });

      test('should provide appropriate recommendations for struggling subject',
          () {
        final subject = Subject(
          name: 'Test Subject',
          totalClasses: 10,
          attendedClasses: 3,
          requiredPercent: 75.0,
        );
        final settings = AppSettings(defaultRequiredPercent: 80.0);

        final recommendations =
            AttendanceService.getAttendanceRecommendations(subject, settings);

        expect(recommendations.length, 2);
        expect(recommendations[0], contains('⚠️ You need to attend'));
        expect(recommendations[1], contains('📈 Consider attending more'));
      });
    });

    group('getAttendanceTrend', () {
      test('should return excellent trend for high attendance', () {
        final subject = Subject(
          name: 'Test Subject',
          totalClasses: 10,
          attendedClasses: 9,
          requiredPercent: 75.0,
        );
        final settings = AppSettings(defaultRequiredPercent: 80.0);

        final trend = AttendanceService.getAttendanceTrend(subject, settings);

        expect(trend['trend'], 'Excellent');
        expect(trend['trendColor'], '#4CAF50');
        expect(trend['isOnTrack'], true);
      });

      test('should return poor trend for low attendance', () {
        final subject = Subject(
          name: 'Test Subject',
          totalClasses: 10,
          attendedClasses: 3,
          requiredPercent: 75.0,
        );
        final settings = AppSettings(defaultRequiredPercent: 80.0);

        final trend = AttendanceService.getAttendanceTrend(subject, settings);

        expect(trend['trend'], 'Poor');
        expect(trend['trendColor'], '#F44336');
        expect(trend['isOnTrack'], false);
      });
    });
  });
}
