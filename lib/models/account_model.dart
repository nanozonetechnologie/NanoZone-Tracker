/// Account types supported by the app
enum AccountType {
  bank,
  creditCard,
}

/// Model representing a bank account or credit card
class Account {
  final int? id;
  final String name;
  final AccountType type;
  final double balance;
  final double? creditLimit; // Only for credit cards
  final String? iconName;
  final String? colorHex;
  final bool isDefault;
  final DateTime createdDate;

  Account({
    this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.creditLimit,
    this.iconName,
    this.colorHex,
    this.isDefault = false,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  /// Total amount for display
  /// For bank: shows balance
  /// For credit card: shows spent amount (negative balance means spent)
  double get displayAmount => type == AccountType.creditCard ? -balance : balance;

  /// Available amount
  /// For bank: same as balance
  /// For credit card: creditLimit + balance (balance is negative when spent)
  double get availableAmount {
    if (type == AccountType.creditCard && creditLimit != null) {
      return creditLimit! + balance;
    }
    return balance;
  }

  /// Type as string for database storage
  String get typeString => type == AccountType.bank ? 'BANK' : 'CREDIT_CARD';

  /// Create Account from database map
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'] as String,
      type: (map['type'] as String) == 'BANK' ? AccountType.bank : AccountType.creditCard,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (map['credit_limit'] as num?)?.toDouble(),
      iconName: map['icon_name'] as String?,
      colorHex: map['color_hex'] as String?,
      isDefault: (map['is_default'] as int?) == 1,
      createdDate: map['created_date'] != null
          ? DateTime.parse(map['created_date'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': typeString,
      'balance': balance,
      'credit_limit': creditLimit,
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_default': isDefault ? 1 : 0,
      'created_date': createdDate.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Account copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? balance,
    double? creditLimit,
    String? iconName,
    String? colorHex,
    bool? isDefault,
    DateTime? createdDate,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}

