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

  // Your GitHub raw URL (questions are auto-updated daily by GitHub Actions)
  // static const String remoteUrl =
  //     'https://raw.githubusercontent.com/musharrafhamraz/FIA-Preparation_App/main/questions.json';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Load questions from GitHub (auto-updated by workflow)
  static Future<QuizDatabase?> loadDatabase({bool forceRefresh = false}) async {
    if (_database != null && !forceRefresh) return _database;

    try {
      // Fetch from GitHub (fresh questions from daily scraper)
      final response = await http
          .get(Uri.parse(remoteUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        _database = QuizDatabase.fromJson(jsonData);

        // Cache locally for offline use
        await _cacheQuestions(response.body);
        return _database;
      }
    } catch (e) {
      // Remote fetch failed, try fallback
    }

    // Fallback: Try cached data
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

  // Fetch fresh questions from GitHub (auto-scrape is already running!)
  static Future<List<Question>> fetchFreshQuestions(
    String category,
    int count,
  ) async {
    // Since GitHub Actions automatically scrapes daily,
    // we just need to fetch the latest from GitHub!
    try {
      final response = await http
          .get(Uri.parse(remoteUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final tempDb = QuizDatabase.fromJson(jsonData);

        _database = tempDb;
        await _cacheQuestions(response.body);

        // Filter by category if selected
        List<Question> questions;
        if (category.isEmpty) {
          questions = tempDb.questions;
        } else {
          questions = tempDb.questions
              .where((q) => q.category == category)
              .toList();
        }

        questions.shuffle(Random());
        return questions.take(count).toList();
      }
    } catch (e) {
      // Fallback to cached
    }

    // Fallback: use cached/bundled data
    return getRandomQuestions(category, count);
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
