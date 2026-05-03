import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';
import '../services/quiz_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  final List<Question> questions;
  final List<int?> answers;
  final int correct;
  final int wrong;

  const ResultsScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.correct,
    required this.wrong,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _updateStats();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateStats() {
    final percentage = ((widget.correct / widget.questions.length) * 100)
        .round();
    QuizService.updateStats(widget.questions.length, percentage);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final skipped = total - widget.correct - widget.wrong;
    final percentage = ((widget.correct / total) * 100).round();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildGradeArea(percentage),
              const SizedBox(height: 28),
              _buildScoreRing(percentage),
              const SizedBox(height: 32),
              _buildStatsGrid(widget.correct, widget.wrong, skipped),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 36),
              _buildReviewSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeArea(int percentage) {
    String emoji, title, description;
    Color color;

    if (percentage >= 90) {
      emoji = '🏆';
      title = 'Outstanding!';
      description = 'Exam-ready. Exceptional performance!';
      color = AppTheme.green;
    } else if (percentage >= 75) {
      emoji = '🌟';
      title = 'Excellent!';
      description = 'Great work — a few more sessions and you\'ll ace it.';
      color = AppTheme.green;
    } else if (percentage >= 60) {
      emoji = '👍';
      title = 'Good Job!';
      description = 'Solid performance. Keep practicing.';
      color = AppTheme.amber;
    } else if (percentage >= 40) {
      emoji = '📚';
      title = 'Keep Studying';
      description = 'Review the explanations and try again.';
      color = AppTheme.amber;
    } else {
      emoji = '💪';
      title = 'Don\'t Give Up!';
      description = 'Every attempt makes you stronger.';
      color = AppTheme.red;
    }

    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppTheme.muted),
        ),
      ],
    );
  }

  Widget _buildScoreRing(int percentage) {
    final color = percentage >= 75
        ? AppTheme.green
        : percentage >= 50
        ? AppTheme.amber
        : AppTheme.red;

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(150, 150),
                painter: _RingPainter(
                  progress: _animation.value * (percentage / 100),
                  color: color,
                ),
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percentage%',
                style: GoogleFonts.syne(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SCORE',
                style: GoogleFonts.syne(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int correct, int wrong, int skipped) {
    return Row(
      children: [
        Expanded(child: _buildStatBox('$correct', 'Correct', AppTheme.green)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatBox('$wrong', 'Wrong', AppTheme.red)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatBox('$skipped', 'Skipped', AppTheme.accent)),
      ],
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.syne(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
          icon: const Text('🏠'),
          label: const Text('Home'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
          icon: const Text('🔄'),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    final wrongQuestions = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final userAnswer = widget.answers[i];

      if (userAnswer != question.correct) {
        wrongQuestions.add({'question': question, 'userAnswer': userAnswer});
      }
    }

    if (wrongQuestions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              '🎉 Perfect Score! All correct!',
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.green,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REVIEW MISTAKES (${wrongQuestions.length})',
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: AppTheme.border),
            ],
          ),
        ),
        ...wrongQuestions.map((item) {
          final question = item['question'] as Question;
          final userAnswer = item['userAnswer'] as int?;
          return _buildReviewItem(question, userAnswer);
        }),
      ],
    );
  }

  Widget _buildReviewItem(Question question, int? userAnswer) {
    const labels = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppTheme.red, width: 3)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(13),
            bottomLeft: Radius.circular(13),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.q,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (userAnswer != null && userAnswer != -1)
                  _buildAnswerChip(
                    '✗ ${question.options[userAnswer]}',
                    AppTheme.red,
                  )
                else
                  _buildAnswerChip('⏭ Skipped', AppTheme.red),
                _buildAnswerChip(
                  '✓ ${question.options[question.correct]}',
                  AppTheme.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    final bgPaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
