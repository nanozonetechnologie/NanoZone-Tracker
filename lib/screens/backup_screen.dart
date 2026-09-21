import 'dart:convert';
import 'dart:io';
import 'package:exptrackerforhybridos/providers/account_provider.dart';
import 'package:exptrackerforhybridos/providers/budget_provider.dart';
import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/providers/monthly_savings_provider.dart';
import 'package:exptrackerforhybridos/providers/savings_goal_provider.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:exptrackerforhybridos/models/account_model.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../models/monthly_savings.dart';
import '../providers/feature_provider.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _loadingMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshProviders() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final savingsProvider = Provider.of<MonthlySavingsProvider>(context, listen: false);
    final savingsGoalProvider = Provider.of<SavingsGoalProvider>(context, listen: false);
    final featureProvider = Provider.of<FeatureProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);

    await expenseProvider.fetchAndSetExpenses();
    await budgetProvider.fetchAllBudgets();
    await savingsProvider.fetchAllMonthlySavings();
    await savingsGoalProvider.fetchAllGoals();
    await featureProvider.init();
    await accountProvider.fetchAllAccounts();
  }

  Future<void> _cleanupOldBackups(Directory directory) async {
    try {
      final files = await directory.list().where((entity) {
        return entity is File &&
               entity.path.contains('expense_tracker_backup_') &&
               entity.path.endsWith('.json');
      }).cast<File>().toList();

      if (files.length > 5) {
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        for (int i = 0; i < files.length - 5; i++) {
          try {
            await files[i].delete();
          } catch (e) {
            // Ignore delete errors
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Creating backup...';
    });

    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final savingsProvider = Provider.of<MonthlySavingsProvider>(context, listen: false);
      final savingsGoalProvider = Provider.of<SavingsGoalProvider>(context, listen: false);
      final featureProvider = Provider.of<FeatureProvider>(context, listen: false);
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);

      await expenseProvider.fetchAndSetExpenses();
      await budgetProvider.fetchAllBudgets();
      await savingsProvider.fetchAllMonthlySavings();
      await savingsGoalProvider.fetchAllGoals();
      await featureProvider.init();
      await accountProvider.fetchAllAccounts();

      final backupData = {
        'backupDate': DateTime.now().toIso8601String(),
        'version': '3.0',
        'appName': 'NanoZone Budget Tracker',
        'expenses': expenseProvider.items.map((e) => e.toMap()).toList(),
        'budgets': budgetProvider.budgets.map((b) => b.toMap()).toList(),
        'monthlySavings': savingsProvider.savings.map((s) => s.toMap()).toList(),
        'savingsGoals': savingsGoalProvider.goals.map((g) => g.toMap()).toList(),
        'featureSettings': featureProvider.features,
        'accounts': accountProvider.accounts.map((a) => a.toMap()).toList(),
      };

      final backupJson = json.encode(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'expense_tracker_backup_$timestamp.json';
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsString(backupJson);

      await _cleanupOldBackups(directory);

      if (!mounted) return;

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'NanoZone Budget Tracker Local Backup',
        subject: 'Backup Data',
      );
      if (!mounted) return;

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Backup exported successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiateImport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Import Backup'),
        content: const Text('This will replace ALL current data with the backup file. Are you sure?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Import'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null) {
      await _performRestore(result);
    }
  }

  Future<void> _performRestore(FilePickerResult result) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Restoring backup...';
    });

    try {
      final file = File(result.files.single.path!);
      final backupJson = await file.readAsString();
      final backupData = json.decode(backupJson);

      if (backupData['appName'] != 'NanoZone Budget Tracker' &&
          backupData['appName'] != 'Expense Tracker') {
        throw Exception('Invalid backup file.');
      }

      if (!mounted) return;

      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final savingsProvider = Provider.of<MonthlySavingsProvider>(context, listen: false);
      final savingsGoalProvider = Provider.of<SavingsGoalProvider>(context, listen: false);
      final featureProvider = Provider.of<FeatureProvider>(context, listen: false);
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);

      await expenseProvider.clearAllExpenses();
      await budgetProvider.clearAllBudgets();
      await savingsProvider.clearAll();
      await savingsGoalProvider.clearAll();
      await accountProvider.clearAll();

      if (backupData.containsKey('accounts')) {
        final accounts = backupData['accounts'] as List;
        for (var acc in accounts) {
          await accountProvider.addAccount(
            name: acc['name'] as String,
            type: (acc['type'] as String) == 'BANK' ? AccountType.bank : AccountType.creditCard,
            balance: (acc['balance'] as num?)?.toDouble() ?? 0,
            creditLimit: (acc['credit_limit'] as num?)?.toDouble(),
            iconName: acc['icon_name'] as String?,
            colorHex: acc['color_hex'] as String?,
            isDefault: (acc['is_default'] as int?) == 1,
          );
        }
      }

      if (backupData.containsKey('expenses')) {
        final expenses = backupData['expenses'] as List;
        for (var exp in expenses) {
          await expenseProvider.addExpense(
            (exp['amount'] as num).toDouble(),
            exp['category'] as String,
            DateTime.parse(exp['date']),
            exp['payment_method'] as String?,
            exp['notes'] as String?,
            accountId: exp['account_id'] as int?,
          );
        }
      }

      if (backupData.containsKey('budgets')) {
        final budgets = backupData['budgets'] as List;
        for (var bud in budgets) {
          await budgetProvider.setBudget(
            (bud['amount'] as num).toDouble(),
            bud['month'],
            bud['year'],
          );
        }
      }

      if (backupData.containsKey('monthlySavings')) {
        final savings = backupData['monthlySavings'] as List;
        for (var s in savings) {
          await savingsProvider.addRestoredSavings(MonthlySavings.fromMap(s));
        }
      }

      if (backupData.containsKey('featureSettings')) {
        final fs = backupData['featureSettings'] as Map<String, dynamic>;
        for (var entry in fs.entries) {
          if (entry.value is bool) {
            await featureProvider.toggleFeature(entry.key, entry.value as bool);
          }
        }
      }

      await _refreshProviders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Backup restored successfully!'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, isDark),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_isLoading) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              _loadingMessage,
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildSectionHeader(isDark, 'Local Device Storage', Icons.folder_rounded, AppTheme.secondaryColor),
                    const SizedBox(height: 16),
                    _buildLocalBackupSection(isDark),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.primaryGradient,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: AppTheme.shadowLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Backup & Storage', style: AppTheme.heading3.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.sd_storage_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Device Backup',
                      style: AppTheme.heading4.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '100% offline JSON data backup and restore',
                      style: AppTheme.caption.copyWith(color: Colors.white.withAlpha(200)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildLocalBackupSection(bool isDark) {
    return Container(
      decoration: AppTheme.cardDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildActionCard(
            isDark: isDark,
            icon: Icons.upload_file_rounded,
            title: 'Export JSON Backup',
            subtitle: 'Save a backup file to device or cloud drive',
            color: AppTheme.secondaryColor,
            onTap: _isLoading ? null : _exportBackup,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            isDark: isDark,
            icon: Icons.download_rounded,
            title: 'Import JSON Backup',
            subtitle: 'Restore expenses and settings from a JSON file',
            color: AppTheme.accentSecondary,
            onTap: _isLoading ? null : _initiateImport,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? color : (isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: isDark ? Colors.white.withAlpha(10) : color.withAlpha(30)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withAlpha(30) : color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isPrimary ? Colors.white : color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isPrimary ? Colors.white : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isPrimary ? Colors.white.withAlpha(200) : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: isPrimary ? Colors.white : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
