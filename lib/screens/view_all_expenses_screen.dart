import 'package:exptrackerforhybridos/app_constants.dart';
import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/screens/add_expense_screen.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:exptrackerforhybridos/models/expense_model.dart';
import 'package:intl/intl.dart';

class ViewAllExpensesScreen extends StatefulWidget {
  const ViewAllExpensesScreen({super.key});

  @override
  State<ViewAllExpensesScreen> createState() => _ViewAllExpensesScreenState();
}

class _ViewAllExpensesScreenState extends State<ViewAllExpensesScreen> with SingleTickerProviderStateMixin {
  late Future _expensesFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int? _selectedMonth;
  int? _selectedYear;
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _expensesFuture = Provider.of<ExpenseProvider>(context, listen: false).fetchAndSetExpenses();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Expense> _getFilteredExpenses(List<Expense> allExpenses) {
    List<Expense> filtered = allExpenses.where((expense) {
      bool matchesMonth = _selectedMonth == null || expense.date.month == _selectedMonth;
      bool matchesYear = _selectedYear == null || expense.date.year == _selectedYear;
      return matchesMonth && matchesYear;
    }).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: FutureBuilder(
                  future: _expensesFuture,
                  builder: (ctx, snapshot) => snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : Consumer<ExpenseProvider>(builder: (ctx, expenseProvider, ch) {
                          final allFilteredExpenses = _getFilteredExpenses(expenseProvider.items);
                          final totalAmount = allFilteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
                          final totalItems = allFilteredExpenses.length;
                          final totalPages = (totalItems / _pageSize).ceil();
                          
                          if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;

                          final startIdx = _currentPage * _pageSize;
                          final endIdx = (startIdx + _pageSize) > totalItems ? totalItems : (startIdx + _pageSize);
                          final pagedExpenses = totalItems > 0 ? allFilteredExpenses.sublist(startIdx, endIdx) : <Expense>[];

                          return Column(
                            children: [
                              _buildQuickSummary(totalItems, totalAmount, isDark),
                              Expanded(
                                child: allFilteredExpenses.isEmpty 
                                  ? _buildEmptyState(isDark) 
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), 
                                      itemCount: pagedExpenses.length, 
                                      itemBuilder: (ctx, i) => _buildExpenseCard(pagedExpenses[i], isDark),
                                    ),
                              ),
                              if (totalPages > 1) 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 110),
                                  child: _buildPaginationControls(isDark, totalPages, totalItems, startIdx, endIdx),
                                )
                              else
                                const SizedBox(height: 110),
                            ],
                          );
                        }),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Transactions', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
          Row(
            children: [
              IconButton(
                onPressed: _showFilterBottomSheet,
                icon: const Icon(Icons.tune_rounded),
                style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white12 : Colors.black.withAlpha(5)),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary(int count, double total, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Spending', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('₹0', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
            child: Text('$count txns', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, bool isDark) {
    final categoryColor = categoryColors[expense.category] ?? AppTheme.primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: categoryColor.withAlpha(15), borderRadius: BorderRadius.circular(16)),
          child: Icon(_getCategoryIcon(expense.category), color: categoryColor, size: 24),
        ),
        title: Text(expense.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Text(DateFormat('dd MMMM yyyy').format(expense.date), style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: Text('₹${expense.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.redAccent)),
        onTap: () {
          HapticFeedback.selectionClick();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddExpenseScreen(expense: expense),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'bills': return Icons.receipt_long_rounded;
      default: return Icons.category_rounded;
    }
  }

  Widget _buildPaginationControls(bool isDark, int totalPages, int totalItems, int startIdx, int endIdx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            isDark: isDark,
          ),
          Text('Page ${_currentPage + 1} of $totalPages', style: const TextStyle(fontWeight: FontWeight.w700)),
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed, required bool isDark}) {
    final bool isDisabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.transparent : AppTheme.primaryColor.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: isDisabled ? Colors.grey : AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history_rounded, size: 64, color: Colors.grey.withAlpha(50)),
      const SizedBox(height: 16),
      const Text('No transactions found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
    ]));
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(80), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.primaryGradient), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 24)),
                const SizedBox(width: 16),
                const Text('Filter History', style: AppTheme.heading3),
              ]),
              const SizedBox(height: 32),
              
              // Year and Month logic similar to previous implementation
              Row(
                children: [
                  Expanded(
                    child: _buildPickerButton(
                      label: 'Year',
                      value: _selectedYear?.toString() ?? 'All',
                      onTap: () async {
                        final currentYear = DateTime.now().year;
                        final result = await showDialog<int>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Year'),
                            content: SizedBox(
                              height: 300,
                              width: 300,
                              child: YearPicker(
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                selectedDate: DateTime(_selectedYear ?? currentYear),
                                onChanged: (v) => Navigator.pop(context, v.year),
                              ),
                            ),
                          ),
                        );
                        if (result != null) setDialogState(() => _selectedYear = result);
                      },
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedMonth,
                      decoration: const InputDecoration(labelText: 'Month', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                      items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(DateFormat('MMMM').format(DateTime(2026, i+1))))),
                      onChanged: (v) => setDialogState(() => _selectedMonth = v),
                      dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () {
                  setState(() { _selectedYear = null; _selectedMonth = null; _currentPage = 0; });
                  Navigator.pop(ctx);
                }, child: const Text('Reset'))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(onPressed: () {
                  setState(() { _currentPage = 0; });
                  Navigator.pop(ctx);
                }, child: const Text('Apply Filter'))),
              ]),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerButton({required String label, required String value, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
