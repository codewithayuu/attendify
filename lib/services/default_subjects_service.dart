import '../models/subject.dart';
import 'hive_service.dart';

class DefaultSubjectsService {
  static const List<Map<String, dynamic>> _defaultSubjects = [
    {
      'name': 'ENGG Graphics Lab',
      'description': 'Engineering Graphics Laboratory',
      'colorHex': '#2196F3', // Blue
    },
    {
      'name': 'Env Studies Lab',
      'description': 'Environmental Studies Laboratory',
      'colorHex': '#4CAF50', // Green
    },
    {
      'name': 'Physics',
      'description': 'Physics Theory',
      'colorHex': '#FF9800', // Orange
    },
    {
      'name': 'Environmental Studies',
      'description': 'Environmental Studies Theory',
      'colorHex': '#9C27B0', // Purple
    },
    {
      'name': 'ENGG Graphics-I Lab',
      'description': 'Engineering Graphics-I Laboratory',
      'colorHex': '#00BCD4', // Cyan
    },
    {
      'name': 'Applied Mathematics-I',
      'description': 'Applied Mathematics-I Theory',
      'colorHex': '#FF5722', // Deep Orange
    },
    {
      'name': 'Communication Skills',
      'description': 'Communication Skills Development',
      'colorHex': '#795548', // Brown
    },
    {
      'name': 'Programming in C',
      'description': 'Programming in C Theory',
      'colorHex': '#607D8B', // Blue Grey
    },
    {
      'name': 'Programming in C Lab',
      'description': 'Programming in C Laboratory',
      'colorHex': '#E91E63', // Pink
    },
    {
      'name': 'Manufacturing Process',
      'description': 'Manufacturing Process Theory',
      'colorHex': '#3F51B5', // Indigo
    },
    {
      'name': 'Applied Physics-I Lab',
      'description': 'Applied Physics-I Laboratory',
      'colorHex': '#009688', // Teal
    },
  ];

  // Initialize default subjects if none exist
  static Future<void> initializeDefaultSubjects() async {
    final existingSubjects = HiveService.getAllSubjects();
    
    // Only add default subjects if no subjects exist
    if (existingSubjects.isEmpty) {
      for (final subjectData in _defaultSubjects) {
        final subject = Subject(
          name: subjectData['name'],
          description: subjectData['description'],
          colorHex: subjectData['colorHex'],
          totalClasses: 0,
          attendedClasses: 0,
          // Add new required fields with proper defaults
          weekdays: [1, 3, 5], // Monday, Wednesday, Friday
          startTime: '09:00',
          endTime: '10:00',
          recurringWeekly: true,
          requiredPercent: null, // Use global default
        );
        
        await HiveService.addSubject(subject);
      }
    }
  }

  // Get default subjects data
  static List<Map<String, dynamic>> getDefaultSubjects() {
    return List.from(_defaultSubjects);
  }

  // Reset to default subjects (clears all existing and adds defaults)
  static Future<void> resetToDefaultSubjects() async {
    // Clear all existing subjects
    final existingSubjects = HiveService.getAllSubjects();
    for (final subject in existingSubjects) {
      await HiveService.deleteSubject(subject.id);
    }

    // Add default subjects
    await initializeDefaultSubjects();
  }

  // Add a single default subject
  static Future<void> addDefaultSubject(Map<String, dynamic> subjectData) async {
    final subject = Subject(
      name: subjectData['name'],
      description: subjectData['description'],
      colorHex: subjectData['colorHex'],
      totalClasses: 0,
      attendedClasses: 0,
      // Add new required fields with proper defaults
      weekdays: [1, 3, 5], // Monday, Wednesday, Friday
      startTime: '09:00',
      endTime: '10:00',
      recurringWeekly: true,
      requiredPercent: null, // Use global default
    );
    
    await HiveService.addSubject(subject);
  }

  // Check if a subject name already exists
  static bool subjectExists(String subjectName) {
    final existingSubjects = HiveService.getAllSubjects();
    return existingSubjects.any((subject) => 
        subject.name.toLowerCase() == subjectName.toLowerCase());
  }

  // Get subjects that are missing from defaults
  static List<Map<String, dynamic>> getMissingDefaultSubjects() {
    final existingSubjects = HiveService.getAllSubjects();
    final existingNames = existingSubjects.map((s) => s.name.toLowerCase()).toSet();
    
    return _defaultSubjects.where((defaultSubject) => 
        !existingNames.contains(defaultSubject['name'].toLowerCase())).toList();
  }

  // Get subjects that are not in defaults (custom subjects)
  static List<Subject> getCustomSubjects() {
    final existingSubjects = HiveService.getAllSubjects();
    final defaultNames = _defaultSubjects.map((s) => s['name'].toLowerCase()).toSet();
    
    return existingSubjects.where((subject) => 
        !defaultNames.contains(subject.name.toLowerCase())).toList();
  }

  // Add missing default subjects
  static Future<void> addMissingDefaultSubjects() async {
    final missingSubjects = getMissingDefaultSubjects();
    
    for (final subjectData in missingSubjects) {
      await addDefaultSubject(subjectData);
    }
  }

  // Check if all default subjects are present
  static bool areAllDefaultSubjectsPresent() {
    return getMissingDefaultSubjects().isEmpty;
  }

  // Get subject statistics
  static Map<String, dynamic> getSubjectStatistics() {
    final existingSubjects = HiveService.getAllSubjects();
    final defaultSubjects = _defaultSubjects.length;
    final customSubjects = getCustomSubjects().length;
    final missingDefaults = getMissingDefaultSubjects().length;
    
    return {
      'totalSubjects': existingSubjects.length,
      'defaultSubjects': defaultSubjects,
      'customSubjects': customSubjects,
      'missingDefaults': missingDefaults,
      'allDefaultsPresent': areAllDefaultSubjectsPresent(),
    };
  }
}

