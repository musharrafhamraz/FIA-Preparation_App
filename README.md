# TestPoint Quiz App - Flutter

A beautiful, offline-first quiz application for government exam preparation, built with Flutter. This is a complete Flutter port of the HTML/JavaScript quiz app.

## Features

✨ **Complete Feature Parity with HTML Version:**
- 🎨 Dark theme with gradient backgrounds matching the original design
- 📚 Multiple quiz categories (Islamic Studies, Pak Study, Computer, English, etc.)
- ⏱️ Configurable timer per question (30s, 45s, 60s, 90s, or no timer)
- 📖 Two modes: Practice (show explanations) and Exam (hide until end)
- 🔥 Streak tracking for consecutive correct answers
- 📊 Detailed results with score ring animation
- 📝 Review wrong answers after quiz completion
- 💾 Persistent stats (total answered, best score)
- 🌐 Support for Urdu text (RTL display)
- 📱 Fully responsive and works offline

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── question.dart         # Question and QuizDatabase models
│   └── quiz_category.dart    # Category definitions
├── screens/
│   ├── home_screen.dart      # Home screen with settings
│   ├── quiz_screen.dart      # Quiz taking screen
│   └── results_screen.dart   # Results and review screen
├── services/
│   └── quiz_service.dart     # Quiz data management and stats
└── theme/
    └── app_theme.dart        # App theme and colors

assets/
└── questions.json            # Quiz questions database
```

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Add Your Questions

Replace the placeholder `assets/questions.json` with your actual questions file. The format should be:

```json
{
  "meta": {
    "count": 1000,
    "last_updated": "2026-05-03",
    "source": "testpointpk"
  },
  "questions": [
    {
      "q": "What is the capital of Pakistan?",
      "urdu": "پاکستان کا دارالحکومت کیا ہے؟",
      "options": [
        "Karachi",
        "Lahore",
        "Islamabad",
        "Peshawar"
      ],
      "correct": 2,
      "explanation": "<p>Islamabad is the capital city of Pakistan.</p>",
      "category": "pak-study"
    }
  ]
}
```

### 3. Run the App

```bash
flutter run
```

## Dependencies

- `shared_preferences: ^2.2.2` - For persistent storage of user stats
- `flutter_html: ^3.0.0-beta.2` - For rendering HTML explanations
- `google_fonts: ^6.1.0` - For Syne and DM Sans fonts

## Color Scheme

The app uses the same color scheme as the HTML version:

- **Background**: `#080c18`
- **Surface**: `#0f1623`
- **Accent**: `#22d3ee` (Cyan)
- **Amber**: `#f59e0b`
- **Green**: `#10b981`
- **Red**: `#ef4444`
- **Text**: `#e2e8f0`
- **Muted**: `#64748b`

## Features Comparison

| Feature | HTML Version | Flutter Version |
|---------|-------------|-----------------|
| Dark Theme | ✅ | ✅ |
| Category Selection | ✅ | ✅ |
| Timer | ✅ | ✅ |
| Practice/Exam Mode | ✅ | ✅ |
| Streak Tracking | ✅ | ✅ |
| Results Screen | ✅ | ✅ |
| Review Mistakes | ✅ | ✅ |
| Persistent Stats | ✅ | ✅ |
| Urdu Support | ✅ | ✅ |
| HTML Explanations | ✅ | ✅ |
| Offline Support | ✅ | ✅ |
| Fresh Scraping | ✅ | ❌ (Not needed in mobile) |

## Screenshots

The app closely matches the HTML version's design with:
- Gradient backgrounds
- Card-based UI
- Smooth animations
- Progress indicators
- Score ring animation

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Notes

- The app works completely offline once the questions.json is bundled
- All user stats are stored locally using SharedPreferences
- The app supports both portrait and landscape orientations
- HTML content in explanations is rendered properly with flutter_html

## License

This is a Flutter port of the TestPoint Quiz web app.
