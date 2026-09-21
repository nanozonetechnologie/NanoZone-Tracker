import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/monthly_savings.dart';

class SavingsCard extends StatelessWidget {
  final MonthlySavings savings;

  const SavingsCard({super.key, required this.savings});

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat.MMMM().format(DateTime(savings.year, savings.month));
    final savingsColor = savings.savings >= 0 ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthName ${savings.year}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('Income', '₹${savings.income.toStringAsFixed(2)}', context),
                _buildInfoColumn('Expenses', '₹${savings.expenses.toStringAsFixed(2)}', context),
                _buildInfoColumn('Savings', '₹${savings.savings.toStringAsFixed(2)}', context, color: savingsColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, BuildContext context, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}
