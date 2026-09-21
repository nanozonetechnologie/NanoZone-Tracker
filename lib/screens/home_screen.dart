import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/providers/budget_provider.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:exptrackerforhybridos/screens/view_all_expenses_screen.dart';
import 'package:exptrackerforhybridos/screens/dashboard_screen.dart';
import 'package:exptrackerforhybridos/screens/savings_tracker_screen.dart';
import 'package:exptrackerforhybridos/screens/feature_settings_screen.dart';
import 'package:exptrackerforhybridos/screens/savings_goals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exptrackerforhybridos/widgets/feature_tour_overlay.dart';
import '../providers/feature_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Customizable Daily Favorite Presets
  final List<Map<String, dynamic>> _quickPresets = [
    {'key': 'coffee', 'title': 'Coffee', 'amount': 50.0, 'category': 'Food & Dining', 'icon': Icons.coffee_rounded, 'color': const Color(0xFF8D6E63)},
    {'key': 'meal', 'title': 'Meal', 'amount': 150.0, 'category': 'Food & Dining', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFFF5252)},
    {'key': 'fuel', 'title': 'Fuel', 'amount': 200.0, 'category': 'Fuel', 'icon': Icons.local_gas_station_rounded, 'color': const Color(0xFFFF7043)},
    {'key': 'grocery', 'title': 'Grocery', 'amount': 500.0, 'category': 'Groceries', 'icon': Icons.shopping_cart_rounded, 'color': const Color(0xFF00C853)},
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomPresetAmounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureTourOverlay.showIfFirstTime(context);
    });
  }

  Future<void> _loadCustomPresetAmounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        for (var preset in _quickPresets) {
          final key = preset['key'] as String;
          final savedAmount = prefs.getDouble('preset_amount_$key');
          final savedTitle = prefs.getString('preset_title_$key');
          if (savedAmount != null) {
            preset['amount'] = savedAmount;
          }
          if (savedTitle != null && savedTitle.isNotEmpty) {
            preset['title'] = savedTitle;
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _saveCustomPreset(int index, String title, double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _quickPresets[index]['key'] as String;
      await prefs.setDouble('preset_amount_$key', amount);
      await prefs.setString('preset_title_$key', title);
      setState(() {
        _quickPresets[index]['title'] = title;
        _quickPresets[index]['amount'] = amount;
      });
    } catch (_) {}
  }

  void _showCustomizePresetSheet(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preset = _quickPresets[index];
    final titleController = TextEditingController(text: preset['title'] as String);
    final amountController = TextEditingController(text: (preset['amount'] as double).toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withAlpha(80), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (preset['color'] as Color).withAlpha(20), shape: BoxShape.circle),
                  child: Icon(preset['icon'] as IconData, color: preset['color'] as Color, size: 24),
                ),
                const SizedBox(width: 14),
                const Text('Customize Preset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Preset Name', prefixIcon: Icon(Icons.edit_rounded)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Default Price', prefixText: '₹ ', prefixIcon: Icon(Icons.currency_rupee_rounded)),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final newTitle = titleController.text.trim();
                      final newAmount = double.tryParse(amountController.text.trim());
                      if (newTitle.isNotEmpty && newAmount != null && newAmount > 0) {
                        _saveCustomPreset(index, newTitle, newAmount);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated $newTitle default price to ₹${newAmount.toStringAsFixed(0)}'),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    child: const Text('Save Preset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final featureProvider = Provider.of<FeatureProvider>(context);
    
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildHeroCard(context, remainingBalance, currentBudget, monthlySpent, progressPercent, isDark),
            ),
          ),

          // 1-Tap Quick Expense Presets
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildQuickPresetBar(context, isDark),
            ),
          ),

          // Quick Modules Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
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
      expandedHeight: 90,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppTheme.shadowSmall,
              ),
              padding: const EdgeInsets.all(3),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => Image.asset('assets/app_logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 7.0,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    letterSpacing: 0.6,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Nano',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                          letterSpacing: -0.4,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const TextSpan(
                        text: 'Zone',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.secondaryColor,
                          letterSpacing: -0.4,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeatureSettingsScreen())),
          icon: const Icon(Icons.settings_suggest_rounded, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? Colors.white10 : Colors.black.withAlpha(8),
            padding: const EdgeInsets.all(8),
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
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
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
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹${remainingBalance.abs().toStringAsFixed(0)}', 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 40, 
                fontWeight: FontWeight.w900, 
                letterSpacing: -1.5
              )
            ),
          ),
          const SizedBox(height: 18),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          
          const SizedBox(height: 18),
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

  Widget _buildQuickPresetBar(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('1-Tap Quick Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
            Text('Hold to customize', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(_quickPresets.length, (index) {
            final preset = _quickPresets[index];
            final title = preset['title'] as String;
            final amount = preset['amount'] as double;
            final category = preset['category'] as String;
            final icon = preset['icon'] as IconData;
            final color = preset['color'] as Color;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                  expenseProvider.addExpense(amount, category, DateTime.now(), 'UPI', title);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          Text('Logged ₹${amount.toStringAsFixed(0)} for $title!'),
                        ],
                      ),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  _showCustomizePresetSheet(context, index);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: AppTheme.cardDecoration(context),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}
