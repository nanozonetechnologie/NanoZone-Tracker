import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../helpers/db_helper.dart';

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [];
  bool _isInitialized = false;

  List<Account> get accounts => [..._accounts];
  bool get isInitialized => _isInitialized;

  List<Account> get bankAccounts =>
      _accounts.where((a) => a.type == AccountType.bank).toList();

  List<Account> get creditCards =>
      _accounts.where((a) => a.type == AccountType.creditCard).toList();

  Account? get defaultAccount =>
      _accounts.where((a) => a.isDefault).firstOrNull;

  double get totalBankBalance =>
      bankAccounts.fold(0.0, (sum, a) => sum + a.balance);

  double get totalCreditUsed =>
      creditCards.fold(0.0, (sum, a) => sum + (-a.balance));

  double get totalCreditLimit =>
      creditCards.fold(0.0, (sum, a) => sum + (a.creditLimit ?? 0));

  double get totalBalance => totalBankBalance - totalCreditUsed;

  Future<void> init() async {
    if (_isInitialized) return;
    await fetchAllAccounts();
    _isInitialized = true;
  }

  Future<void> fetchAllAccounts() async {
    try {
      final data = await DBHelper.getAllAccounts();
      _accounts = data.map((map) => Account.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
    }
  }

  Future<int> addAccount({
    required String name,
    required AccountType type,
    double balance = 0.0,
    double? creditLimit,
    String? iconName,
    String? colorHex,
    bool isDefault = false,
  }) async {
    try {
      final shouldBeDefault = isDefault || _accounts.isEmpty;

      if (shouldBeDefault) {
        await DBHelper.setDefaultAccount(-1);
      }

      final account = Account(
        name: name,
        type: type,
        balance: balance,
        creditLimit: creditLimit,
        iconName: iconName,
        colorHex: colorHex,
        isDefault: shouldBeDefault,
        createdDate: DateTime.now(),
      );

      final id = await DBHelper.insertAccount(account.toMap());
      _accounts.add(account.copyWith(id: id));
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Error adding account: $e');
      rethrow;
    }
  }

  Future<void> updateAccount({
    required int id,
    required String name,
    required AccountType type,
    double? balance,
    double? creditLimit,
    String? iconName,
    String? colorHex,
  }) async {
    try {
      final index = _accounts.indexWhere((a) => a.id == id);
      if (index == -1) return;

      final existing = _accounts[index];
      final updated = existing.copyWith(
        name: name,
        type: type,
        balance: balance ?? existing.balance,
        creditLimit: creditLimit,
        iconName: iconName,
        colorHex: colorHex,
      );

      await DBHelper.updateAccount(id, updated.toMap());
      _accounts[index] = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating account: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await DBHelper.deleteAccount(id);
      _accounts.removeWhere((a) => a.id == id);

      if (_accounts.isNotEmpty && !_accounts.any((a) => a.isDefault)) {
        await setDefaultAccount(_accounts.first.id!);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> setDefaultAccount(int accountId) async {
    try {
      await DBHelper.setDefaultAccount(accountId);

      for (int i = 0; i < _accounts.length; i++) {
        _accounts[i] = _accounts[i].copyWith(
          isDefault: _accounts[i].id == accountId,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting default account: $e');
      rethrow;
    }
  }

  Future<void> deductFromAccount(int accountId, double amount) async {
    try {
      await DBHelper.updateAccountBalance(accountId, amount, isDeduction: true);

      final index = _accounts.indexWhere((a) => a.id == accountId);
      if (index != -1) {
        _accounts[index] = _accounts[index].copyWith(
          balance: _accounts[index].balance - amount,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deducting from account: $e');
    }
  }

  Future<void> addToAccount(int accountId, double amount) async {
    try {
      await DBHelper.updateAccountBalance(accountId, amount, isDeduction: false);

      final index = _accounts.indexWhere((a) => a.id == accountId);
      if (index != -1) {
        _accounts[index] = _accounts[index].copyWith(
          balance: _accounts[index].balance + amount,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding to account: $e');
    }
  }

  Future<void> setAccountBalance(int accountId, double newBalance) async {
    try {
      final index = _accounts.indexWhere((a) => a.id == accountId);
      if (index == -1) return;

      final updated = _accounts[index].copyWith(balance: newBalance);
      await DBHelper.updateAccount(accountId, updated.toMap());
      _accounts[index] = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting account balance: $e');
    }
  }

  Account? getAccountById(int id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await DBHelper.clearAllAccounts();
    _accounts = [];
    notifyListeners();
  }
}
