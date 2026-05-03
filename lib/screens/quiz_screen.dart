import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/question.dart';
import '../models/quiz_category.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final int timerSeconds;
  final String mode;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.timerSeconds,
    required this.mode,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  List<int?> _answers = [];
  int _correct = 0;
  int _wrong = 0;
  int _streak = 0;
  int? _selectedAnswer;
  bool _answered = false;
  Timer? _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.questions.length, null);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.timerSeconds > 0) {
      _timeLeft = widget.timerSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _timeLeft--;
          if (_timeLeft <= 0) {
            _timer?.cancel();
            if (!_answered) {
              _timeUp();
            }
          }
        });
      });
    }
  }

  void _timeUp() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('⏰ Time\'s up!')));
    _revealAnswer(-1);
  }

  void _selectAnswer(int index) {
    if (_answered) return;

    setState(() {
      _selectedAnswer = index;
    });

    _timer?.cancel();
    _answers[_currentIndex] = index;
    _revealAnswer(index);
  }

  void _revealAnswer(int chosen) {
    final question = widget.questions[_currentIndex];
    final correct = question.correct;
    final skipped = chosen == -1;

    setState(() {
      _answered = true;

      if (!skipped && chosen == correct) {
        _correct++;
        _streak++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Correct!'),
            backgroundColor: AppTheme.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else if (!skipped) {
        _wrong++;
        _streak = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Wrong'),
            backgroundColor: AppTheme.red,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        _streak = 0;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= widget.questions.length) {
      _showResults();
    } else {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      _startTimer();
    }
  }

  void _showResults() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          questions: widget.questions,
          answers: _answers,
          correct: _correct,
          wrong: _wrong,
        ),
      ),
    );
  }

  void _quitQuiz() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Quit Quiz?', style: TextStyle(color: AppTheme.text)),
        content: const Text(
          'Are you sure you want to quit this quiz?',
          style: TextStyle(color: AppTheme.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quit', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.questions.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(progress),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_streak >= 3) _buildStreakBadge(),
                    _buildQuestionCard(question),
                    const SizedBox(height: 18),
                    _buildOptions(question),
                    if (_answered &&
                        (widget.mode == 'practice' ||
                            _selectedAnswer != question.correct))
                      _buildExplanation(question),
                    const SizedBox(height: 18),
                    _buildNavigationButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Q ${_currentIndex + 1}/${widget.questions.length}',
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, Color(0xFF0ea5e9)],
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (widget.timerSeconds > 0) _buildTimer(),
              const SizedBox(width: 10),
              _buildLiveScore(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final isWarning = _timeLeft <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? AppTheme.red.withOpacity(0.1) : AppTheme.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Text('⏱', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '${_timeLeft}s',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isWarning ? AppTheme.red : AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveScore() {
    return Row(
      children: [
        Text(
          '✓ $_correct',
          style: GoogleFonts.syne(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.green,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '✗ $_wrong',
          style: GoogleFonts.syne(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.amber.withOpacity(0.1),
        border: Border.all(color: AppTheme.amber.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '🔥 $_streak in a row! Keep going!',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.amber,
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final categoryName = QuizCategory.categories
        .firstWhere(
          (c) => c.slug == question.category,
          orElse: () => const QuizCategory(name: 'General', slug: ''),
        )
        .name;

    return Card(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accent, Color(0xFF0ea5e9)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName.toUpperCase(),
                  style: GoogleFonts.syne(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  question.q,
                  style: GoogleFonts.syne(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text,
                    height: 1.5,
                  ),
                ),
                if (question.urdu.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 8),
                  Text(
                    question.urdu,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(Question question) {
    const labels = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Column(
      children: List.generate(question.options.length, (index) {
        final isCorrect = index == question.correct;
        final isSelected = index == _selectedAnswer;
        final showResult = _answered;

        Color borderColor = AppTheme.border;
        Color bgColor = AppTheme.surface2;
        Color labelBg = AppTheme.surface;
        Color labelColor = AppTheme.muted;
        Widget? icon;

        if (showResult) {
          if (isCorrect) {
            borderColor = AppTheme.green;
            bgColor = AppTheme.green.withOpacity(0.09);
            labelBg = AppTheme.green;
            labelColor = Colors.white;
            icon = const Icon(Icons.check, color: AppTheme.green, size: 20);
          } else if (isSelected) {
            borderColor = AppTheme.red;
            bgColor = AppTheme.red.withOpacity(0.07);
            labelBg = AppTheme.red;
            labelColor = Colors.white;
            icon = const Icon(Icons.close, color: AppTheme.red, size: 20);
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          child: InkWell(
            onTap: _answered ? null : () => _selectAnswer(index),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: labelBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      question.options[index],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.text,
                      ),
                    ),
                  ),
                  if (icon != null) ...[const SizedBox(width: 8), icon],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildExplanation(Question question) {
    const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
    final isCorrect = _selectedAnswer == question.correct;
    final skipped = _selectedAnswer == -1;

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.amber.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'EXPLANATION',
                  style: GoogleFonts.syne(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.amber,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  skipped
                      ? 'Correct: ${labels[question.correct]}. ${question.options[question.correct]}'
                      : isCorrect
                      ? '✓ Correct!'
                      : 'Correct: ${labels[question.correct]}. ${question.options[question.correct]}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isCorrect ? AppTheme.green : AppTheme.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (question.explanation.isNotEmpty)
            Html(
              data: question.explanation,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(14),
                  color: const Color(0xFF94a3b8),
                  lineHeight: const LineHeight(1.75),
                ),
                "strong": Style(color: AppTheme.text),
                "b": Style(color: AppTheme.text),
              },
            )
          else
            Text(
              'The correct answer is ${question.options[question.correct]}.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94a3b8),
                height: 1.75,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(onPressed: _quitQuiz, child: const Text('Quit')),
        const SizedBox(width: 10),
        if (_answered)
          ElevatedButton(onPressed: _nextQuestion, child: const Text('Next →')),
      ],
    );
  }
}
