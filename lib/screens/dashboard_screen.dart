import 'package:exptrackerforhybridos/helpers/notification_helper.dart';
import 'package:exptrackerforhybridos/providers/budget_provider.dart';
import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/providers/monthly_savings_provider.dart';
import 'package:exptrackerforhybridos/providers/savings_goal_provider.dart';
import 'package:exptrackerforhybridos/widgets/category_pie_chart.dart';
import 'package:exptrackerforhybridos/widgets/trend_graph.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final _budgetController = TextEditingController();
  bool _showPieChart = true;
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
    Future.delayed(Duration.zero, () {
      _fetchData();
      _loadBudgetForCurrentMonth();
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _fetchData() {
    Provider.of<BudgetProvider>(context, listen: false).fetchAllBudgets();
    Provider.of<ExpenseProvider>(context, listen: false).fetchAndSetExpenses();
    Provider.of<ExpenseProvider>(context, listen: false).fetchTrendData(_selectedMonth);
    Provider.of<SavingsGoalProvider>(context, listen: false).fetchAllGoals();
  }

  void _loadBudgetForCurrentMonth() {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final budget = budgetProvider.getBudgetForMonth(_selectedMonth, _selectedYear);
    if (budget != null && budget.amount > 0) {
      _budgetController.text = budget.amount.toStringAsFixed(0);
    } else {
      _budgetController.clear();
    }
  }

  void _saveBudget() async {
    final budgetText = _budgetController.text.trim();
    if (budgetText.isEmpty) return;
    final budgetAmount = double.tryParse(budgetText.replaceAll(RegExp(r'[₹,]'), ''));
    if (budgetAmount == null || budgetAmount <= 0) return;

    HapticFeedback.mediumImpact();
    await NotificationHelper.resetNotificationsForMonth(_selectedMonth, _selectedYear);
    if (!mounted) return;
    Provider.of<BudgetProvider>(context, listen: false).setBudget(budgetAmount, _selectedMonth, _selectedYear);
    Provider.of<MonthlySavingsProvider>(context, listen: false).updateSavingsForBudget(_selectedMonth, _selectedYear, budgetAmount);
    
    _fetchData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget Updated'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final budget = budgetProvider.getBudgetForMonth(_selectedMonth, _selectedYear)?.amount ?? 0;
    final spent = expenseProvider.items
        .where((exp) => exp.date.month == _selectedMonth && exp.date.year == _selectedYear && !exp.category.startsWith('Gift'))
        .fold(0.0, (sum, item) => sum + item.amount);
    final remaining = budget - spent;
    final percentage = budget > 0 ? (spent / budget * 100) : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(context, isDark, budget, spent, percentage),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildPeriodSelector(isDark),
                    const SizedBox(height: 16),
                    _buildRemainingCard(context, remaining, isDark),
                    const SizedBox(height: 16),
                    _buildQuickActions(isDark, budget),
                    const SizedBox(height: 28),
                    _buildChartSection(isDark),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, double budget, double spent, double percentage) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.primaryGradient,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
          boxShadow: AppTheme.shadowLarge,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Analytics Hub', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                IconButton(
                  onPressed: () => setState(() => _fetchData()),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white24),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _HeaderStat(label: 'Monthly Budget', amount: budget, icon: Icons.account_balance_wallet_rounded),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: _HeaderStat(label: 'Total Spent', amount: spent, icon: Icons.shopping_bag_rounded),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: (percentage / 100).clamp(0, 1),
                    strokeWidth: 12,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      'Spent',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    final monthName = DateFormat('MMMM').format(DateTime(_selectedYear, _selectedMonth));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Analysis Period', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700)),
                Text('$monthName $_selectedYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showPeriodPicker(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingCard(BuildContext context, double remaining, bool isDark) {
    final isNegative = remaining < 0;
    final color = isNegative ? AppTheme.errorColor : AppTheme.secondaryColor;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNegative ? 'OVER BUDGET' : 'REMAINING BUDGET', 
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                ),
                const SizedBox(height: 6),
                Text('₹${remaining.abs().toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
          if (remaining > 0)
            ElevatedButton.icon(
              onPressed: () => _showTransferToGoalDialog(context, remaining, isDark),
              icon: const Icon(Icons.savings_rounded, size: 16),
              label: const Text('Save Extra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, double currentBudget) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Update Monthly Budget', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter new budget limit',
              prefixText: '₹ ',
              prefixIcon: const Icon(Icons.edit_note_rounded),
              suffixIcon: IconButton(
                onPressed: _saveBudget,
                icon: const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Visual Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            _ChartToggle(
              showPie: _showPieChart,
              onChanged: (v) => setState(() => _showPieChart = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _showPieChart 
          ? CategoryPieChart(month: _selectedMonth, year: _selectedYear)
          : const TrendGraph(),
      ],
    );
  }

  void _showTransferToGoalDialog(BuildContext context, double remainingAmount, bool isDark) async {
    final savingsGoalProvider = Provider.of<SavingsGoalProvider>(context, listen: false);
    final activeGoals = savingsGoalProvider.activeGoals;

    if (activeGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active savings goals found.')));
      return;
    }

    int? selectedGoalId;
    final amountController = TextEditingController(text: remainingAmount.toStringAsFixed(0));

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
        child: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('Transfer to Goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
              ),
              const SizedBox(height: 20),
              ...activeGoals.map((goal) => RadioListTile<int>(
                title: Text(goal.name),
                subtitle: Text('Current: ₹${goal.currentAmount.toStringAsFixed(0)}'),
                value: goal.id!,
                // ignore: deprecated_member_use
                groupValue: selectedGoalId,
                // ignore: deprecated_member_use
                onChanged: (v) => setDialogState(() => selectedGoalId = v),
              )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedGoalId == null ? null : () async {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0 || amount > remainingAmount) return;

                    await savingsGoalProvider.addToGoal(selectedGoalId!, amount);
                    if (!context.mounted) return;
                    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                    await expenseProvider.addExpense(amount, 'Savings', DateTime.now(), 'Other', 'Transferred from remaining budget');

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _fetchData();
                  },
                  child: const Text('Confirm Transfer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodPicker() async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      builder: (context) => _PeriodPickerSheet(initialMonth: _selectedMonth, initialYear: _selectedYear),
    );

    if (result != null) {
      setState(() {
        _selectedMonth = result['month']!;
        _selectedYear = result['year']!;
      });
      _applyFilter();
    }
  }

  void _applyFilter() {
    _loadBudgetForCurrentMonth();
    _fetchData();
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;

  const _HeaderStat({required this.label, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ChartToggle extends StatelessWidget {
  final bool showPie;
  final ValueChanged<bool> onChanged;

  const _ChartToggle({required this.showPie, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ToggleIcon(icon: Icons.pie_chart_rounded, isSelected: showPie, onTap: () => onChanged(true)),
          _ToggleIcon(icon: Icons.show_chart_rounded, isSelected: !showPie, onTap: () => onChanged(false)),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleIcon({required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
      ),
    );
  }
}

class _PeriodPickerSheet extends StatefulWidget {
  final int initialMonth;
  final int initialYear;
  const _PeriodPickerSheet({required this.initialMonth, required this.initialYear});

  @override
  State<_PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends State<_PeriodPickerSheet> {
  late int m;
  late int y;

  @override
  void initState() {
    super.initState();
    m = widget.initialMonth;
    y = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select Period', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: m,
                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMMM').format(DateTime(2022, i + 1))))),
                  onChanged: (v) => setState(() => m = v!),
                  dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: y,
                  items: List.generate(10, (i) => DropdownMenuItem(value: 2022 + i, child: Text((2022 + i).toString()))),
                  onChanged: (v) => setState(() => y = v!),
                  dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {'month': m, 'year': y}),
              child: const Text('Apply Filter'),
            ),
          ),
        ],
      ),
    );
  }
}
