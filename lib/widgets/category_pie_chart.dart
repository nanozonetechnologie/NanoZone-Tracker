import 'package:exptrackerforhybridos/app_constants.dart';
import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryPieChart extends StatefulWidget {
  final int month;
  final int year;

  const CategoryPieChart({super.key, required this.month, required this.year});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenses = expenseProvider.items
        .where((exp) => 
            exp.date.month == widget.month && 
            exp.date.year == widget.year &&
            !exp.category.startsWith('Gift / Outside Budget'))
        .toList();

    // Return empty state if no expenses
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.pie_chart_outline_rounded,
                size: 48,
                color: AppTheme.primaryColor.withAlpha(100),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses for this period',
              style: AppTheme.bodyLarge.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    final Map<String, double> categorySpending = {};
    for (var exp in expenses) {
      categorySpending.update(exp.category, (value) => value + exp.amount,
          ifAbsent: () => exp.amount);
    }

    final double totalAmount = expenses.fold(0.0, (sum, item) => sum + item.amount);

    // Sort by amount descending
    final sortedEntries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<PieChartSectionData> sections = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final category = sortedEntries[i].key;
      final amount = sortedEntries[i].value;
      final percent = (amount / totalAmount * 100);
      final isTouched = i == _touchedIndex;
      final color = categoryColors[category] ?? Colors.grey;

      sections.add(PieChartSectionData(
        color: color,
        value: amount,
        title: '${percent.toStringAsFixed(0)}%',
        radius: isTouched ? 95.0 : 80.0,
        titleStyle: TextStyle(
          fontSize: isTouched ? 20.0 : 14.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black45, blurRadius: 4),
          ],
        ),
        titlePositionPercentageOffset: 0.55,
        badgeWidget: null,
      ));
    }

    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              centerSpaceColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Legend
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: sortedEntries.map((entry) {
            final category = entry.key;
            final amount = entry.value;
            final percent = (amount / totalAmount * 100).toStringAsFixed(0);
            final color = categoryColors[category] ?? Colors.grey;
            final index = sortedEntries.indexOf(entry);
            final isTouched = index == _touchedIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _touchedIndex = isTouched ? -1 : index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isTouched
                      ? color.withAlpha(25)
                      : (isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isTouched ? color : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
                    width: isTouched ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isTouched ? FontWeight.w700 : FontWeight.w500,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
