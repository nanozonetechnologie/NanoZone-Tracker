import 'package:flutter/material.dart';

class BudgetCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final Widget? child;

  const BudgetCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (child != null)
              child!
            else
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
