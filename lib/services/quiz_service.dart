import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class QuestionSet {
  final String id;
  final DateTime syncDate;
  final List<Question> questions;
  final int totalQuestions;

  QuestionSet({
    required this.id,
    required this.syncDate,
    required this.questions,
    required this.totalQuestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'syncDate': syncDate.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'totalQuestions': totalQuestions,
    };
  }

  factory QuestionSet.fromJson(Map<String, dynamic> json) {
    return QuestionSet(
      id: json['id'],
      syncDate: DateTime.parse(json['syncDate']),
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
      totalQuestions: json['totalQuestions'],
    );
  }
}

class QuizService {
  static QuizDatabase? _database;
  static SharedPreferences? _prefs;

  // GitHub raw URL (questions are auto-updated daily by GitHub Actions)
  static const String remoteUrl =
      'https://raw.githubusercontent.com/musharrafhamraz/FIA-Preparation_App/main/questions.json';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Load questions from GitHub (auto-updated by workflow)
  static Future<QuizDatabase?> loadDatabase({bool forceRefresh = false}) async {
    if (_database != null && !forceRefresh) return _database;

    try {
      print('QuizService: Attempting to fetch from GitHub...');
      // Fetch from GitHub (fresh questions from daily scraper)
      final response = await http
          .get(Uri.parse(remoteUrl))
          .timeout(const Duration(seconds: 15));

      print('QuizService: Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(
          'QuizService: Successfully fetched ${response.body.length} bytes',
        );
        final Map<String, dynamic> jsonData = json.decode(response.body);
        _database = QuizDatabase.fromJson(jsonData);
        print('QuizService: Parsed ${_database!.questions.length} questions');

        // Save as a new question set with timestamp
        final saved = await _saveQuestionSetWithTimestamp(_database!.questions);
        print('QuizService: Question set saved: $saved');
        if (!saved) {
          // Could not save - either duplicate or daily limit reached
          print(
            'QuizService: Could not save - duplicate or daily limit reached',
          );
        }

        // Cache locally for offline use (legacy support)
        await _cacheQuestions(response.body);
        return _database;
      } else {
        print('QuizService: HTTP error ${response.statusCode}');
      }
    } catch (e) {
      // Remote fetch failed, try fallback
      print('QuizService: Remote fetch failed: $e');
    }

    // Fallback: Try cached data
    try {
      print('QuizService: Trying cached data...');
      final cachedData = _prefs?.getString('cached_questions');
      if (cachedData != null) {
        print('QuizService: Found cached data, parsing...');
        final Map<String, dynamic> jsonData = json.decode(cachedData);
        _database = QuizDatabase.fromJson(jsonData);
        print(
          'QuizService: Using cached database with ${_database!.questions.length} questions',
        );
        return _database;
      } else {
        print('QuizService: No cached data found');
      }
    } catch (e) {
      // Cache load failed
      print('QuizService: Cache load failed: $e');
    }

    // Final fallback: Load from bundled asset
    try {
      print('QuizService: Trying bundled asset...');
      final String jsonString = await rootBundle.loadString(
        'assets/questions.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _database = QuizDatabase.fromJson(jsonData);
      print(
        'QuizService: Using bundled asset with ${_database!.questions.length} questions',
      );
      return _database;
    } catch (e) {
      print('QuizService: Asset load failed: $e');
      return null;
    }
  }

  // Save questions as a timestamped set
  static Future<bool> _saveQuestionSetWithTimestamp(
    List<Question> questions,
  ) async {
    if (_prefs == null) return false;

    // Check daily limit (4 times per day)
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existingSets = await getSavedQuestionSets();
    final todaysSets = existingSets.where((set) {
      final setDate = set.syncDate;
      final setKey =
          '${setDate.year}-${setDate.month.toString().padLeft(2, '0')}-${setDate.day.toString().padLeft(2, '0')}';
      return setKey == todayKey;
    }).length;

    // Limit to 4 syncs per day
    if (todaysSets >= 4) {
      return false; // Already synced 4 times today
    }

    // Check if we already have the exact same questions (prevent duplicates)
    final questionHashes = questions.map((q) => q.q.hashCode).toSet();
    for (var existingSet in existingSets) {
      final existingHashes = existingSet.questions
          .map((q) => q.q.hashCode)
          .toSet();
      if (questionHashes.length == existingHashes.length &&
          questionHashes.containsAll(existingHashes)) {
        return false; // Duplicate question set
      }
    }

    final now = DateTime.now();
    final questionSet = QuestionSet(
      id: _generateSetId(now),
      syncDate: now,
      questions: questions,
      totalQuestions: questions.length,
    );

    // Add new set
    existingSets.add(questionSet);

    // Keep only the last 20 sets to avoid storage bloat
    if (existingSets.length > 20) {
      existingSets.sort((a, b) => b.syncDate.compareTo(a.syncDate));
      existingSets.removeRange(20, existingSets.length);
    }

    // Save updated list
    final setsJson = existingSets.map((set) => set.toJson()).toList();
    await _prefs!.setString('question_sets', json.encode(setsJson));
    return true;
  }

