import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/main_nav_shell.dart';
import 'services/category_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // Request permissions (iOS)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}

class NotificationsService {
  static Future<void> showOverspendingAlert(double spent, double limit) async {
    final currency = NumberFormat.simpleCurrency(locale: 'en_US');
    await flutterLocalNotificationsPlugin.show(
      0,
      'Budget Exceeded!',
      'You have spent ${currency.format(spent)} out of your budget (${currency.format(limit)}).',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'overspending_channel',
          'Overspending Alerts',
          channelDescription: 'Alerts when you exceed your budget',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CategoryService().insertDefaultCategories();
  await setupNotifications();
  runApp(const ProviderScope(child: StuBudgetApp()));
}

class StuBudgetApp extends ConsumerWidget {
  const StuBudgetApp({super.key});

  static const Color kLightBlue = Color(0xFF4F90FF);
  static const Color kDarkNavBg = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'StuBudget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kLightBlue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: kLightBlue,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: kLightBlue,
          unselectedItemColor: Colors.black54,
          selectedIconTheme: const IconThemeData(color: kLightBlue),
          unselectedIconTheme: const IconThemeData(color: Colors.black54),
          showUnselectedLabels: true,
          showSelectedLabels: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kLightBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: kLightBlue,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: kDarkNavBg,
          selectedItemColor: kLightBlue,
          unselectedItemColor: Colors.grey[400],
          selectedIconTheme: const IconThemeData(color: kLightBlue),
          unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
          showUnselectedLabels: true,
          showSelectedLabels: true,
        ),
      ),
      themeMode: themeMode,
      home: const MainNavShell(),
    );
  }
}

/// Placeholder widget for home screen. Will be replaced in later steps.
class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StuBudget')),
      body: const Center(
        child: Text('Welcome to StuBudget!', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}
