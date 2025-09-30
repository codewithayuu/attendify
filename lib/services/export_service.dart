import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/subject.dart';
import '../models/attendance_record.dart';
import 'hive_service.dart';

class ExportService {
  // Export all data to CSV
  static Future<String> exportToCSV() async {
    final subjects = HiveService.getAllSubjects();
    final records = HiveService.getAllAttendanceRecords();
    final settings = HiveService.getSettings();

    // Create CSV data
    final csvData = <List<dynamic>>[];

    // Add header
    csvData.add(['Attendance Tracker Export']);
    csvData.add([
      'Export Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'
    ]);
    csvData.add([]);

    // Add subjects
    csvData.add(['SUBJECTS']);
    csvData.add([
      'ID',
      'Name',
      'Description',
      'Total Classes',
      'Attended Classes',
      'Percentage',
      'Created At',
      'Updated At'
    ]);

    for (final subject in subjects) {
      csvData.add([
        subject.id,
        subject.name,
        subject.description ?? '',
        subject.totalClasses,
        subject.attendedClasses,
        subject.attendancePercentage.toStringAsFixed(2),
        DateFormat('yyyy-MM-dd HH:mm:ss').format(subject.createdAt),
        DateFormat('yyyy-MM-dd HH:mm:ss').format(subject.updatedAt),
      ]);
    }

    csvData.add([]);

    // Add attendance records
    csvData.add(['ATTENDANCE RECORDS']);
    csvData.add([
      'ID',
      'Subject ID',
      'Subject Name',
      'Date',
      'Status',
      'Notes',
      'Created At'
    ]);

    for (final record in records) {
      final subject = subjects.firstWhere((s) => s.id == record.subjectId,
          orElse: () => Subject(name: 'Unknown'));
      csvData.add([
        record.id,
        record.subjectId,
        subject.name,
        DateFormat('yyyy-MM-dd').format(record.date),
        record.status.displayName,
        record.notes ?? '',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(record.createdAt),
      ]);
    }

    csvData.add([]);

    // Add settings
    csvData.add(['SETTINGS']);
    csvData.add(['Setting', 'Value']);
    csvData.add(['Dark Mode', settings.isDarkMode]);
    csvData.add(['Notifications Enabled', settings.enableNotifications]);
    csvData.add(['Notification Time', settings.notificationTime]);
    csvData.add(['Firebase Sync', settings.enableFirebaseSync]);
    csvData.add(['Attendance Threshold', settings.attendanceThreshold]);
    csvData.add(['Show Percentage on Cards', settings.showPercentageOnCards]);
    csvData.add(['Default Subject Color', settings.defaultSubjectColor]);
    csvData.add(['Haptic Feedback', settings.enableHapticFeedback]);
    csvData.add(['Language Code', settings.languageCode]);
    csvData.add([
      'Last Sync Time',
      DateFormat('yyyy-MM-dd HH:mm:ss').format(settings.lastSyncTime)
    ]);

    // Convert to CSV string
    const converter = ListToCsvConverter();
    final csvString = converter.convert(csvData);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'attendance_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  // Export all data to Excel
  static Future<String> exportToExcel() async {
    final subjects = HiveService.getAllSubjects();
    final records = HiveService.getAllAttendanceRecords();
    final settings = HiveService.getSettings();

    // Create Excel file
    final excel = Excel.createExcel();
    final sheet = excel['Attendance Data'];

    // Add header
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('Attendance Tracker Export');
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'Export Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');

    // Add subjects
    int row = 4;
    sheet.cell(CellIndex.indexByString('A$row')).value =
        TextCellValue('SUBJECTS');
    row++;

    // Subject headers
    final subjectHeaders = [
      'ID',
      'Name',
      'Description',
      'Total Classes',
      'Attended Classes',
      'Percentage',
      'Created At',
      'Updated At'
    ];
    for (int i = 0; i < subjectHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}$row'))
          .value = TextCellValue(subjectHeaders[i]);
    }
    row++;

    // Subject data
    for (final subject in subjects) {
      sheet.cell(CellIndex.indexByString('A$row')).value =
          TextCellValue(subject.id);
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(subject.name);
      sheet.cell(CellIndex.indexByString('C$row')).value =
          TextCellValue(subject.description ?? '');
      sheet.cell(CellIndex.indexByString('D$row')).value =
          IntCellValue(subject.totalClasses);
      sheet.cell(CellIndex.indexByString('E$row')).value =
          IntCellValue(subject.attendedClasses);
      sheet.cell(CellIndex.indexByString('F$row')).value =
          DoubleCellValue(subject.attendancePercentage);
      sheet.cell(CellIndex.indexByString('G$row')).value = TextCellValue(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(subject.createdAt));
      sheet.cell(CellIndex.indexByString('H$row')).value = TextCellValue(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(subject.updatedAt));
      row++;
    }

    row += 2;

    // Add attendance records
    sheet.cell(CellIndex.indexByString('A$row')).value =
        TextCellValue('ATTENDANCE RECORDS');
    row++;

