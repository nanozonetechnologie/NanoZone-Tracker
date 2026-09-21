import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum TrendPeriod { monthly, yearly }

class TrendGraph extends StatefulWidget {
  const TrendGraph({super.key});

  @override
  State<TrendGraph> createState() => _TrendGraphState();
}

class _TrendGraphState extends State<TrendGraph> {
  TrendPeriod _selectedPeriod = TrendPeriod.monthly;
  final _yearController = TextEditingController();
  int _selectedYear = DateTime.now().year;
  int _yearRange = 5;

  static const _chartPrimary = Color(0xFF6C63FF);
  static const _chartSecondary = Color(0xFF5A52E0);

  @override
  void initState() {
    super.initState();
    _yearController.text = _selectedYear.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrendData();
    });
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _loadTrendData() {
    if (!mounted) return;
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    if (_selectedPeriod == TrendPeriod.monthly) {
      provider.fetchMonthlyTrend(_selectedYear);
    } else {
      provider.fetchYearlyTrend(_yearRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_chartPrimary, _chartSecondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Expense Trends',
                style: AppTheme.heading3.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Filter Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segmented toggle for Monthly / Yearly
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildToggleButton('Monthly', TrendPeriod.monthly, isDark),
                      const SizedBox(width: 4),
                      _buildToggleButton('Yearly', TrendPeriod.yearly, isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Monthly: Year navigation
                if (_selectedPeriod == TrendPeriod.monthly)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavButton(Icons.chevron_left_rounded, () {
                        setState(() {
                          _selectedYear--;
                          _yearController.text = _selectedYear.toString();
                        });
                        _loadTrendData();
                      }, isDark),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _showYearPickerDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: _chartPrimary.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _chartPrimary.withAlpha(40)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: _chartPrimary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedYear.toString(),
                                style: AppTheme.heading3.copyWith(color: _chartPrimary, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildNavButton(Icons.chevron_right_rounded, () {
                        setState(() {
                          _selectedYear++;
                          _yearController.text = _selectedYear.toString();
                        });
                        _loadTrendData();
                      }, isDark),
                    ],
                  ),

                // Yearly: Range selector chips
                if (_selectedPeriod == TrendPeriod.yearly)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [3, 5, 10].map((years) {
                      final isSelected = _yearRange == years;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _yearRange = years);
                            _loadTrendData();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(colors: [_chartPrimary, _chartSecondary])
                                  : null,
                              color: isSelected ? null : (isDark ? Colors.white.withAlpha(8) : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? null : Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade300),
                            ),
                            child: Text(
                              '$years Yrs',
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Chart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
            child: _buildLineChart(isDark),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildToggleButton(String label, TrendPeriod period, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = period);
          _loadTrendData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? const LinearGradient(colors: [_chartPrimary, _chartSecondary]) : null,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [BoxShadow(color: _chartPrimary.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade300),
        ),
        child: Icon(icon, size: 22, color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
      ),
    );
  }

  void _showYearPickerDialog(BuildContext context) async {
    final currentYear = DateTime.now().year;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Year'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2000),
            lastDate: DateTime(currentYear + 5),
            selectedDate: DateTime(_selectedYear),
            onChanged: (DateTime dt) => Navigator.pop(ctx, dt.year),
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedYear = result;
        _yearController.text = result.toString();
      });
      _loadTrendData();
    }
  }

  Widget _buildLineChart(bool isDark) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final data = _selectedPeriod == TrendPeriod.monthly
        ? expenseProvider.monthlyTrendData
        : expenseProvider.yearlyTrendData;

    if (data.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _chartPrimary.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.show_chart_rounded, size: 48, color: _chartPrimary.withAlpha(100)),
              ),
              const SizedBox(height: 16),
              Text(
                'No data available',
                style: AppTheme.bodyLarge.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add expenses to see trends here',
                style: AppTheme.caption.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final spots = data.entries
        .map((entry) => FlSpot(double.parse(entry.key), entry.value))
        .toList();
    spots.sort((a, b) => a.x.compareTo(b.x));

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final gridColor = isDark ? Colors.white.withAlpha(12) : Colors.grey.shade200;

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: gridColor, strokeWidth: 1, dashArray: [6, 4]);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (_selectedPeriod == TrendPeriod.monthly) {
                    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    int month = value.toInt();
                    if (month >= 1 && month <= 12) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          monthNames[month - 1],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      );
                    }
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  String label;
                  if (value >= 100000) {
                    label = '₹${(value / 100000).toStringAsFixed(1)}L';
                  } else if (value >= 1000) {
                    label = '₹${(value / 1000).toStringAsFixed(1)}K';
                  } else {
                    label = '₹${value.toInt()}';
                  }
                  return Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: spots.first.x,
          maxX: spots.last.x,
          minY: 0,
          maxY: maxY * 1.15,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => isDark ? AppTheme.cardDark : Colors.white,
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              tooltipBorder: BorderSide(color: _chartPrimary.withAlpha(40)),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  String label;
                  if (_selectedPeriod == TrendPeriod.monthly) {
                    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    final idx = spot.x.toInt() - 1;
                    label = (idx >= 0 && idx < 12) ? monthNames[idx] : '';
                  } else {
                    label = spot.x.toInt().toString();
                  }
                  return LineTooltipItem(
                    '$label\n',
                    TextStyle(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: '₹${spot.y.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: _chartPrimary.withAlpha(40), strokeWidth: 1, dashArray: [4, 4]),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: _chartPrimary,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              gradient: const LinearGradient(colors: [_chartPrimary, _chartSecondary]),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: _chartPrimary,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _chartPrimary.withAlpha(60),
                    _chartPrimary.withAlpha(10),
                    _chartPrimary.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
