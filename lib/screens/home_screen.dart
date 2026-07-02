import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quiz_category.dart';
import '../models/question.dart';
import '../services/quiz_service.dart';
import '../services/notification_service.dart';
import '../services/notification_service_test.dart';
import '../services/simple_notification_service.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  QuizDatabase? _database;
  bool _isLoading = true;
  String _selectedCategory = '';
  int _questionCount = 20;
  int _timerSeconds = 45;
  String _mode = 'practice';
  Map<String, int> _categoryCounts = {};

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    final db = await QuizService.loadDatabase();
    setState(() {
      _database = db;
      _isLoading = false;
      if (db != null) {
        _categoryCounts = QuizService.getCategoryCounts();
      }
    });
  }

  void _startQuiz() async {
    if (_database == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No questions available')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('🌐 Fetching fresh questions...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Fetch fresh questions on-demand
      final questions = await QuizService.fetchFreshQuestions(
        _selectedCategory,
        _questionCount,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ No questions in this category')),
          );
        }
        return;
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded ${questions.length} fresh questions!'),
            backgroundColor: AppTheme.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Navigate to quiz
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
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to fetch questions. Using cached data.'),
            backgroundColor: AppTheme.amber,
          ),
        );
      }

      // Fallback to cached questions
      final questions = QuizService.getRandomQuestions(
        _selectedCategory,
        _questionCount,
      );

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ No questions available')),
          );
        }
        return;
      }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [Color(0x1222d3ee), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _database == null
                    ? _buildNoDataBanner()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final totalAnswered = QuizService.getTotalAnswered();
    final bestScore = QuizService.getBestScore();
    final totalQuestions = _database?.questions.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg.withOpacity(0.85),
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '⚡ Sarkari Tayyari Quiz ',
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accent,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PK',
                  style: GoogleFonts.syne(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.bg,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPill('Questions', totalQuestions.toString()),
              _buildPill('Answered', totalAnswered.toString()),
              _buildPill('Best', bestScore > 0 ? '$bestScore%' : '—'),
              _buildStatusBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (_isLoading) {
      return _buildBadge('⏳ Loading DB...', AppTheme.amber);
    } else if (_database == null) {
      return _buildBadge('✗ No Data', AppTheme.red);
    } else {
      final count = _database!.questions.length;
      return _buildBadge('✓ $count Questions', AppTheme.green);
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNoDataBanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: AppTheme.amber.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppTheme.amber.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📂 questions.json not found',
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.amber,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please add a questions.json file to the assets folder.',
                  style: TextStyle(color: AppTheme.amber, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHero(),
          const SizedBox(height: 24),
          _buildSettingsCard(),
          const SizedBox(height: 16),
          _buildNotificationCard(),
          const SizedBox(height: 16),
          _buildCategoryCard(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startQuiz,
              child: const Text('🚀 Start Quiz'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'OFFLINE QUIZ BANK · Sarkari Tayyari',
            style: GoogleFonts.syne(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.accent,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.text, AppTheme.accent, AppTheme.amber],
            stops: [0.2, 0.55, 1.0],
          ).createShader(bounds),
          child: Text(
            'Ace Every\nGovernment Exam',
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'All questions stored locally — works offline,\nloads instantly, always up to date.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppTheme.muted, height: 1.65),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUIZ SETTINGS',
              style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.muted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildQuestionCountDropdown()),
                const SizedBox(width: 14),
                Expanded(child: _buildTimerDropdown()),
              ],
            ),
            const SizedBox(height: 14),
            _buildModeToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCountDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questions',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(9),
          ),
          child: DropdownButton<int>(
            value: _questionCount,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppTheme.surface2,
            style: const TextStyle(color: AppTheme.text, fontSize: 14),
            items: [10, 15, 20, 30, 50].map((count) {
              return DropdownMenuItem(
                value: count,
                child: Text('$count Questions'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _questionCount = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timer per Question',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(9),
          ),
          child: DropdownButton<int>(
            value: _timerSeconds,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppTheme.surface2,
            style: const TextStyle(color: AppTheme.text, fontSize: 14),
            items: const [
              DropdownMenuItem(value: 0, child: Text('No Timer')),
              DropdownMenuItem(value: 30, child: Text('30 seconds')),
              DropdownMenuItem(value: 45, child: Text('45 seconds')),
              DropdownMenuItem(value: 60, child: Text('60 seconds')),
              DropdownMenuItem(value: 90, child: Text('90 seconds')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _timerSeconds = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mode',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          children: [
            _buildToggleButton(
              '📖 Practice — show explanations',
              'practice',
              _mode == 'practice',
            ),
            _buildToggleButton(
              '🎯 Exam — hide until end',
              'exam',
              _mode == 'exam',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, String value, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _mode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.surface2,
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? AppTheme.bg : AppTheme.muted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'DAILY REMINDERS ',
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('🔔', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Get notified to take a quiz at these times:',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTimeChip('🌅 6:00 AM', true),
                _buildTimeChip('🕛 12:00 PM', true),
                _buildTimeChip('🌆 6:00 PM', true),
                _buildTimeChip('🌙 12:00 AM', true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final success =
                          await NotificationService.enableRemindersWithPermission();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? '✅ Reminders enabled! You\'ll be notified at 6 AM, 12 PM, 6 PM, 12 AM'
                                  : '❌ Please grant notification permission',
                            ),
                            backgroundColor: success
                                ? AppTheme.green
                                : AppTheme.red,
                          ),
                        );
                      }
                    },
                    icon: const Text('🔔'),
                    label: const Text('Enable'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await NotificationService.cancelAllReminders();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔕 Reminders disabled'),
                            backgroundColor: AppTheme.muted,
                          ),
                        );
                      }
                    },
                    icon: const Text('🔕'),
                    label: const Text('Disable'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                // First cancel any existing
                await NotificationService.cancelAllReminders();

                // Test notification
                final success =
                    await NotificationService.testBackgroundNotification();

                if (mounted) {
                  if (success) {
                    final count = await NotificationService.getPendingCount();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '⏰ Test notification scheduled for 30 seconds! Pending: $count\nClose the app and wait!',
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Failed to schedule notification'),
                        backgroundColor: AppTheme.red,
                      ),
                    );
                  }
                }
              },
              icon: const Text('🔔'),
              label: const Text('Test Background (30s)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final count = await NotificationService.getPendingCount();
                final message = '📋 Pending notifications: $count';
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              },
              icon: const Text('📋'),
              label: const Text('Check Pending'),
            ),
            const SizedBox(height: 15),
            // DEBUG SECTION
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  const Text(
                    '🔧 Debug Tests',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await NotificationTestService.init();
                            await NotificationTestService.testImmediate();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Immediate test sent!'),
                                ),
                              );
                            }
                          },
                          child: const Text('Immediate'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await NotificationTestService.init();
                            await NotificationTestService.testShortDelay();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⏱️ 10-second test scheduled!'),
                                ),
                              );
                            }
                          },
                          child: const Text('10sec'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await NotificationTestService.init();
                      await NotificationTestService.testBackground30Seconds();
                      final count =
                          await NotificationTestService.getPendingCount();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🎯 Debug 30s test! Pending: $count\nClose app and wait!',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: AppTheme.accent,
                    ),
                    child: const Text('Debug 30s Test'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await NotificationTestService.init();
                      await NotificationTestService.testWithExactAlarmPermission();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎯 Testing exact alarm permission!'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Test Exact Alarm Permission'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await SimpleNotificationService.init();
                      await SimpleNotificationService.triggerReminderNow();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '✅ Manual reminder triggered! More will follow in 1-3 minutes',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Manual Reminder (Workaround)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accent.withOpacity(0.1) : AppTheme.surface2,
        border: Border.all(color: isActive ? AppTheme.accent : AppTheme.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? AppTheme.accent : AppTheme.muted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'CATEGORY ',
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  '(select one or leave on All)',
                  style: TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: QuizCategory.categories.map((cat) {
                final count = cat.slug.isEmpty
                    ? _database?.questions.length ?? 0
                    : _categoryCounts[cat.slug] ?? 0;
                return _buildCategoryButton(cat, count);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(QuizCategory category, int count) {
    final isSelected = _selectedCategory == category.slug;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category.slug),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withOpacity(0.08)
              : AppTheme.surface2,
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.accent : AppTheme.muted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${count.toString()} MCQs',
                style: const TextStyle(fontSize: 10, color: AppTheme.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
