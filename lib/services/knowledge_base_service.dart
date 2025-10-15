import 'package:flutter/services.dart';

class CareerInfo {
  final String name;
  final String primaryDegree;
  final String keyExams;
  final String advancedStudies;
  final String stream;
  final int number;

  CareerInfo({
    required this.name,
    required this.primaryDegree,
    required this.keyExams,
    required this.advancedStudies,
    required this.stream,
    required this.number,
  });

  // Create a comprehensive text representation for embedding
  String get fullDescription {
    return '''
Career: $name
Stream: $stream
Primary Degree: $primaryDegree
Key Exams/Certifications: $keyExams
Advanced Studies: $advancedStudies
''';
  }

  // Create a searchable text with keywords
  String get searchableText {
    return '$name $stream $primaryDegree $keyExams $advancedStudies';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'primaryDegree': primaryDegree,
      'keyExams': keyExams,
      'advancedStudies': advancedStudies,
      'stream': stream,
      'number': number,
    };
  }

  factory CareerInfo.fromJson(Map<String, dynamic> json) {
    return CareerInfo(
      name: json['name'] ?? '',
      primaryDegree: json['primaryDegree'] ?? '',
      keyExams: json['keyExams'] ?? '',
      advancedStudies: json['advancedStudies'] ?? '',
      stream: json['stream'] ?? '',
      number: json['number'] ?? 0,
    );
  }
}

class KnowledgeBaseService {
  static List<CareerInfo>? _careers;
  static bool _isInitialized = false;

