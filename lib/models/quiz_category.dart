class QuizCategory {
  final String name;
  final String slug;

  const QuizCategory({required this.name, required this.slug});

  static const List<QuizCategory> categories = [
    QuizCategory(name: 'All', slug: ''),
    QuizCategory(name: 'Islamic Studies', slug: 'islamic-studies-mcqs'),
    QuizCategory(name: 'Pak Study', slug: 'pak-study'),
    QuizCategory(name: 'Computer', slug: 'computer'),
    QuizCategory(name: 'English', slug: 'english'),
    QuizCategory(name: 'General Knowledge', slug: 'general-knowledge'),
    QuizCategory(name: 'General Science', slug: 'general-science'),
    QuizCategory(name: 'Everyday Science', slug: 'everyday-science'),
    QuizCategory(name: 'Pedagogy', slug: 'pedagogy'),
    QuizCategory(name: 'Maths', slug: 'maths-mcqs'),
    QuizCategory(name: 'Urdu', slug: 'urdu-mcqs'),
    QuizCategory(
      name: 'Monthly Current Affairs',
      slug: 'monthly-current-affairs',
    ),
    QuizCategory(
      name: 'Yearly Current Affairs',
      slug: 'yearly-current-affairs',
    ),
    QuizCategory(
      name: 'Pakistan Current Affairs',
      slug: 'pakistan-current-affairs',
    ),
    QuizCategory(
      name: 'International Affairs',
      slug: 'international-current-affairs',
    ),
    QuizCategory(
      name: 'Guess Paper (Govt Jobs)',
      slug: 'guess-paper-for-all-govt-jobs-test',
    ),
    QuizCategory(name: 'First Aid', slug: 'first-aid-mcqs'),
    QuizCategory(name: 'Accounting', slug: 'accounting'),
    QuizCategory(name: 'LAW', slug: 'law'),
  ];
}
