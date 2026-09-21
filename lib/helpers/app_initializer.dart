import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:exptrackerforhybridos/helpers/notification_helper.dart';
import 'package:exptrackerforhybridos/helpers/db_helper.dart';
import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/providers/budget_provider.dart';
import 'package:exptrackerforhybridos/providers/monthly_savings_provider.dart';
import 'package:provider/provider.dart';

class AppInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    debugPrint('🚀 Starting post-frame initialization...');

    // ignore: use_build_context_synchronously
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final savingsProvider = Provider.of<MonthlySavingsProvider>(context, listen: false);

    await Future.delayed(Duration.zero);
    if (!context.mounted) return;

    try {
      await _initializeDatabase();
      if (!context.mounted) return;

      await Future.wait([
        _initProvider('ExpenseProvider', expenseProvider.init),
        _initProvider('BudgetProvider', budgetProvider.init),
        _initProvider('SavingsProvider', savingsProvider.init),
      ]);
      if (!context.mounted) return;
      debugPrint('✅ All providers initialized');

      _setupNotifications();
      _requestPermissions();

      _isInitialized = true;
      debugPrint('✅ App initialization complete');
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
    }
  }

  static Future<void> _initializeDatabase() async {
    try {
      await DBHelper.database();
      debugPrint('✅ Database initialized');
    } catch (e) {
      debugPrint('❌ Database init error: $e');
    }
  }

  static Future<void> _initProvider(String name, Future<void> Function() initFn) async {
    try {
      await initFn();
    } catch (e) {
      debugPrint('❌ $name init error: $e');
    }
  }

  static void _setupNotifications() {
    Future.microtask(() async {
      try {
        await NotificationHelper.init();

        final permission = await Permission.scheduleExactAlarm.request();
        if (permission.isGranted) {
          await NotificationHelper.scheduleWeekendNotification();
          await NotificationHelper.scheduleMonthEndNotification();
        }
        debugPrint('✅ Notifications configured');
      } catch (e) {
        debugPrint('❌ Notification setup error: $e');
      }
    });
  }

  static void _requestPermissions() {
    Future.microtask(() async {
      try {
        await Permission.notification.request();
        debugPrint('✅ Permissions requested');
      } catch (e) {
        debugPrint('❌ Permission request error: $e');
      }
    });
  }
}
