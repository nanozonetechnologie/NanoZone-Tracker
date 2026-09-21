import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/monthly_savings.dart';

class MonthlySavingsProvider with ChangeNotifier {
  List<MonthlySavings> _savings = [];
  double _totalSavings = 0.0;
  bool _isInitialized = false;

  List<MonthlySavings> get savings => _savings;
  double get totalSavings => _totalSavings;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await fetchAllMonthlySavings();
      _isInitialized = true;
    } catch (e) {
      debugPrint('MonthlySavingsProvider init error: $e');
    }
  }

  Future<void> fetchAllMonthlySavings() async {
    final data = await DBHelper.getAllMonthlySavings();
    _savings = data.map((item) => MonthlySavings.fromMap(item)).toList();
    _totalSavings = await DBHelper.getTotalSavings();
    notifyListeners();
  }

  Future<void> syncWithBudgets() async {
    final budgets = await DBHelper.getAllBudgets();
    for (var budget in budgets) {
      await DBHelper.addOrUpdateMonthlySavings(
        budget['month'],
        budget['year'],
        budget['amount'],
      );
    }
    await fetchAllMonthlySavings();
  }

  Future<void> syncExistingBudgets() async {
    await syncWithBudgets();
  }

  Future<void> updateSavingsForBudget(int month, int year, double income) async {
    await DBHelper.addOrUpdateMonthlySavings(month, year, income);
    await fetchAllMonthlySavings();
  }

  Future<void> addRestoredSavings(MonthlySavings savings) async {
    await DBHelper.insert('monthly_savings', savings.toMap());
  }

  Future<void> clearAll() async {
    await DBHelper.clearAllMonthlySavings();
    await fetchAllMonthlySavings();
  }

  Future<void> deleteSavings(int id) async {
    await DBHelper.delete('monthly_savings', id);
    await fetchAllMonthlySavings();
  }
}
