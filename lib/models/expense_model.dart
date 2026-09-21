class Expense {
  final int? id;
  final double amount;
  final String category;
  final DateTime date;
  final String? paymentMethod;
  final String? notes;
  final int? accountId;
  final int? debtId; // Links to debts table

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.paymentMethod,
    this.notes,
    this.accountId,
    this.debtId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
      'account_id': accountId,
      'debt_id': debtId,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'],
      date: DateTime.parse(map['date']),
      paymentMethod: map['payment_method'],
      notes: map['notes'],
      accountId: map['account_id'] as int?,
      debtId: map['debt_id'] as int?,
    );
  }

  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? notes,
    int? accountId,
    int? debtId,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      accountId: accountId ?? this.accountId,
      debtId: debtId ?? this.debtId,
    );
  }
}
