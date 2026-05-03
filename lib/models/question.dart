class Question {
  final String q;
  final String urdu;
  final List<String> options;
  final int correct;
  final String explanation;
  final String category;

  Question({
    required this.q,
    this.urdu = '',
    required this.options,
    required this.correct,
    this.explanation = '',
    this.category = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      q: json['q'] ?? '',
      urdu: json['urdu'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correct: json['correct'] ?? 0,
      explanation: json['explanation'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'q': q,
      'urdu': urdu,
      'options': options,
      'correct': correct,
      'explanation': explanation,
      'category': category,
    };
  }
}

class QuizDatabase {
  final List<Question> questions;
  final Map<String, dynamic> meta;

  QuizDatabase({required this.questions, required this.meta});

  factory QuizDatabase.fromJson(Map<String, dynamic> json) {
    return QuizDatabase(
      questions:
          (json['questions'] as List?)
              ?.map((q) => Question.fromJson(q))
              .toList() ??
          [],
      meta: json['meta'] ?? {},
    );
  }
}