    // Record headers
    final recordHeaders = [
      'ID',
      'Subject ID',
      'Subject Name',
      'Date',
      'Status',
      'Notes',
      'Created At'
    ];
    for (int i = 0; i < recordHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}$row'))
          .value = TextCellValue(recordHeaders[i]);
    }
    row++;

    // Record data
    for (final record in records) {
      final subject = subjects.firstWhere((s) => s.id == record.subjectId,
          orElse: () => Subject(name: 'Unknown'));
      sheet.cell(CellIndex.indexByString('A$row')).value =
          TextCellValue(record.id);
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(record.subjectId);
      sheet.cell(CellIndex.indexByString('C$row')).value =
          TextCellValue(subject.name);
      sheet.cell(CellIndex.indexByString('D$row')).value =
          TextCellValue(DateFormat('yyyy-MM-dd').format(record.date));
      sheet.cell(CellIndex.indexByString('E$row')).value =
          TextCellValue(record.status.displayName);
      sheet.cell(CellIndex.indexByString('F$row')).value =
          TextCellValue(record.notes ?? '');
      sheet.cell(CellIndex.indexByString('G$row')).value = TextCellValue(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(record.createdAt));
      row++;
    }

    row += 2;

    // Add settings
    sheet.cell(CellIndex.indexByString('A$row')).value =
        TextCellValue('SETTINGS');
    row++;

    sheet.cell(CellIndex.indexByString('A$row')).value =
        TextCellValue('Setting');
    sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue('Value');
    row++;

    final settingsData = [
      ['Dark Mode', settings.isDarkMode],
      ['Notifications Enabled', settings.enableNotifications],
      ['Notification Time', settings.notificationTime],
      ['Firebase Sync', settings.enableFirebaseSync],
      ['Attendance Threshold', settings.attendanceThreshold],
      ['Show Percentage on Cards', settings.showPercentageOnCards],
      ['Default Subject Color', settings.defaultSubjectColor],
      ['Haptic Feedback', settings.enableHapticFeedback],
      ['Language Code', settings.languageCode],
      [
        'Last Sync Time',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(settings.lastSyncTime)
      ],
    ];

    for (final setting in settingsData) {
      sheet.cell(CellIndex.indexByString('A$row')).value =
          TextCellValue(setting[0].toString());
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(setting[1].toString());
      row++;
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'attendance_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final file = File('${directory.path}/$fileName');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file.path;
  }

  // Export subjects only to CSV
  static Future<String> exportSubjectsToCSV() async {
    final subjects = HiveService.getAllSubjects();

    final csvData = <List<dynamic>>[];

    // Add header
    csvData.add([
      'Subject Name',
      'Description',
      'Total Classes',
      'Attended Classes',
      'Percentage',
      'Created At'
    ]);

    for (final subject in subjects) {
      csvData.add([
        subject.name,
        subject.description ?? '',
        subject.totalClasses,
        subject.attendedClasses,
        subject.attendancePercentage.toStringAsFixed(2),
        DateFormat('yyyy-MM-dd').format(subject.createdAt),
      ]);
    }

    const converter = ListToCsvConverter();
    final csvString = converter.convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'subjects_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  // Export attendance records only to CSV
  static Future<String> exportAttendanceToCSV() async {
    final subjects = HiveService.getAllSubjects();
    final records = HiveService.getAllAttendanceRecords();

    final csvData = <List<dynamic>>[];

    // Add header
    csvData.add(['Subject Name', 'Date', 'Status', 'Notes']);

    for (final record in records) {
      final subject = subjects.firstWhere((s) => s.id == record.subjectId,
          orElse: () => Subject(name: 'Unknown'));
      csvData.add([
        subject.name,
        DateFormat('yyyy-MM-dd').format(record.date),
        record.status.displayName,
        record.notes ?? '',
      ]);
    }

    const converter = ListToCsvConverter();
    final csvString = converter.convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'attendance_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  // Share exported file
  static Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)],
        text: 'Attendance Tracker Export');
  }

  // Get export statistics
  static Map<String, dynamic> getExportStats() {
    final subjects = HiveService.getAllSubjects();
    final records = HiveService.getAllAttendanceRecords();
    final settings = HiveService.getSettings();

    return {
      'subjects': subjects.length,
      'records': records.length,
      'totalClasses': subjects.fold(0, (sum, s) => sum + s.totalClasses),
      'attendedClasses': subjects.fold(0, (sum, s) => sum + s.attendedClasses),
      'lastExport': settings.lastSyncTime,
      'dataSize':
          '${(subjects.length + records.length) * 0.1} KB', // Rough estimate
    };
  }

  // Import data from CSV (basic implementation)
  static Future<bool> importFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(csvString);

      // This is a basic implementation
      // In a real app, you'd want more robust parsing and validation
      print('CSV data loaded: ${csvData.length} rows');

      // TODO: Implement proper CSV import logic
      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }

  // Import data from Excel (basic implementation)
  static Future<bool> importFromExcel(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // This is a basic implementation
      // In a real app, you'd want more robust parsing and validation
      print('Excel data loaded: ${excel.tables.keys.length} sheets');

      // TODO: Implement proper Excel import logic
      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }
}
