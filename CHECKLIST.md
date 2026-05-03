# 📋 Setup Checklist

Use this checklist to get your quiz app up and running!

## ✅ Initial Setup

- [ ] **Install Flutter** (if not already installed)
  - Run `flutter doctor` to verify installation
  
- [ ] **Navigate to project directory**
  ```bash
  cd fiaquizapp
  ```

- [ ] **Install dependencies**
  ```bash
  flutter pub get
  ```

- [ ] **Test with sample data**
  ```bash
  flutter run
  ```
  - App should launch with 5 sample questions
  - Test all features (timer, categories, modes)
  - Check that everything works as expected

## 📝 Add Your Questions

- [ ] **Prepare your questions.json file**
  - Verify JSON format is correct
  - Check all category slugs match the valid list
  - Ensure `correct` indices are valid (0-based)
  - Test with a JSON validator

- [ ] **Replace the sample file**
  ```bash
  # Backup the sample first (optional)
  cp assets/questions.json assets/questions.sample.json
  
  # Copy your questions file
  cp /path/to/your/questions.json assets/questions.json
  ```

- [ ] **Test with your data**
  ```bash
  flutter run
  ```
  - Verify all questions load correctly
  - Check different categories
  - Test Urdu text display (if applicable)
  - Verify explanations render properly

## 🎨 Customization (Optional)

- [ ] **Update app name**
  - Edit `pubspec.yaml` → change `name: fiaquizapp`
  - Edit `android/app/src/main/AndroidManifest.xml` → change `android:label`
  - Edit `ios/Runner/Info.plist` → change `CFBundleName`

- [ ] **Change app icon**
  - Add `flutter_launcher_icons` package
  - Create icon assets
  - Run icon generator

- [ ] **Customize colors** (if desired)
  - Edit `lib/theme/app_theme.dart`
  - Change color constants
  - Test on both light and dark backgrounds

- [ ] **Modify branding**
  - Edit `lib/screens/home_screen.dart`
  - Change "TestPoint Quiz" to your app name
  - Update hero text and descriptions

## 🧪 Testing

- [ ] **Test all quiz settings**
  - [ ] 10, 15, 20, 30, 50 questions
  - [ ] All timer options (0s, 30s, 45s, 60s, 90s)
  - [ ] Practice mode
  - [ ] Exam mode

- [ ] **Test all categories**
  - [ ] "All" category
  - [ ] Each individual category
  - [ ] Verify question counts are correct

- [ ] **Test quiz flow**
  - [ ] Answer correctly → check green feedback
  - [ ] Answer incorrectly → check red feedback
  - [ ] Let timer expire → check skip behavior
  - [ ] Build a streak → check streak badge
  - [ ] Complete quiz → check results screen

- [ ] **Test results screen**
  - [ ] Score ring animation
  - [ ] Correct grade and emoji
  - [ ] Stats accuracy (correct, wrong, skipped)
  - [ ] Review mistakes section
  - [ ] Home and Try Again buttons

- [ ] **Test persistence**
  - [ ] Complete a quiz
  - [ ] Close and reopen app
  - [ ] Verify stats updated (total answered, best score)

- [ ] **Test edge cases**
  - [ ] Quiz with 0 timer
  - [ ] All correct answers
  - [ ] All wrong answers
  - [ ] Quit mid-quiz
  - [ ] Very long questions
  - [ ] Questions with 2 options
  - [ ] Questions with 6 options

## 📱 Device Testing

- [ ] **Test on Android**
  - [ ] Phone (small screen)
  - [ ] Tablet (large screen)
  - [ ] Portrait orientation
  - [ ] Landscape orientation

- [ ] **Test on iOS** (if applicable)
  - [ ] iPhone
  - [ ] iPad
  - [ ] Portrait orientation
  - [ ] Landscape orientation

## 🚀 Build for Release

- [ ] **Update version number**
  - Edit `pubspec.yaml` → `version: 1.0.0+1`

- [ ] **Build Android APK**
  ```bash
  flutter build apk --release
  ```
  - [ ] Test the APK on a real device
  - [ ] Verify app size is reasonable
  - [ ] Check that all features work

- [ ] **Build Android App Bundle** (for Play Store)
  ```bash
  flutter build appbundle --release
  ```

- [ ] **Build iOS** (if applicable)
  ```bash
  flutter build ios --release
  ```
  - [ ] Test on real iOS device
  - [ ] Verify all features work

## 📦 Deployment

### Android (Google Play Store)

- [ ] **Create Play Console account**
- [ ] **Prepare store listing**
  - [ ] App name
  - [ ] Short description
  - [ ] Full description
  - [ ] Screenshots (phone & tablet)
  - [ ] Feature graphic
  - [ ] App icon
- [ ] **Upload app bundle**
- [ ] **Set up pricing & distribution**
- [ ] **Submit for review**

### iOS (App Store)

- [ ] **Create App Store Connect account**
- [ ] **Prepare store listing**
  - [ ] App name
  - [ ] Subtitle
  - [ ] Description
  - [ ] Screenshots (iPhone & iPad)
  - [ ] App icon
- [ ] **Upload build via Xcode**
- [ ] **Submit for review**

## 📊 Post-Launch

- [ ] **Monitor crash reports**
- [ ] **Collect user feedback**
- [ ] **Plan updates**
  - [ ] Add more questions
  - [ ] Fix reported bugs
  - [ ] Add requested features

## 🎯 Optional Enhancements

- [ ] **Add sound effects**
  - Correct answer sound
  - Wrong answer sound
  - Timer warning sound

- [ ] **Add haptic feedback**
  - Vibrate on correct/wrong answer
  - Vibrate on timer warning

- [ ] **Add achievements**
  - Perfect score badge
  - Streak milestones
  - Category completion

- [ ] **Add leaderboard**
  - Local high scores
  - Share scores

- [ ] **Add dark/light theme toggle**
  - Let users choose theme
  - System theme following

- [ ] **Add question bookmarking**
  - Save difficult questions
  - Review bookmarked questions

- [ ] **Add statistics screen**
  - Performance by category
  - Progress over time
  - Accuracy trends

---

## ✨ You're Done!

Once you've completed this checklist, your quiz app is ready for users! 🎉

**Quick Reference:**
- 📖 Full docs: `README.md`
- 🚀 Quick start: `QUICKSTART.md`
- 📊 Overview: `PROJECT_SUMMARY.md`
- ✅ This checklist: `CHECKLIST.md`

Good luck with your app! 🍀
