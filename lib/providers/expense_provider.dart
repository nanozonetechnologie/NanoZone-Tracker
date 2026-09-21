import 'package:exptrackerforhybridos/models/expense_model.dart';
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../helpers/notification_helper.dart';
import 'package:intl/intl.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _items = [];
  Map<String, double> _monthlyTrendData = {};
  Map<String, double> _yearlyTrendData = {};
  bool _isInitialized = false;

  List<Expense> get items {
    return [..._items];
  }

  Map<String, double> get monthlyTrendData => _monthlyTrendData;
  Map<String, double> get yearlyTrendData => _yearlyTrendData;
  bool get isInitialized => _isInitialized;

  Future<void> _checkBudgetThreshold(int month, int year) async {
    try {
      final budgetData = await DBHelper.getBudgetForMonth(month, year);
      if (budgetData == null || budgetData['amount'] == null) return;

      final budget = budgetData['amount'] as double;
      if (budget <= 0) return;

      final spent = _items
          .where((exp) => 
            exp.date.month == month && 
            exp.date.year == year && 
            !exp.category.startsWith('Gift / Outside Budget'))
          .fold(0.0, (sum, item) => sum + item.amount);

      final percentage = (spent / budget) * 100;
      final monthName = DateFormat.MMMM().format(DateTime(year, month));

      if (percentage >= 100) {
        await NotificationHelper.showBudgetAlert(100, monthName, month, year);
      } else if (percentage >= 90) {
        await NotificationHelper.showBudgetAlert(90, monthName, month, year);
      } else if (percentage >= 75) {
        await NotificationHelper.showBudgetAlert(75, monthName, month, year);
      } else if (percentage >= 50) {
        await NotificationHelper.showBudgetAlert(50, monthName, month, year);
      }
    } catch (e) {
      debugPrint('Error checking budget threshold: $e');
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await fetchAndSetExpenses();
      _isInitialized = true;
    } catch (e) {
      debugPrint('ExpenseProvider init error: $e');
    }
  }

  Future<void> addExpense(
    double amount,
    String category,
    DateTime date,
    String? paymentMethod,
    String? notes, {
    int? accountId,
    int? debtId,
  }) async {
    final newExpense = Expense(
      amount: amount,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
      notes: notes,
      accountId: accountId,
      debtId: debtId,
    );
    _items.add(newExpense);
    notifyListeners();
    await DBHelper.insert('expenses', {
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod ?? 'Cash',
      'notes': notes ?? '',
      'account_id': accountId,
      'debt_id': debtId,
    });
    await DBHelper.updateMonthlySavingsExpenses(date.month, date.year);
    await _checkBudgetThreshold(date.month, date.year);
  }

  Future<void> updateExpense(
    int id,
    double amount,
    String category,
    DateTime date,
    String? paymentMethod,
    String? notes, {
    int? accountId,
    int? debtId,
  }) async {
    final expenseIndex = _items.indexWhere((exp) => exp.id == id);
    if (expenseIndex >= 0) {
      final updatedExpense = Expense(
        id: id,
        amount: amount,
        category: category,
        date: date,
        paymentMethod: paymentMethod,
        notes: notes,
        accountId: accountId,
        debtId: debtId,
      );
      _items[expenseIndex] = updatedExpense;
      notifyListeners();
      DBHelper.update(
          'expenses',
          id,
          {
            'amount': amount,
            'category': category,
            'date': date.toIso8601String(),
            'payment_method': paymentMethod ?? 'Cash',
            'notes': notes ?? '',
            'account_id': accountId,
            'debt_id': debtId,
          });
      await DBHelper.updateMonthlySavingsExpenses(date.month, date.year);
      await _checkBudgetThreshold(date.month, date.year);
    }
  }

  Future<void> fetchAndSetExpenses() async {
    final dataList = await DBHelper.getData('expenses');
    _items = dataList
        .map(
          (item) => Expense(
            id: item['id'],
            amount: item['amount'],
            category: item['category'],
            date: DateTime.parse(item['date']),
            paymentMethod: item['payment_method'],
            notes: item['notes'],
            accountId: item['account_id'],
            debtId: item['debt_id'],
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<void> fetchTrendData(int month) async {
    final monthlyData = await DBHelper.getMonthlySpendingForLastYears(month, 3);
    _monthlyTrendData = { for (var item in monthlyData) item['year'] : item['total'] };

    final yearlyData = await DBHelper.getYearlySpending();
    _yearlyTrendData = { for (var item in yearlyData) item['year'] : item['total'] };
    notifyListeners();
  }

  Future<void> fetchMonthlyTrend(int year) async {
    _monthlyTrendData = {};

    for (int month = 1; month <= 12; month++) {
      final expenses = _items.where((exp) =>
        exp.date.year == year && exp.date.month == month
      ).toList();

      final total = expenses.fold<double>(
        0.0,
        (sum, exp) => sum + exp.amount
      );

      _monthlyTrendData[month.toString()] = total;
    }

    notifyListeners();
  }

  Future<void> fetchYearlyTrend(int yearRange) async {
    _yearlyTrendData = {};
    final currentYear = DateTime.now().year;

    for (int i = 0; i < yearRange; i++) {
      final year = currentYear - yearRange + i + 1;
      final expenses = _items.where((exp) => exp.date.year == year).toList();

      final total = expenses.fold<double>(
        0.0,
        (sum, exp) => sum + exp.amount
      );

      _yearlyTrendData[year.toString()] = total;
    }

    notifyListeners();
  }

  Future<Expense?> deleteExpense(int id) async {
    final expenseIndex = _items.indexWhere((exp) => exp.id == id);
    if (expenseIndex >= 0) {
      final expense = _items[expenseIndex];
      _items.removeAt(expenseIndex);
      notifyListeners();
      await DBHelper.delete('expenses', id);
      await DBHelper.updateMonthlySavingsExpenses(expense.date.month, expense.date.year);
      return expense;
    }
    return null;
  }

  Future<void> clearAllExpenses() async {
    _items = [];
    notifyListeners();
    final db = await DBHelper.database();
    await db.delete('expenses');
  }
}
