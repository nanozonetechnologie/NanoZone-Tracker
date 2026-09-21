import 'package:exptrackerforhybridos/models/budget_model.dart';
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';

class BudgetProvider with ChangeNotifier {
  List<Budget> _budgets = [];
  bool _isInitialized = false;

  List<Budget> get budgets => _budgets;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await fetchAllBudgets();
      _isInitialized = true;
    } catch (e) {
      debugPrint('BudgetProvider init error: $e');
    }
  }

  Future<void> fetchAllBudgets() async {
    final data = await DBHelper.getAllBudgets();
    _budgets = data.map((item) => Budget.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> setBudget(double amount, int month, int year) async {
    final newBudget = Budget(amount: amount, month: month, year: year);
    _budgets.removeWhere((b) => b.month == month && b.year == year);
    _budgets.add(newBudget);
    notifyListeners();
    await DBHelper.insert('budget', {
      'amount': amount,
      'month': month,
      'year': year,
    });

    await DBHelper.addOrUpdateMonthlySavings(month, year, amount);
  }

  Budget? getBudgetForMonth(int month, int year) {
    try {
      return _budgets.firstWhere((b) => b.month == month && b.year == year);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAllBudgets() async {
    _budgets = [];
    notifyListeners();
    final db = await DBHelper.database();
    await db.delete('budget');
  }
}
