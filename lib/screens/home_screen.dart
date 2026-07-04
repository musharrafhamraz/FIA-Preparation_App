import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';
import '../services/quiz_service.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';
import 'offline_questions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  QuizDatabase? _database;
  bool _isLoading = true;
  int _questionCount = 20;
  int _timerSeconds = 45;
  String _mode = 'practice';
  Map<String, dynamic> _offlineStats = {};

  @override
  void initState() {
    super.initState();
    _loadDatabase();
    _loadOfflineStats();
  }

  Future<void> _loadDatabase() async {
    final db = await QuizService.loadDatabase();
    setState(() {
      _database = db;
      _isLoading = false;
    });
  }

  Future<void> _loadOfflineStats() async {
    final stats = await QuizService.getStorageInfo();
    final syncsRemaining = await QuizService.getDailySyncsRemaining();
    setState(() {
      _offlineStats = {...stats, 'syncsRemaining': syncsRemaining};
    });
  }

  void _startQuiz() async {
    if (_database == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No questions available')),
      );
      return;
    }

    // Check daily sync limit before fetching
    final syncsRemaining = await QuizService.getDailySyncsRemaining();

    // Fetch fresh questions from GitHub
    setState(() => _isLoading = true);

    try {
      print('HomeScreen: Starting quiz with $_questionCount questions');
      final questions = await QuizService.fetchFreshQuestions(_questionCount);

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ No questions found. Check your internet connection.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      print('HomeScreen: Got ${questions.length} questions for quiz');

      // Show sync info
      if (mounted && syncsRemaining > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Questions synced offline! $syncsRemaining syncs remaining today',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted && syncsRemaining == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📋 Using cached questions (daily sync limit reached)',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Refresh offline stats
      await _loadOfflineStats();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              questions: questions,
              timerSeconds: _timerSeconds,
              mode: _mode,
            ),
          ),
        );
      }
    } catch (e) {
      print('HomeScreen: Error starting quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to load questions: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshQuestions() async {
    setState(() => _isLoading = true);
    await QuizService.clearCache();
    await _loadDatabase();
    await _loadOfflineStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatsCard(),
                    const SizedBox(height: 20),
                    _buildQuizSetupCard(),
                    const SizedBox(height: 20),
                    _buildStartButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sarkari Tayyari',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                // Show confirmation dialog before resetting
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text('Reset Sync Counter?'),
                    content: const Text(
                      'This will reset your daily sync limit back to 4 and clear all saved offline question sets. Are you sure?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                // Only reset if user confirmed
                if (confirm == true) {
                  await QuizService.resetDailySyncCounter();
                  await _loadOfflineStats();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '🔄 Daily sync counter reset! You now have 4 syncs available.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.restore, color: AppTheme.accent),
              tooltip: 'Reset Sync Counter',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Practice for FIA exams with fresh questions',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.cloud_sync, color: AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Auto-synced • ${QuizService.getTotalQuestions()} questions • ${_offlineStats['syncsRemaining'] ?? 4}/4 syncs',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () async {
                // Navigate to offline questions and refresh stats when returning
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OfflineQuestionsScreen(
                      onDataChanged: () async {
                        await _loadOfflineStats();
                      },
                    ),
                  ),
                );
                // Refresh offline stats when returning
                await _loadOfflineStats();
              },
              icon: const Icon(Icons.offline_bolt, color: AppTheme.accent),
              tooltip: 'Offline Questions',
            ),
            // IconButton(
            //   onPressed: () async {
            //     // Reset daily sync counter for testing
            //     await QuizService.resetDailySyncCounter();
            //     await _loadOfflineStats();
            //     if (mounted) {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(
            //           content: Text(
            //             '🔄 Daily sync counter reset! You now have 4 syncs available.',
            //           ),
            //           duration: Duration(seconds: 2),
            //         ),
            //       );
            //     }
            //   },
            //   icon: const Icon(Icons.refresh_outlined, color: AppTheme.accent),
            //   tooltip: 'Reset Sync Counter',
            // ),
            IconButton(
              onPressed: _refreshQuestions,
              icon: const Icon(Icons.refresh, color: AppTheme.accent),
              tooltip: 'Refresh Questions',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '📊',
                  'Questions Answered',
                  QuizService.getTotalAnswered().toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '🏆',
                  'Best Score',
                  '${QuizService.getBestScore()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '💾',
                  'Offline Sets',
                  _offlineStats['totalSets']?.toString() ?? '0',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '📁',
                  'Saved Questions',
                  _offlineStats['totalQuestions']?.toString() ?? '0',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSetupCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Setup',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Question Count
          _buildOptionSection(
            '📝 Questions',
            'How many questions?',
            Row(
              children: [10, 15, 20, 25, 30].map((count) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildOptionChip(
                      count.toString(),
                      _questionCount == count,
                      () => setState(() => _questionCount = count),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Timer
          _buildOptionSection(
            '⏱️ Timer',
            'Seconds per question',
            Row(
              children: [30, 45, 60, 90, 120].map((seconds) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildOptionChip(
                      '${seconds}s',
                      _timerSeconds == seconds,
                      () => setState(() => _timerSeconds = seconds),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Mode
          _buildOptionSection(
            '🎯 Mode',
            'Quiz type',
            Row(
              children: [
                Expanded(
                  child: _buildOptionChip(
                    '📖 Practice',
                    _mode == 'practice',
                    () => setState(() => _mode = 'practice'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOptionChip(
                    '🔥 Exam',
                    _mode == 'exam',
                    () => setState(() => _mode = 'exam'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSection(String icon, String subtitle, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon.split(' ')[0], style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              icon.split(' ')[1],
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildOptionChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.1)
              : AppTheme.surface2,
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                '🚀 Start Quiz ($_questionCount questions)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
