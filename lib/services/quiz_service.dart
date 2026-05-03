import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class QuizService {
  static QuizDatabase? _database;
  static SharedPreferences? _prefs;

  // IMPORTANT: Your GitHub raw URL (fetches from main branch)
  static const String remoteUrl =
      'https://raw.githubusercontent.com/musharrafhamraz/FIA-Preparation_App/main/questions.json';

  // Set to true to always use remote, false to try remote with fallback
  static const bool alwaysUseRemote = true;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<QuizDatabase?> loadDatabase() async {
    if (_database != null) return _database;

    try {
      if (alwaysUseRemote) {
        // Try loading from remote first
        final response = await http
            .get(Uri.parse(remoteUrl))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          _database = QuizDatabase.fromJson(jsonData);

          // Cache the remote data locally for offline use
          await _cacheQuestions(response.body);
          return _database;
        }
      }
    } catch (e) {
      // Remote fetch failed, try fallback
    }

    // Fallback: Try cached data first, then bundled asset
    try {
      final cachedData = _prefs?.getString('cached_questions');
      if (cachedData != null) {
        final Map<String, dynamic> jsonData = json.decode(cachedData);
        _database = QuizDatabase.fromJson(jsonData);
        return _database;
      }
    } catch (e) {
      // Cache load failed
    }

    // Final fallback: Load from bundled asset
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/questions.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _database = QuizDatabase.fromJson(jsonData);
      return _database;
    } catch (e) {
      return null;
    }
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

  static List<Question> getQuestionsByCategory(String category) {
    if (_database == null) return [];

    if (category.isEmpty) {
      return _database!.questions;
    }

    return _database!.questions.where((q) => q.category == category).toList();
  }

  static List<Question> getRandomQuestions(String category, int count) {
    final questions = getQuestionsByCategory(category);
    if (questions.isEmpty) return [];

    final shuffled = List<Question>.from(questions)..shuffle(Random());
    return shuffled.take(count).toList();
  }

  static Map<String, int> getCategoryCounts() {
    if (_database == null) return {};

    final Map<String, int> counts = {};
    for (var question in _database!.questions) {
      counts[question.category] = (counts[question.category] ?? 0) + 1;
    }
    return counts;
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