  /// Initialize the knowledge base by parsing the career data
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final String data = await rootBundle.loadString(
        'assets/knowledge_base.txt',
      );
      _careers = _parseCareerData(data);
      _isInitialized = true;
      print('Knowledge base initialized with ${_careers!.length} careers');
    } catch (e) {
      print('Error initializing knowledge base: $e');
      _careers = [];
      _isInitialized = true;
    }
  }

  /// Parse the raw career data from the knowledge base file
  static List<CareerInfo> _parseCareerData(String data) {
    final List<CareerInfo> careers = [];
    final lines = data.split('\n');

    String currentStream = '';
    CareerInfo? currentCareer;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      // Check for stream headers
      if (line.contains('🔬 Science Stream') ||
          line.contains('💹 Commerce & Finance Stream') ||
          line.contains('🎨 Arts Stream')) {
        if (line.contains('Science')) {
          currentStream = 'Science';
        } else if (line.contains('Commerce')) {
          currentStream = 'Commerce & Finance';
        } else {
          currentStream = 'Arts';
        }
        continue;
      }

      // Check for career number (e.g., "1. Lawyer", "18. Doctor")
      final careerMatch = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(line);
      if (careerMatch != null) {
        // Save previous career if exists
        if (currentCareer != null) {
          careers.add(currentCareer);
        }

        final number = int.parse(careerMatch.group(1)!);
        final name = careerMatch.group(2)!;
        currentCareer = CareerInfo(
          name: name,
          primaryDegree: '',
          keyExams: '',
          advancedStudies: '',
          stream: currentStream,
          number: number,
        );
        continue;
      }

      // Check for sections within a career
      if (currentCareer != null) {
        if (line.startsWith('Primary Degree:')) {
          currentCareer = CareerInfo(
            name: currentCareer.name,
            primaryDegree: line.substring('Primary Degree:'.length).trim(),
            keyExams: currentCareer.keyExams,
            advancedStudies: currentCareer.advancedStudies,
            stream: currentCareer.stream,
            number: currentCareer.number,
          );
        } else if (line.startsWith('Key Exams/Certifications:')) {
          currentCareer = CareerInfo(
            name: currentCareer.name,
            primaryDegree: currentCareer.primaryDegree,
            keyExams: line.substring('Key Exams/Certifications:'.length).trim(),
            advancedStudies: currentCareer.advancedStudies,
            stream: currentCareer.stream,
            number: currentCareer.number,
          );
        } else if (line.startsWith('Advanced Studies:')) {
          currentCareer = CareerInfo(
            name: currentCareer.name,
            primaryDegree: currentCareer.primaryDegree,
            keyExams: currentCareer.keyExams,
            advancedStudies: line.substring('Advanced Studies:'.length).trim(),
            stream: currentCareer.stream,
            number: currentCareer.number,
          );
        }
      }
    }

    // Add the last career
    if (currentCareer != null) {
      careers.add(currentCareer);
    }

    return careers;
  }

  /// Get all careers
  static List<CareerInfo> getAllCareers() {
    if (!_isInitialized) {
      throw Exception(
        'Knowledge base not initialized. Call initialize() first.',
      );
    }
    return _careers ?? [];
  }

  /// Search careers by keyword
  static List<CareerInfo> searchCareers(String query) {
    if (!_isInitialized) {
      throw Exception(
        'Knowledge base not initialized. Call initialize() first.',
      );
    }

    if (query.isEmpty) return getAllCareers();

    final lowerQuery = query.toLowerCase();
    final results = <CareerInfo>[];

    for (final career in _careers!) {
      final searchText = career.searchableText.toLowerCase();
      if (searchText.contains(lowerQuery)) {
        results.add(career);
      }
    }

    // Sort by relevance (exact name match first, then by stream)
    results.sort((a, b) {
      final aNameMatch = a.name.toLowerCase().contains(lowerQuery);
      final bNameMatch = b.name.toLowerCase().contains(lowerQuery);

      if (aNameMatch && !bNameMatch) return -1;
      if (!aNameMatch && bNameMatch) return 1;

      return a.name.compareTo(b.name);
    });

    return results;
  }

  /// Get careers by stream
  static List<CareerInfo> getCareersByStream(String stream) {
    if (!_isInitialized) {
      throw Exception(
        'Knowledge base not initialized. Call initialize() first.',
      );
    }

    return _careers!.where((career) => career.stream == stream).toList();
  }

  /// Get a specific career by name
  static CareerInfo? getCareerByName(String name) {
    if (!_isInitialized) {
      throw Exception(
        'Knowledge base not initialized. Call initialize() first.',
      );
    }

    try {
      return _careers!.firstWhere(
        (career) => career.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get relevant careers for a user query using keyword matching
  static List<CareerInfo> getRelevantCareers(
    String query, {
    int maxResults = 5,
  }) {
    final allCareers = getAllCareers();
    final queryWords = query.toLowerCase().split(' ');
    final scoredCareers = <MapEntry<CareerInfo, int>>[];

    for (final career in allCareers) {
      int score = 0;

      // Score based on keyword matches
      for (final word in queryWords) {
        if (word.length < 3) continue; // Skip short words

        if (career.name.toLowerCase().contains(word)) {
          score += 10; // High score for name matches
        }
        if (career.stream.toLowerCase().contains(word)) {
          score += 5; // Medium score for stream matches
        }
        if (career.primaryDegree.toLowerCase().contains(word)) {
          score += 3; // Lower score for degree matches
        }
        if (career.keyExams.toLowerCase().contains(word)) {
          score += 3; // Lower score for exam matches
        }
        if (career.advancedStudies.toLowerCase().contains(word)) {
          score += 3; // Lower score for advanced studies matches
        }
      }

      if (score > 0) {
        scoredCareers.add(MapEntry(career, score));
      }
    }

    // Sort by score (highest first) and return top results
    scoredCareers.sort((a, b) => b.value.compareTo(a.value));
    return scoredCareers.take(maxResults).map((entry) => entry.key).toList();
  }

  /// Get career suggestions based on user profile
  static List<CareerInfo> getCareerSuggestions(
    Map<String, dynamic>? userProfile,
  ) {
    if (userProfile == null) return getAllCareers().take(10).toList();

    final stream = userProfile['stream'];
    final educationLevel = userProfile['educationLevel'];
    final isWorking = userProfile['isWorking'] ?? false;

    List<CareerInfo> suggestions = [];

    // Filter by stream if available
    if (stream != null && stream.isNotEmpty) {
      suggestions = getCareersByStream(stream);
    } else {
      suggestions = getAllCareers();
    }

    // Filter by education level
    if (educationLevel != null && educationLevel.isNotEmpty) {
      if (educationLevel.toLowerCase().contains('12th') ||
          educationLevel.toLowerCase().contains('intermediate')) {
        // For 12th pass students, prioritize careers that start after 12th
        suggestions = suggestions.where((career) {
          final degree = career.primaryDegree.toLowerCase();
          return degree.contains('b.') ||
              degree.contains('bachelor') ||
              degree.contains('diploma') ||
              degree.contains('certificate');
        }).toList();
      }
    }

    // If working, suggest advanced studies
    if (isWorking) {
      suggestions = suggestions.where((career) {
        return career.advancedStudies.isNotEmpty &&
            !career.advancedStudies.toLowerCase().contains('not required');
      }).toList();
    }

    return suggestions.take(8).toList();
  }

  /// Get career statistics
  static Map<String, int> getCareerStats() {
    if (!_isInitialized) {
      throw Exception(
        'Knowledge base not initialized. Call initialize() first.',
      );
    }

    final stats = <String, int>{};
    for (final career in _careers!) {
      stats[career.stream] = (stats[career.stream] ?? 0) + 1;
    }

    return stats;
  }
}
