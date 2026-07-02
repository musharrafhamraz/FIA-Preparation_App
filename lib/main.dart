import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/quiz_service.dart';
import 'services/notification_service.dart';
import 'services/notification_service_test.dart';
import 'services/simple_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await QuizService.init();
  await NotificationService.init();
  await NotificationTestService.init();
  await SimpleNotificationService.init();

  // Check if it's a reminder time and show notification
  await SimpleNotificationService.checkAndShowReminderIfTime();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TestPoint Quiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
