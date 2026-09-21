import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DBHelper {
  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, 'expenses.db'),
      version: 12,
      onCreate: (db, version) {
        db.execute(
            'CREATE TABLE expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, category TEXT NOT NULL, date TEXT NOT NULL, payment_method TEXT, notes TEXT, account_id INTEGER, debt_id INTEGER)');
        db.execute(
            'CREATE TABLE budget(id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, month INTEGER NOT NULL, year INTEGER NOT NULL, UNIQUE(month, year))');
        db.execute(
            'CREATE TABLE monthly_savings(id INTEGER PRIMARY KEY AUTOINCREMENT, month INTEGER NOT NULL, year INTEGER NOT NULL, income REAL NOT NULL, expenses REAL NOT NULL, savings REAL NOT NULL, UNIQUE(month, year))');
        db.execute(
            'CREATE TABLE savings_goals(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, target_amount REAL NOT NULL, current_amount REAL NOT NULL DEFAULT 0, target_date TEXT NOT NULL, created_date TEXT NOT NULL, icon_name TEXT, color_hex TEXT, is_completed INTEGER NOT NULL DEFAULT 0)');
        db.execute(
            'CREATE TABLE accounts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, balance REAL NOT NULL DEFAULT 0, credit_limit REAL, icon_name TEXT, color_hex TEXT, is_default INTEGER NOT NULL DEFAULT 0, created_date TEXT NOT NULL)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute(
              'CREATE TABLE monthly_savings(id INTEGER PRIMARY KEY AUTOINCREMENT, month INTEGER NOT NULL, year INTEGER NOT NULL, income REAL NOT NULL, expenses REAL NOT NULL, savings REAL NOT NULL, UNIQUE(month, year))');
        }
        if (oldVersion < 4) {
          await db.execute('CREATE TABLE expenses_new(id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, category TEXT NOT NULL, date TEXT NOT NULL, payment_method TEXT, notes TEXT)');
          await db.execute('INSERT INTO expenses_new(id, amount, category, date, payment_method, notes) SELECT id, amount, category, date, payment_method, notes FROM expenses');
          await db.execute('DROP TABLE expenses');
          await db.execute('ALTER TABLE expenses_new RENAME TO expenses');
        }
        if (oldVersion < 5) {
          await db.execute(
              'CREATE TABLE savings_goals(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, target_amount REAL NOT NULL, current_amount REAL NOT NULL DEFAULT 0, target_date TEXT NOT NULL, created_date TEXT NOT NULL, icon_name TEXT, color_hex TEXT, is_completed INTEGER NOT NULL DEFAULT 0)');
        }
        if (oldVersion < 8) {
          await db.execute(
              'CREATE TABLE accounts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, balance REAL NOT NULL DEFAULT 0, credit_limit REAL, icon_name TEXT, color_hex TEXT, is_default INTEGER NOT NULL DEFAULT 0, created_date TEXT NOT NULL)');
          await db.execute('ALTER TABLE expenses ADD COLUMN account_id INTEGER');
        }
      },
    );
  }

  // Generic Methods
  static Future<void> insert(String table, Map<String, Object?> data) async {
    final db = await DBHelper.database();
    db.insert(
      table,
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
    return db.query(table);
  }

  static Future<void> update(
      String table, int id, Map<String, Object?> data) async {
    final db = await DBHelper.database();
    db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> delete(String table, int id) async {
    final db = await DBHelper.database();
    db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
  
  // Expense Methods
  static Future<double> getExpensesSumForMonth(int month, int year) async {
    final db = await DBHelper.database();
    final result = await db.rawQuery(
        "SELECT SUM(amount) as total FROM expenses WHERE strftime('%m', date) = ? AND strftime('%Y', date) = ? AND category NOT LIKE 'Gift / Outside Budget%'",
        [month.toString().padLeft(2, '0'), year.toString()]);
    return (result.first['total'] as double?) ?? 0.0;
  }

  static Future<List<Map<String, dynamic>>> getMonthlySpendingForLastYears(
    int month, int numberOfYears) async {
    final db = await DBHelper.database();
    final currentYear = DateTime.now().year;
    final years = List.generate(numberOfYears, (i) => currentYear - i);
    return await db.rawQuery(
      "SELECT strftime('%Y', date) as year, SUM(amount) as total FROM expenses WHERE strftime('%m', date) = ? AND strftime('%Y', date) IN (${years.map((_) => '?').join(',')}) AND category NOT LIKE 'Gift / Outside Budget%' GROUP BY year",
      [month.toString().padLeft(2, '0'), ...years.map((y) => y.toString())]);
  }

  static Future<List<Map<String, dynamic>>> getYearlySpending() async {
    final db = await DBHelper.database();
    return await db.rawQuery(
        "SELECT strftime('%Y', date) as year, SUM(amount) as total FROM expenses WHERE category NOT LIKE 'Gift / Outside Budget%' GROUP BY year");
  }
  
  // Monthly Savings Methods
  static Future<void> addOrUpdateMonthlySavings(int month, int year, double income) async {
    final expenses = await getExpensesSumForMonth(month, year);
    final savings = income - expenses;

    final db = await DBHelper.database();
    await db.insert(
      'monthly_savings',
      {
        'month': month,
        'year': year,
        'income': income,
        'expenses': expenses,
        'savings': savings,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateMonthlySavingsExpenses(int month, int year) async {
    final db = await DBHelper.database();
    final existing = await db.query('monthly_savings', where: 'month = ? AND year = ?', whereArgs: [month, year]);
    
    if (existing.isNotEmpty) {
      final income = existing.first['income'] as double;
      await addOrUpdateMonthlySavings(month, year, income);
    }
  }

  static Future<List<Map<String, dynamic>>> getAllMonthlySavings() async {
    final db = await DBHelper.database();
    return db.query('monthly_savings', orderBy: 'year DESC, month DESC');
  }

  static Future<double> getTotalSavings() async {
    final db = await DBHelper.database();
    final result = await db.rawQuery("SELECT SUM(savings) as total FROM monthly_savings");
    return (result.first['total'] as double?) ?? 0.0;
  }

  static Future<void> clearAllMonthlySavings() async {
    final db = await DBHelper.database();
    await db.delete('monthly_savings');
  }

  // Budget Methods
  static Future<List<Map<String, dynamic>>> getAllBudgets() async {
    final db = await DBHelper.database();
    return db.query('budget');
  }

  static Future<Map<String, dynamic>?> getBudgetForMonth(int month, int year) async {
    final db = await DBHelper.database();
    final result = await db.query(
      'budget',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Savings Goals Methods
  static Future<int> insertSavingsGoal(Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    return await db.insert('savings_goals', data);
  }

  static Future<List<Map<String, dynamic>>> getAllSavingsGoals() async {
    final db = await DBHelper.database();
    return db.query('savings_goals', orderBy: 'target_date ASC');
  }

  static Future<void> updateSavingsGoal(int id, Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    await db.update('savings_goals', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteSavingsGoal(int id) async {
    final db = await DBHelper.database();
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> addToSavingsGoal(int id, double amount) async {
    final db = await DBHelper.database();
    await db.rawUpdate(
      'UPDATE savings_goals SET current_amount = current_amount + ? WHERE id = ?',
      [amount, id],
    );
  }

  static Future<void> clearAllSavingsGoals() async {
    final db = await DBHelper.database();
    await db.delete('savings_goals');
  }

  // Account Methods
  static Future<int> insertAccount(Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    return await db.insert('accounts', data);
  }

  static Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final db = await DBHelper.database();
    return db.query('accounts', orderBy: 'is_default DESC, name ASC');
  }

  static Future<Map<String, dynamic>?> getAccountById(int id) async {
    final db = await DBHelper.database();
    final result = await db.query('accounts', where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> getDefaultAccount() async {
    final db = await DBHelper.database();
    final result = await db.query('accounts', where: 'is_default = 1', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> updateAccount(int id, Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    await db.update('accounts', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAccount(int id) async {
    final db = await DBHelper.database();
    await db.rawUpdate('UPDATE expenses SET account_id = NULL WHERE account_id = ?', [id]);
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateAccountBalance(int accountId, double amount, {bool isDeduction = true}) async {
    final db = await DBHelper.database();
    if (isDeduction) {
      await db.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, accountId],
      );
    } else {
      await db.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [amount, accountId],
      );
    }
  }

  static Future<void> setDefaultAccount(int accountId) async {
    final db = await DBHelper.database();
    await db.rawUpdate('UPDATE accounts SET is_default = 0');
    await db.rawUpdate('UPDATE accounts SET is_default = 1 WHERE id = ?', [accountId]);
  }

  static Future<void> clearAllAccounts() async {
    final db = await DBHelper.database();
    await db.rawUpdate('UPDATE expenses SET account_id = NULL');
    await db.delete('accounts');
  }

  static Future<List<Map<String, dynamic>>> getExpensesByAccount(int accountId) async {
    final db = await DBHelper.database();
    return db.query('expenses', where: 'account_id = ?', whereArgs: [accountId], orderBy: 'date DESC');
  }

  static Future<double> getAccountTotalExpenses(int accountId) async {
    final db = await DBHelper.database();
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE account_id = ?',
      [accountId],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  static Future<double> getExpensesSumForMonthByAccount(int month, int year, int? accountId) async {
    final db = await DBHelper.database();
    String query = "SELECT SUM(amount) as total FROM expenses WHERE strftime('%m', date) = ? AND strftime('%Y', date) = ? AND category NOT LIKE 'Gift / Outside Budget%'";
    List<dynamic> args = [month.toString().padLeft(2, '0'), year.toString()];

    if (accountId != null) {
      query += ' AND account_id = ?';
      args.add(accountId);
    }

    final result = await db.rawQuery(query, args);
    return (result.first['total'] as double?) ?? 0.0;
  }
}