  // Check how many syncs are left today
  static Future<int> getDailySyncsRemaining() async {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existingSets = await getSavedQuestionSets();
    final todaysSets = existingSets.where((set) {
      final setDate = set.syncDate;
      final setKey =
          '${setDate.year}-${setDate.month.toString().padLeft(2, '0')}-${setDate.day.toString().padLeft(2, '0')}';
      return setKey == todayKey;
    }).length;

    return 4 - todaysSets;
  }

  static String _generateSetId(DateTime date) {
    return 'set_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }

  // Get all saved question sets
  static Future<List<QuestionSet>> getSavedQuestionSets() async {
    if (_prefs == null) return [];

    try {
      final setsJson = _prefs!.getString('question_sets');
      if (setsJson == null) return [];

      final List<dynamic> setsList = json.decode(setsJson);
      return setsList.map((setJson) => QuestionSet.fromJson(setJson)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get questions from a specific set
  static Future<List<Question>> getQuestionsFromSet(
    String setId,
    int count,
  ) async {
    final sets = await getSavedQuestionSets();
    final targetSet = sets.where((set) => set.id == setId).firstOrNull;

    if (targetSet == null) return [];

    final shuffled = List<Question>.from(targetSet.questions)
      ..shuffle(Random());
    return shuffled.take(count).toList();
  }

  // Delete a specific question set
  static Future<void> deleteQuestionSet(String setId) async {
    if (_prefs == null) return;

    final existingSets = await getSavedQuestionSets();
    existingSets.removeWhere((set) => set.id == setId);

    final setsJson = existingSets.map((set) => set.toJson()).toList();
    await _prefs!.setString('question_sets', json.encode(setsJson));
  }

  // Clear all saved question sets
  static Future<void> clearAllQuestionSets() async {
    if (_prefs == null) return;
    await _prefs!.remove('question_sets');
  }

  // Reset daily sync counter (for testing purposes)
  static Future<void> resetDailySyncCounter() async {
    if (_prefs == null) return;

    // Clear all existing question sets to reset the counter
    await _prefs!.remove('question_sets');

    // Also clear any cached data for a fresh start
    await _prefs!.remove('cached_questions');
    await _prefs!.remove('cache_date');
  }

  // Get storage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final sets = await getSavedQuestionSets();
    int totalQuestions = 0;
    for (var set in sets) {
      totalQuestions += set.totalQuestions;
    }

    return {
      'totalSets': sets.length,
      'totalQuestions': totalQuestions,
      'oldestDate': sets.isEmpty
          ? null
          : sets.map((s) => s.syncDate).reduce((a, b) => a.isBefore(b) ? a : b),
      'newestDate': sets.isEmpty
          ? null
          : sets.map((s) => s.syncDate).reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }

  // Fetch fresh questions from GitHub
  static Future<List<Question>> fetchFreshQuestions(int count) async {
    try {
      final response = await http
          .get(Uri.parse(remoteUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final tempDb = QuizDatabase.fromJson(jsonData);

        _database = tempDb;

        // Save as new timestamped set
        final saved = await _saveQuestionSetWithTimestamp(tempDb.questions);
        if (!saved) {
          // Could not save - either duplicate or daily limit reached
        }

        // Legacy cache
        await _cacheQuestions(response.body);

        // Get all questions and shuffle
        final questions = List<Question>.from(tempDb.questions)
          ..shuffle(Random());
        return questions.take(count).toList();
      }
    } catch (e) {
      // Fallback to cached
    }

    // Fallback: use cached/bundled data
    return getRandomQuestions(count);
  }

  static Future<void> _cacheQuestions(String jsonString) async {
    try {
      await _prefs?.setString('cached_questions', jsonString);
      await _prefs?.setString('cache_date', DateTime.now().toIso8601String());
    } catch (e) {
      // Failed to cache
    }
  }

  static String? getCacheDate() {
    return _prefs?.getString('cache_date');
  }

  static Future<void> clearCache() async {
    await _prefs?.remove('cached_questions');
    await _prefs?.remove('cache_date');
    _database = null;
  }

  static List<Question> getRandomQuestions(int count) {
    if (_database == null) return [];

    final questions = List<Question>.from(_database!.questions)
      ..shuffle(Random());
    return questions.take(count).toList();
  }

  static int getTotalQuestions() {
    return _database?.questions.length ?? 0;
  }

  // Session management
  static int getTotalAnswered() {
    return _prefs?.getInt('tpq_answered') ?? 0;
  }

  static void setTotalAnswered(int count) {
    _prefs?.setInt('tpq_answered', count);
  }

  static int getBestScore() {
    return _prefs?.getInt('tpq_best') ?? 0;
  }

  static void setBestScore(int score) {
    _prefs?.setInt('tpq_best', score);
  }

  static void updateStats(int questionsAnswered, int scorePercentage) {
    final currentTotal = getTotalAnswered();
    setTotalAnswered(currentTotal + questionsAnswered);

    final currentBest = getBestScore();
    if (scorePercentage > currentBest) {
      setBestScore(scorePercentage);
    }
  }
}
