class SavingsGoal {
  final int? id;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final DateTime createdDate;
  final String? iconName;
  final String? colorHex;
  final bool isCompleted;

  SavingsGoal({
    this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    DateTime? createdDate,
    this.iconName,
    this.colorHex,
    this.isCompleted = false,
  }) : createdDate = createdDate ?? DateTime.now();

  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Calculate remaining amount to save
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  /// Calculate months remaining until target date
  int get monthsRemaining {
    final now = DateTime.now();
    final months = (targetDate.year - now.year) * 12 + (targetDate.month - now.month);
    return months < 0 ? 0 : months;
  }

  /// Calculate days remaining until target date
  int get daysRemaining {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  /// Calculate required monthly savings to reach goal
  double get requiredMonthlySavings {
    if (remainingAmount <= 0) return 0.0;
    if (monthsRemaining <= 0) return remainingAmount;
    return remainingAmount / monthsRemaining;
  }

  /// Check if goal is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && !isCompleted;
  }

  /// Check if goal is on track
  bool get isOnTrack {
    if (isCompleted) return true;
    if (targetAmount <= 0) return true;

    final now = DateTime.now();
    final totalDays = targetDate.difference(createdDate).inDays;
    final elapsedDays = now.difference(createdDate).inDays;

    if (totalDays <= 0) return progressPercentage >= 1.0;

    final expectedProgress = elapsedDays / totalDays;
    return progressPercentage >= expectedProgress;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String(),
      'created_date': createdDate.toIso8601String(),
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetDate: DateTime.parse(map['target_date']),
      createdDate: map['created_date'] != null
          ? DateTime.parse(map['created_date'])
          : DateTime.now(),
      iconName: map['icon_name'],
      colorHex: map['color_hex'],
      isCompleted: map['is_completed'] == 1,
    );
  }

  SavingsGoal copyWith({
    int? id,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdDate,
    String? iconName,
    String? colorHex,
    bool? isCompleted,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdDate: createdDate ?? this.createdDate,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

