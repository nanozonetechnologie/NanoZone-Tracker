class MonthlySavings {
  final int? id;
  final int month;
  final int year;
  final double income;
  final double expenses;
  final double savings;

  MonthlySavings({
    this.id,
    required this.month,
    required this.year,
    required this.income,
    required this.expenses,
    required this.savings,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'month': month,
        'year': year,
        'income': income,
        'expenses': expenses,
        'savings': savings,
      };

  factory MonthlySavings.fromMap(Map<String, dynamic> map) => MonthlySavings(
        id: map['id'],
        month: map['month'],
        year: map['year'],
        income: (map['income'] as num).toDouble(),
        expenses: (map['expenses'] as num).toDouble(),
        savings: (map['savings'] as num).toDouble(),
      );
}
