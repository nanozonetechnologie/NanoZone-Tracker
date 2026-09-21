import 'package:exptrackerforhybridos/providers/account_provider.dart';
import 'package:exptrackerforhybridos/providers/budget_provider.dart';
import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/providers/monthly_savings_provider.dart';
import 'package:exptrackerforhybridos/providers/savings_goal_provider.dart';
import 'package:exptrackerforhybridos/providers/feature_provider.dart';
import 'package:exptrackerforhybridos/screens/main_navigation_screen.dart';
import 'package:exptrackerforhybridos/screens/feature_settings_screen.dart';
import 'package:exptrackerforhybridos/screens/splash_screen.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:exptrackerforhybridos/helpers/notification_helper.dart';
import 'package:exptrackerforhybridos/helpers/db_helper.dart';

/// Main entry point - Must be ultra-lightweight
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => BudgetProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => MonthlySavingsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => SavingsGoalProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => AccountProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => FeatureProvider(), lazy: true),
      ],
      child: const AppInitializer(
        child: MaterialApp(
          title: 'NanoZone Budget Tracker',
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        ),
      ),
    );
  }
}

/// AppInitializer widget that has access to providers
class AppInitializer extends StatefulWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    try {
      debugPrint('🚀 Starting post-frame initialization...');

      await _initializeDatabase();
      await _initializeProviders();
      _setupBackgroundTasks();

      debugPrint('✅ App initialization complete');
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      await DBHelper.database();
      debugPrint('✅ Database initialized');
    } catch (e) {
      debugPrint('❌ Database init error: $e');
    }
  }

  Future<void> _initializeProviders() async {
    if (!mounted) return;

    try {
      await Future.wait([
        Provider.of<ExpenseProvider>(context, listen: false).init(),
        Provider.of<BudgetProvider>(context, listen: false).init(),
        Provider.of<MonthlySavingsProvider>(context, listen: false).init(),
        Provider.of<SavingsGoalProvider>(context, listen: false).fetchAllGoals(),
        Provider.of<AccountProvider>(context, listen: false).init(),
        Provider.of<FeatureProvider>(context, listen: false).init(),
      ]);
      debugPrint('✅ All providers initialized');
    } catch (e) {
      debugPrint('❌ Provider init error: $e');
    }
  }

  void _setupBackgroundTasks() {
    Future.microtask(() async {
      try {
        await NotificationHelper.init();

        await Future.delayed(const Duration(milliseconds: 500));

        final permission = await Permission.scheduleExactAlarm.request();
        if (permission.isGranted) {
          await NotificationHelper.scheduleWeekendNotification();
          await NotificationHelper.scheduleMonthEndNotification();
          await NotificationHelper.checkAndShowMonthEndSummary();
        }
        debugPrint('✅ Notifications configured');
      } catch (e) {
        debugPrint('❌ Notification setup error: $e');
      }
    });

    Future.microtask(() async {
      try {
        await Future.delayed(const Duration(seconds: 1));
        await Permission.notification.request();
        debugPrint('✅ Permissions requested');
      } catch (e) {
        debugPrint('❌ Permission request error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NanoZone Budget Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/settings': (context) => const FeatureSettingsScreen(),
      },
      initialRoute: '/',
    );
  }
}
