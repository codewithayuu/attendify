import '../models/subject.dart';
import '../models/app_settings.dart';

class AttendanceService {
  /// Calculate the minimum number of classes that must be attended to meet the required percentage
  ///
  /// [pct] - Required attendance percentage (e.g., 75.0 for 75%)
  /// [totalClasses] - Total number of classes
  /// Returns the minimum number of classes that must be attended
  static int requiredAttended(double pct, int totalClasses) {
    return (pct / 100 * totalClasses).ceil();
  }

  /// Calculate how many more classes need to be attended to meet the required percentage
  ///
  /// [attended] - Number of classes already attended
  /// [requiredPct] - Required attendance percentage (e.g., 75.0 for 75%)
  /// [totalClasses] - Total number of classes
  /// Returns the number of additional classes that need to be attended
  static int classesNeeded(int attended, double requiredPct, int totalClasses) {
    final req = requiredAttended(requiredPct, totalClasses);
    final need = req - attended;
    return need > 0 ? need : 0;
  }

  /// Get the effective required percentage for a subject
  ///
  /// [subject] - The subject to check
  /// [settings] - App settings containing default required percentage
  /// Returns the required percentage (subject-specific or global default)
  static double getRequiredPercentage(Subject subject, AppSettings settings) {
    return subject.requiredPercent ?? settings.defaultRequiredPercent;
  }

  /// Calculate attendance statistics for a subject
  ///
  /// [subject] - The subject to analyze
  /// [settings] - App settings containing default required percentage
  /// Returns a map with attendance statistics
  static Map<String, dynamic> getAttendanceStats(
      Subject subject, AppSettings settings) {
    final requiredPct = getRequiredPercentage(subject, settings);
    final totalClasses = subject.totalClasses;
    final attendedClasses = subject.attendedClasses;
    final currentPct =
        totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0.0;
    final requiredAttendedCount = requiredAttended(requiredPct, totalClasses);
    final classesNeededCount =
        classesNeeded(attendedClasses, requiredPct, totalClasses);
    final isOnTrack = attendedClasses >= requiredAttendedCount;

    return {
      'totalClasses': totalClasses,
      'attendedClasses': attendedClasses,
      'currentPercentage': currentPct,
      'requiredPercentage': requiredPct,
      'requiredAttended': requiredAttendedCount,
      'classesNeeded': classesNeededCount,
      'isOnTrack': isOnTrack,
      'canStillMeetRequirement':
          _canStillMeetRequirement(attendedClasses, requiredPct, totalClasses),
    };
  }

  /// Check if it's still possible to meet the attendance requirement
  ///
  /// [attended] - Number of classes already attended
  /// [requiredPct] - Required attendance percentage
  /// [totalClasses] - Total number of classes
  /// Returns true if it's still possible to meet the requirement
  static bool _canStillMeetRequirement(
      int attended, double requiredPct, int totalClasses) {
    if (totalClasses == 0) return true;

    final requiredAttendedCount = requiredAttended(requiredPct, totalClasses);
    final remainingClasses = totalClasses - attended;

    // If no remaining classes, check if we already met the requirement
    if (remainingClasses == 0) {
      return attended >= requiredAttendedCount;
    }

    // Check if it's possible to meet the requirement with remaining classes
    return attended + remainingClasses >= requiredAttendedCount;
  }

  /// Get attendance recommendations for a subject
  ///
  /// [subject] - The subject to analyze
  /// [settings] - App settings containing default required percentage
  /// Returns a list of recommendations
  static List<String> getAttendanceRecommendations(
      Subject subject, AppSettings settings) {
    final stats = getAttendanceStats(subject, settings);
    final recommendations = <String>[];

    if (stats['isOnTrack'] == true) {
      recommendations
          .add('✅ You are on track to meet the attendance requirement!');
    } else {
      final classesNeeded = stats['classesNeeded'] as int;
      if (classesNeeded > 0) {
        recommendations.add(
            '⚠️ You need to attend $classesNeeded more class${classesNeeded == 1 ? '' : 'es'} to meet the requirement.');
      }
    }

    if (stats['canStillMeetRequirement'] == false) {
      recommendations.add(
          '❌ It is no longer possible to meet the attendance requirement.');
    }

    final currentPct = stats['currentPercentage'] as double;
    final requiredPct = stats['requiredPercentage'] as double;

    if (currentPct < requiredPct - 10) {
      recommendations.add(
          '📈 Consider attending more classes to improve your attendance.');
    }

    return recommendations;
  }

  /// Calculate attendance trend for a subject
  ///
  /// [subject] - The subject to analyze
  /// [settings] - App settings containing default required percentage
  /// Returns trend information
  static Map<String, dynamic> getAttendanceTrend(
      Subject subject, AppSettings settings) {
    final stats = getAttendanceStats(subject, settings);
    final currentPct = stats['currentPercentage'] as double;
    final requiredPct = stats['requiredPercentage'] as double;

    String trend;
    String trendColor;

    if (currentPct >= requiredPct) {
      trend = 'Excellent';
      trendColor = '#4CAF50'; // Green
    } else if (currentPct >= requiredPct - 10) {
      trend = 'Good';
      trendColor = '#8BC34A'; // Light Green
    } else if (currentPct >= requiredPct - 20) {
      trend = 'Fair';
      trendColor = '#FF9800'; // Orange
    } else {
      trend = 'Poor';
      trendColor = '#F44336'; // Red
    }

    return {
      'trend': trend,
      'trendColor': trendColor,
      'currentPercentage': currentPct,
      'requiredPercentage': requiredPct,
      'isOnTrack': stats['isOnTrack'],
    };
  }
}
