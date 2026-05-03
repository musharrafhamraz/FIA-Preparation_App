# Quick Start Guide

## 🚀 Get Started in 3 Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Run the App
```bash
flutter run
```

The app will launch with 5 sample questions to test the functionality.

### Step 3: Add Your Questions
Replace `assets/questions.json` with your full questions database.

---

## 📝 Questions JSON Format

Your `questions.json` file should follow this structure:

```json
{
  "meta": {
    "count": 1000,
    "last_updated": "2026-05-03",
    "source": "testpointpk"
  },
  "questions": [
    {
      "q": "Question text in English",
      "urdu": "سوال اردو میں (optional)",
      "options": [
        "Option A",
        "Option B",
        "Option C",
        "Option D"
      ],
      "correct": 2,
      "explanation": "<p>HTML explanation with <strong>formatting</strong></p>",
      "category": "category-slug"
    }
  ]
}
```

### Field Descriptions:

- **q** (required): The question text in English
- **urdu** (optional): Question text in Urdu (will be displayed RTL)
- **options** (required): Array of answer options (2-6 options supported)
- **correct** (required): Index of correct answer (0-based, so 0 = first option)
- **explanation** (optional): HTML formatted explanation
- **category** (required): Category slug (must match one from the list below)

### Valid Category Slugs:

- `islamic-studies-mcqs`
- `pak-study`
- `computer`
- `english`
- `general-knowledge`
- `general-science`
- `everyday-science`
- `pedagogy`
- `maths-mcqs`
- `urdu-mcqs`
- `monthly-current-affairs`
- `yearly-current-affairs`
- `pakistan-current-affairs`
- `international-current-affairs`
- `guess-paper-for-all-govt-jobs-test`
- `first-aid-mcqs`
- `accounting`
- `law`

---

## 🎨 App Features

### Home Screen
- Select number of questions (10, 15, 20, 30, 50)
- Set timer per question (30s, 45s, 60s, 90s, or no timer)
- Choose mode: Practice (show explanations) or Exam (hide until end)
- Select category or choose "All"
- View stats: total answered, best score

### Quiz Screen
- Progress bar showing current question
- Live timer countdown (if enabled)
- Live score tracking (correct/wrong)
- Streak indicator (3+ correct in a row)
- Question with optional Urdu translation
- Multiple choice options (A, B, C, D...)
- Instant feedback on answer selection
- Explanation shown after answering (in Practice mode)

### Results Screen
- Animated score ring
- Grade with emoji and message
- Detailed stats (correct, wrong, skipped)
- Review all wrong answers
- Options to retry or go home

---

## 🔧 Customization

### Change Colors
Edit `lib/theme/app_theme.dart` to customize the color scheme.

### Add More Categories
Edit `lib/models/quiz_category.dart` to add new categories.

### Modify Timer Options
Edit `lib/screens/home_screen.dart` in the `_buildTimerDropdown()` method.

---

## 📱 Testing

The app includes 5 sample questions covering:
- Pak Study (2 questions with Urdu)
- Computer (1 question)
- General Knowledge (2 questions)

Try different settings:
1. Practice mode with timer
2. Exam mode without timer
3. Different question counts
4. Category filtering

---

## 🐛 Troubleshooting

### "Unable to load asset: assets/questions.json"
- Make sure `assets/questions.json` exists
- Check that `pubspec.yaml` includes the assets section
- Run `flutter clean` and `flutter pub get`

### Questions not showing
- Verify JSON format is correct
- Check that category slugs match exactly
- Ensure `correct` index is within options array bounds

### Urdu text not displaying correctly
- Urdu text should display RTL automatically
- Make sure the text is in the `urdu` field, not `q`

---

## 📦 Building for Release

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS
```bash
flutter build ios --release
```

---

## 💡 Tips

1. **Large Question Banks**: The app handles thousands of questions efficiently
2. **Offline First**: All questions are bundled with the app, no internet needed
3. **Stats Persist**: User stats are saved locally and persist across app restarts
4. **HTML Support**: Explanations support HTML formatting (bold, lists, tables, etc.)
5. **Responsive**: Works on phones and tablets in any orientation

---

## 🎯 Next Steps

1. Replace sample questions with your full database
2. Test thoroughly with different categories
3. Customize colors and branding if needed
4. Build release version
5. Deploy to Play Store / App Store

Enjoy your quiz app! 🎉
