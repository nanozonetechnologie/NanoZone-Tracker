import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if timezone detection fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Check if a notification has already been shown for a specific threshold
  static Future<bool> _hasNotificationBeenShown(
      int threshold, int month, int year) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'budget_notif_${threshold}_${month}_$year';
    return prefs.getBool(key) ?? false;
  }

  /// Mark a notification as shown for a specific threshold
  static Future<void> _markNotificationAsShown(
      int threshold, int month, int year) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'budget_notif_${threshold}_${month}_$year';
    await prefs.setBool(key, true);
  }

  /// Reset notification tracking for a specific month/year (when budget changes)
  static Future<void> resetNotificationsForMonth(int month, int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('budget_notif_50_${month}_$year');
    await prefs.remove('budget_notif_75_${month}_$year');
    await prefs.remove('budget_notif_90_${month}_$year');
    await prefs.remove('budget_notif_100_${month}_$year');
  }

  static Future<void> showBudgetAlert(
      double percentage, String month, int monthNum, int year) async {
    // Determine which threshold was crossed
    int threshold = 0;
    if (percentage >= 100) {
      threshold = 100;
    } else if (percentage >= 90) {
      threshold = 90;
    } else if (percentage >= 75) {
      threshold = 75;
    } else if (percentage >= 50) {
      threshold = 50;
    }

    if (threshold == 0) return;

    // Check if this notification has already been shown
    final alreadyShown = await _hasNotificationBeenShown(threshold, monthNum, year);
    if (alreadyShown) {
      return; // Don't show the notification again
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications for budget alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      threshold, // Use threshold as notification ID so each is unique
      'Budget Alert!',
      'You\'ve spent $threshold% of your budget for $month',
      platformChannelSpecifics,
    );

    // Mark this notification as shown
    await _markNotificationAsShown(threshold, monthNum, year);
  }

  static Future<void> scheduleWeekendNotification() async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'Weekend Budget Review',
        'Check your weekly spending and plan ahead!',
        _nextInstanceOfSaturdayTenAM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekend_notification',
            'Weekend Notification',
            channelDescription: 'Weekly reminder to check your budget.',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
  }

  static tz.TZDateTime _nextInstanceOfSaturdayTenAM() {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(10, 0);
    while (scheduledDate.weekday != DateTime.saturday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> scheduleMonthEndNotification() async {
    // Cancel any existing month-end notification
    await _flutterLocalNotificationsPlugin.cancel(2);

    // Schedule a repeating notification for month-end
    await _flutterLocalNotificationsPlugin.zonedSchedule(
        2,
        'Monthly Budget Summary',
        'Calculating your monthly summary...',
        _nextInstanceOfLastDayOfMonth8PM(),
        const NotificationDetails(
          android: AndroidNotificationDetails('month_end_notification',
              'Month End Notification',
              channelDescription: 'Notification for month-end summary'),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime);
  }

  /// Show detailed month-end summary notification with actual data
  static Future<void> showMonthEndSummary(
    double totalExpenses,
    double totalSavings,
    double budget,
    String monthName,
  ) async {
    final percentageUsed = budget > 0 ? (totalExpenses / budget * 100).toStringAsFixed(1) : '0';
    final savingsFormatted = totalSavings >= 0
        ? '₹${totalSavings.toStringAsFixed(0)} saved'
        : '₹${totalSavings.abs().toStringAsFixed(0)} overspent';

    String title = '📊 $monthName Summary';
    String body = 'Spent: ₹${totalExpenses.toStringAsFixed(0)} | $savingsFormatted | Budget: $percentageUsed% used';

    // Add emoji based on performance
    if (totalSavings > 0 && totalExpenses < budget * 0.8) {
      title = '🎉 $monthName - Great Job!';
    } else if (totalExpenses > budget) {
      title = '⚠️ $monthName - Over Budget!';
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'month_end_summary',
      'Monthly Summary',
      channelDescription: 'Detailed monthly expense and savings summary',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      999, // Unique ID for month-end summary
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Check if it's month-end and show summary with actual data
  static Future<void> checkAndShowMonthEndSummary() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final lastNotificationKey = 'last_month_end_notif_${now.month}_${now.year}';

    // Check if we've already shown notification for this month
    final alreadyShown = prefs.getBool(lastNotificationKey) ?? false;

    // Show notification if:
    // 1. It's the last 3 days of the month, AND
    // 2. We haven't shown it yet this month
    final isMonthEnd = now.day >= DateTime(now.year, now.month + 1, 0).day - 2;

    if (isMonthEnd && !alreadyShown) {
      try {
        // Get current month data
        final month = now.month;
        final year = now.year;
        final monthName = DateFormat.MMMM().format(now);

        // Fetch expenses for the month
        final totalExpenses = await DBHelper.getExpensesSumForMonth(month, year);

        // Fetch budget for the month
        final budgetData = await DBHelper.getBudgetForMonth(month, year);
        final budget = budgetData?['amount'] as double? ?? 0.0;

        // Calculate savings
        final totalSavings = budget - totalExpenses;

        // Show the detailed notification
        await showMonthEndSummary(totalExpenses, totalSavings, budget, monthName);

        // Mark as shown for this month
        await prefs.setBool(lastNotificationKey, true);
      } catch (e) {
        // If there's an error, show a generic notification
        await _flutterLocalNotificationsPlugin.show(
          999,
          'Monthly Summary',
          'Check your expenses and savings for this month!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'month_end_summary',
              'Monthly Summary',
              channelDescription: 'Monthly expense summary',
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    }
  }

  static tz.TZDateTime _nextInstanceOfLastDayOfMonth8PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month + 1, 0, 20);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(tz.local, now.year, now.month + 2, 0, 20);
    }
    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// TEST METHOD: Manually trigger month-end notification (for testing)
  /// Call this from anywhere to test the notification immediately
  static Future<void> testMonthEndNotification() async {
    try {
      final now = DateTime.now();
      final month = now.month;
      final year = now.year;
      final monthName = DateFormat.MMMM().format(now);

      final totalExpenses = await DBHelper.getExpensesSumForMonth(month, year);
      final budgetData = await DBHelper.getBudgetForMonth(month, year);
      final budget = budgetData?['amount'] as double? ?? 0.0;
      final totalSavings = budget - totalExpenses;

      await showMonthEndSummary(totalExpenses, totalSavings, budget, monthName);
    } catch (e) {
      // Show error notification
      await _flutterLocalNotificationsPlugin.show(
        999,
        'Test Notification',
        'Error: $e',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'month_end_summary',
            'Monthly Summary',
            channelDescription: 'Monthly expense summary',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }
}
