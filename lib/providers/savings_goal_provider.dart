import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalProvider with ChangeNotifier {
  List<SavingsGoal> _goals = [];

  List<SavingsGoal> get goals => [..._goals];

  List<SavingsGoal> get activeGoals =>
      _goals.where((g) => !g.isCompleted).toList();

  List<SavingsGoal> get completedGoals =>
      _goals.where((g) => g.isCompleted).toList();

  double get totalTargetAmount =>
      activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);

  double get totalCurrentAmount =>
      activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);

  double get overallProgress {
    if (totalTargetAmount <= 0) return 0.0;
    return (totalCurrentAmount / totalTargetAmount).clamp(0.0, 1.0);
  }

  Future<void> fetchAllGoals() async {
    final dataList = await DBHelper.getAllSavingsGoals();
    _goals = dataList.map((data) => SavingsGoal.fromMap(data)).toList();
    notifyListeners();
  }

  Future<void> addGoal({
    required String name,
    String? description,
    required double targetAmount,
    required DateTime targetDate,
    String? iconName,
    String? colorHex,
  }) async {
    final newGoal = SavingsGoal(
      name: name,
      description: description,
      targetAmount: targetAmount,
      targetDate: targetDate,
      createdDate: DateTime.now(),
      iconName: iconName,
      colorHex: colorHex,
    );

    final id = await DBHelper.insertSavingsGoal({
      'name': newGoal.name,
      'description': newGoal.description,
      'target_amount': newGoal.targetAmount,
      'current_amount': newGoal.currentAmount,
      'target_date': newGoal.targetDate.toIso8601String(),
      'created_date': newGoal.createdDate.toIso8601String(),
      'icon_name': newGoal.iconName,
      'color_hex': newGoal.colorHex,
      'is_completed': 0,
    });

    _goals.add(newGoal.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateGoal({
    required int id,
    required String name,
    String? description,
    required double targetAmount,
    required DateTime targetDate,
    String? iconName,
    String? colorHex,
  }) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index < 0) return;

    final existingGoal = _goals[index];
    final updatedGoal = existingGoal.copyWith(
      name: name,
      description: description,
      targetAmount: targetAmount,
      targetDate: targetDate,
      iconName: iconName,
      colorHex: colorHex,
    );

    await DBHelper.updateSavingsGoal(id, {
      'name': updatedGoal.name,
      'description': updatedGoal.description,
      'target_amount': updatedGoal.targetAmount,
      'target_date': updatedGoal.targetDate.toIso8601String(),
      'icon_name': updatedGoal.iconName,
      'color_hex': updatedGoal.colorHex,
    });

    _goals[index] = updatedGoal;
    notifyListeners();
  }

  Future<void> addToGoal(int id, double amount) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index < 0) return;

    await DBHelper.addToSavingsGoal(id, amount);

    final goal = _goals[index];
    final newAmount = goal.currentAmount + amount;
    final isCompleted = newAmount >= goal.targetAmount;

    _goals[index] = goal.copyWith(
      currentAmount: newAmount,
      isCompleted: isCompleted,
    );

    if (isCompleted) {
      await DBHelper.updateSavingsGoal(id, {'is_completed': 1});
    }

    notifyListeners();
  }

  Future<void> withdrawFromGoal(int id, double amount) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index < 0) return;

    final goal = _goals[index];
    final newAmount = (goal.currentAmount - amount).clamp(0.0, double.infinity);

    await DBHelper.updateSavingsGoal(id, {
      'current_amount': newAmount,
      'is_completed': 0,
    });

    _goals[index] = goal.copyWith(
      currentAmount: newAmount,
      isCompleted: false,
    );

    notifyListeners();
  }

  Future<void> markAsCompleted(int id) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index < 0) return;

    await DBHelper.updateSavingsGoal(id, {'is_completed': 1});

    _goals[index] = _goals[index].copyWith(isCompleted: true);
    notifyListeners();
  }

  Future<void> deleteGoal(int id) async {
    await DBHelper.deleteSavingsGoal(id);
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await DBHelper.clearAllSavingsGoals();
    _goals = [];
    notifyListeners();
  }

  SavingsGoal? getGoalById(int id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }
}
