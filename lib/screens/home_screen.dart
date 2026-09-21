import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/providers/budget_provider.dart';
import 'package:exptrackerforhybridos/providers/account_provider.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:exptrackerforhybridos/widgets/voice_input_widget.dart';
import 'package:exptrackerforhybridos/screens/view_all_expenses_screen.dart';
import 'package:exptrackerforhybridos/screens/dashboard_screen.dart';
import 'package:exptrackerforhybridos/screens/savings_tracker_screen.dart';
import 'package:exptrackerforhybridos/screens/accounts_screen.dart';
import 'package:exptrackerforhybridos/screens/feature_settings_screen.dart';
import 'package:exptrackerforhybridos/screens/savings_goals_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/feature_provider.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final featureProvider = Provider.of<FeatureProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    
    final recentExpenses = expenseProvider.items.take(5).toList();
    
    final now = DateTime.now();
    final monthlySpent = expenseProvider.items
        .where((e) => 
            e.date.month == now.month && 
            e.date.year == now.year && 
            !e.category.startsWith('Gift'))
        .fold(0.0, (sum, item) => sum + item.amount);

    final currentBudget = budgetProvider.getBudgetForMonth(now.month, now.year)?.amount ?? 0.0;
    final remainingBalance = currentBudget - monthlySpent;
    final progressPercent = currentBudget > 0 ? (monthlySpent / currentBudget).clamp(0.0, 1.0) : 0.0;

    final List<Map<String, dynamic>> allModules = [
      {'title': 'Analytics', 'icon': Icons.insights_rounded, 'color': const Color(0xFF6366F1), 'screen': const DashboardScreen(), 'key': 'dashboard'},
      {'title': 'Savings', 'icon': Icons.savings_rounded, 'color': const Color(0xFF10B981), 'screen': const SavingsTrackerScreen(), 'key': 'savings_tracker'},
      {'title': 'Goals', 'icon': Icons.flag_rounded, 'color': const Color(0xFFEC4899), 'screen': const SavingsGoalsScreen(), 'key': 'savings_goals'},
    ];

    final visibleModules = allModules.where((m) {
      if (m['key'] == null) return true;
      return featureProvider.isFeatureEnabled(m['key'] as String);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, isDark),
          
          // Hero Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildHeroCard(context, remainingBalance, currentBudget, monthlySpent, progressPercent, isDark),
            ),
          ),

          // Accounts / Wallet Shortcut Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildWalletShortcut(context, accountProvider, isDark),
            ),
          ),

          // Quick Modules Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  TextButton.icon(
                    onPressed: () => _showVoiceInput(context), 
                    icon: const Icon(Icons.mic_rounded, size: 18, color: AppTheme.primaryColor),
                    label: const Text('Voice Add', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                  ),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final m = visibleModules[index];
                  return _buildQuickActionTile(context, m['title'], m['icon'], m['color'], m['screen'], isDark);
                },
                childCount: visibleModules.length,
              ),
            ),
          ),

          // Recent Activity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewAllExpensesScreen())),
                    child: const Text('See All', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: recentExpenses.isEmpty
                ? SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: AppTheme.cardDecoration(context),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No expenses logged yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('Tap (+) button below to add your first expense', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildRecentItem(context, recentExpenses[index], isDark),
                      childCount: recentExpenses.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 110,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        centerTitle: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 1.2)),
            const Text('NanoZone Tracker', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeatureSettingsScreen())),
          icon: const Icon(Icons.settings_suggest_rounded, size: 24),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? Colors.white10 : Colors.black.withAlpha(8),
            padding: const EdgeInsets.all(10),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    double remainingBalance,
    double currentBudget,
    double monthlySpent,
    double progressPercent,
    bool isDark,
  ) {
    final isNegative = remainingBalance < 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative 
              ? AppTheme.dangerGradient 
              : AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.shadowLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isNegative ? 'OVER BUDGET' : 'REMAINING BUDGET', 
                style: const TextStyle(
                  color: Colors.white70, 
                  fontWeight: FontWeight.w800, 
                  fontSize: 11, 
                  letterSpacing: 1.2
                )
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progressPercent * 100).toStringAsFixed(0)}% Spent',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹${remainingBalance.abs().toStringAsFixed(0)}', 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 42, 
                fontWeight: FontWeight.w900, 
                letterSpacing: -1.5
              )
            ),
          ),
          const SizedBox(height: 20),
          
          // Progress Gauge Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Budget', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                        Text('₹${currentBudget.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Spent', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                          Text('₹${monthlySpent.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletShortcut(BuildContext context, AccountProvider accountProvider, bool isDark) {
    final accounts = accountProvider.accounts;
    final bankBalance = accountProvider.totalBankBalance;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.account_balance_rounded, color: AppTheme.secondaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Wallet & Accounts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${accounts.length} linked accounts • ₹${bankBalance.toStringAsFixed(0)} total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(BuildContext context, String title, IconData icon, Color color, Widget screen, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Container(
        decoration: AppTheme.cardDecoration(context),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(BuildContext context, dynamic expense, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context, customColor: isDark ? AppTheme.cardDark : Colors.white),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(15), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.category, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(DateFormat('MMM dd, yyyy').format(expense.date), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text('-₹${expense.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.spentColor)),
        ],
      ),
    );
  }

  void _showVoiceInput(BuildContext context) async {
    final result = await showVoiceInputSheet(context);
    if (result != null && result.isValid && context.mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => AddExpenseScreen(
          prefilledAmount: result.amount,
          prefilledCategory: result.category,
          prefilledPaymentMethod: result.paymentMethod,
          prefilledNotes: result.notes,
          prefilledDate: result.date,
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}
