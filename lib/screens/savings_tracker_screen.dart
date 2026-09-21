import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/monthly_savings_provider.dart';
import '../models/monthly_savings.dart';
import '../theme/app_theme.dart';

class SavingsTrackerScreen extends StatefulWidget {
  const SavingsTrackerScreen({super.key});

  @override
  State<SavingsTrackerScreen> createState() => _SavingsTrackerScreenState();
}

class _SavingsTrackerScreenState extends State<SavingsTrackerScreen> with TickerProviderStateMixin {
  int? _selectedYear;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 5;

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
    Provider.of<MonthlySavingsProvider>(context, listen: false).fetchAllMonthlySavings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showAddSavingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddSavingsBottomSheet(),
    );
  }

  void _showYearPicker(BuildContext context) async {
    final currentYear = DateTime.now().year;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Year', style: AppTheme.heading3.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  )),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('All Years'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: YearPicker(
                  firstDate: DateTime(2000),
                  lastDate: DateTime(currentYear + 10),
                  selectedDate: DateTime(_selectedYear ?? currentYear),
                  onChanged: (DateTime dateTime) {
                    Navigator.pop(context, dateTime.year);
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );

    if (result != null || result == null && _selectedYear != null) {
      setState(() {
        _selectedYear = result;
        _currentPage = 0; // Reset pagination on filter change
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savingsProvider = Provider.of<MonthlySavingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<MonthlySavings> filteredSavings = _selectedYear == null
        ? savingsProvider.savings
        : savingsProvider.savings.where((s) => s.year == _selectedYear).toList();

    // Pagination logic
    final int totalItems = filteredSavings.length;
    final int totalPages = (totalItems / _pageSize).ceil();
    final int startIdx = _currentPage * _pageSize;
    final int endIdx = (startIdx + _pageSize) > totalItems ? totalItems : (startIdx + _pageSize);
    final List<MonthlySavings> pagedSavings = totalItems > 0 ? filteredSavings.sublist(startIdx, endIdx) : [];

    final currentYear = DateTime.now().year;
    final List<int> availableYears = List.generate(16, (i) => currentYear - 10 + i)
      ..sort((a, b) => b.compareTo(a));

    final double averageSavings = filteredSavings.isEmpty
        ? 0.0
        : filteredSavings.fold(0.0, (sum, s) => sum + s.savings) / filteredSavings.length;

    // Calculate best and worst months
    MonthlySavings? bestMonth;
    MonthlySavings? worstMonth;
    if (filteredSavings.isNotEmpty) {
      bestMonth = filteredSavings.reduce((a, b) => a.savings > b.savings ? a : b);
      worstMonth = filteredSavings.reduce((a, b) => a.savings < b.savings ? a : b);
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await savingsProvider.fetchAllMonthlySavings();
            },
            color: AppTheme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  // Premium Header
                  SliverToBoxAdapter(
                    child: _buildPremiumHeader(context, isDark, savingsProvider),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Summary Stats Cards
                        _buildSummaryStats(context, isDark, savingsProvider.totalSavings, averageSavings, filteredSavings.length),

                        const SizedBox(height: 20),

                        // Best/Worst Months
                        if (bestMonth != null && worstMonth != null)
                          _buildBestWorstSection(context, isDark, bestMonth, worstMonth),

                        const SizedBox(height: 20),

                        // Year Filter
                        _buildYearFilter(context, isDark, availableYears),

                        const SizedBox(height: 24),

                        // Monthly Savings List
                        _buildSavingsListHeader(context, isDark, filteredSavings.length),
                        const SizedBox(height: 16),

                        if (filteredSavings.isEmpty)
                          _buildEmptyState(isDark)
                        else
                          ...pagedSavings.map((savings) => _buildSavingsCard(context, savings, isDark)),

                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      bottomNavigationBar: totalPages > 1 
          ? _buildPaginationControls(isDark, totalPages, totalItems, startIdx, endIdx) 
          : null,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppTheme.primaryGradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddSavingsDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Income', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, bool isDark, MonthlySavingsProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.successGradient,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                child: Text('Savings Tracker', style: AppTheme.heading3.copyWith(color: Colors.white)),
              ),
              GestureDetector(
                onTap: () async {
                  await provider.syncWithBudgets();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Synced with budgets'),
                        ],
                      ),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.sync_rounded, color: Colors.white, size: 22),
                ),
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
                child: const Icon(Icons.savings_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Savings',
                      style: AppTheme.caption.copyWith(color: Colors.white.withAlpha(200)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${provider.totalSavings.toStringAsFixed(0)}',
                      style: AppTheme.heading1.copyWith(color: Colors.white),
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

  Widget _buildSummaryStats(BuildContext context, bool isDark, double totalSavings, double averageSavings, int monthsCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            isDark,
            'Average/Month',
            '₹${averageSavings.toStringAsFixed(0)}',
            Icons.trending_up_rounded,
            AppTheme.infoColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            isDark,
            'Months Tracked',
            '$monthsCount',
            Icons.calendar_month_rounded,
            AppTheme.accentSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, bool isDark, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : color.withAlpha(30)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withAlpha(180)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.heading3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestWorstSection(BuildContext context, bool isDark, MonthlySavings best, MonthlySavings worst) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Monthly Insights',
                style: AppTheme.heading4.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  isDark,
                  'Best Month',
                  '${DateFormat.MMM().format(DateTime(best.year, best.month))} ${best.year}',
                  '₹${best.savings.toStringAsFixed(0)}',
                  AppTheme.successColor,
                  Icons.arrow_upward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
              ),
              Expanded(
                child: _buildInsightItem(
                  isDark,
                  'Lowest Month',
                  '${DateFormat.MMM().format(DateTime(worst.year, worst.month))} ${worst.year}',
                  '₹${worst.savings.toStringAsFixed(0)}',
                  AppTheme.warningColor,
                  Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(bool isDark, String label, String period, String amount, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: AppTheme.heading4.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            period,
            style: AppTheme.caption.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearFilter(BuildContext context, bool isDark, List<int> availableYears) {
    return GestureDetector(
      onTap: () => _showYearPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.filter_list_rounded, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Year',
                    style: AppTheme.caption.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedYear?.toString() ?? 'All Years',
                    style: AppTheme.bodyLarge.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedYear != null)
              GestureDetector(
                onTap: () {
                  setState(() => _selectedYear = null);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded, color: AppTheme.errorColor, size: 18),
                ),
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsListHeader(BuildContext context, bool isDark, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.history_rounded, color: AppTheme.secondaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Monthly History',
          style: AppTheme.heading4.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count ${count == 1 ? 'record' : 'records'}',
            style: AppTheme.caption.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.savings_outlined, size: 48, color: AppTheme.primaryColor.withAlpha(150)),
          ),
          const SizedBox(height: 20),
          Text(
            'No savings records yet',
            style: AppTheme.heading4.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your monthly budgets from Dashboard are\nautomatically used as income here.\n\nOr tap + to add manually.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(BuildContext context, MonthlySavings savings, bool isDark) {
    final monthName = DateFormat.MMMM().format(DateTime(savings.year, savings.month));
    final double savingsRate = savings.income > 0
        ? (savings.savings / savings.income * 100).clamp(0.0, 100.0).toDouble()
        : 0.0;

    Color getSavingsColor() {
      if (savingsRate >= 50) return AppTheme.successColor;
      if (savingsRate >= 20) return AppTheme.warningColor;
      return AppTheme.errorColor;
    }

    final savingsColor = savings.savings >= 0 ? getSavingsColor() : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppTheme.primaryGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$monthName ${savings.year}',
                    style: AppTheme.labelLarge.copyWith(color: Colors.white),
                  ),
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  color: AppTheme.primaryColor,
                  onTap: () => _showEditSavingsDialog(savings),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppTheme.errorColor,
                  onTap: () => _confirmDelete(savings),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Financial Details
            Row(
              children: [
                Expanded(
                  child: _buildFinancialItem(
                    isDark,
                    'Income',
                    savings.income,
                    Icons.arrow_downward_rounded,
                    AppTheme.successColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
                ),
                Expanded(
                  child: _buildFinancialItem(
                    isDark,
                    'Expenses',
                    savings.expenses,
                    Icons.arrow_upward_rounded,
                    AppTheme.errorColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Savings Highlight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: savingsColor.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: savingsColor.withAlpha(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.savings_rounded, color: savingsColor, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Savings',
                        style: AppTheme.bodyLarge.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${savings.savings.toStringAsFixed(0)}',
                    style: AppTheme.heading3.copyWith(color: savingsColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Savings Rate Progress
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: savingsRate / 100,
                      minHeight: 8,
                      backgroundColor: savingsColor.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation<Color>(savingsColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: savingsColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${savingsRate.toStringAsFixed(0)}%',
                    style: AppTheme.labelLarge.copyWith(color: savingsColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialItem(bool isDark, String label, double amount, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: AppTheme.heading4.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showEditSavingsDialog(MonthlySavings savings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incomeController = TextEditingController(text: savings.income.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Edit Income',
              style: AppTheme.heading3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
            Text(
              '${DateFormat.MMMM().format(DateTime(savings.year, savings.month))} ${savings.year}',
              style: AppTheme.bodyMedium.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Income Amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final income = double.tryParse(incomeController.text);
                      if (income != null) {
                        await Provider.of<MonthlySavingsProvider>(context, listen: false)
                            .updateSavingsForBudget(savings.month, savings.year, income);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark, int totalPages, int totalItems, int startIdx, int endIdx) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 10),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
            onPressed: _currentPage > 0 
              ? () => setState(() => _currentPage--) 
              : null,
            isDark: isDark,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                'Showing ${startIdx + 1} - $endIdx of $totalItems',
                style: AppTheme.caption.copyWith(color: Colors.grey),
              ),
            ],
          ),
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            onPressed: _currentPage < totalPages - 1 
              ? () => setState(() => _currentPage++) 
              : null,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed, required bool isDark}) {
    final bool isDisabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDisabled 
              ? (isDark ? Colors.white10 : Colors.grey.shade100)
              : AppTheme.primaryColor.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled 
                ? Colors.transparent 
                : AppTheme.primaryColor.withAlpha(30),
            ),
          ),
          child: Icon(
            icon,
            color: isDisabled 
              ? Colors.grey 
              : AppTheme.primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(MonthlySavings savings) async {
    final monthName = DateFormat.MMMM().format(DateTime(savings.year, savings.month));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Delete savings record for $monthName ${savings.year}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && savings.id != null) {
      if (!mounted) return;
      await Provider.of<MonthlySavingsProvider>(context, listen: false).deleteSavings(savings.id!);
    }
  }
}

// Add Savings Bottom Sheet
class _AddSavingsBottomSheet extends StatefulWidget {
  @override
  State<_AddSavingsBottomSheet> createState() => _AddSavingsBottomSheetState();
}

class _AddSavingsBottomSheetState extends State<_AddSavingsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _saveSavings() async {
    if (_formKey.currentState!.validate()) {
      final income = double.parse(_incomeController.text);
      await Provider.of<MonthlySavingsProvider>(context, listen: false)
          .updateSavingsForBudget(_selectedMonth, _selectedYear, income);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Savings record saved!'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
                        'July', 'August', 'September', 'October', 'November', 'December'];
    final years = List.generate(10, (i) => DateTime.now().year - 5 + i);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppTheme.successGradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_chart_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Income Record',
                        style: AppTheme.heading3.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Set your monthly income/budget',
                        style: AppTheme.caption.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Income Field
            TextFormField(
              controller: _incomeController,
              decoration: const InputDecoration(
                labelText: 'Income Amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter an amount';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Month/Year Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    items: List.generate(12, (i) {
                      final month = i + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(monthNames[i]),
                      );
                    }),
                    onChanged: (val) {
                      setState(() => _selectedMonth = val!);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                    ),
                    items: years.map((year) {
                      return DropdownMenuItem(value: year, child: Text(year.toString()));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedYear = val!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppTheme.successGradient),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.successColor.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveSavings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
