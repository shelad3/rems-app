class Expense {
  final int? id;
  final int propertyId;
  final int? unitId;
  final String title;
  final double amount;
  final String category;
  final String description;
  final String? receiptPath;
  final DateTime expenseDate;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.propertyId,
    this.unitId,
    required this.title,
    required this.amount,
    this.category = 'Repairs',
    this.description = '',
    this.receiptPath,
    DateTime? expenseDate,
    DateTime? createdAt,
  })  : expenseDate = expenseDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'property_id': propertyId,
      'unit_id': unitId,
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'receipt_path': receiptPath,
      'expense_date': expenseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      propertyId: map['property_id'] as int,
      unitId: map['unit_id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: (map['category'] as String?) ?? 'Repairs',
      description: (map['description'] as String?) ?? '',
      receiptPath: map['receipt_path'] as String?,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Expense copyWith({
    int? id,
    int? propertyId,
    int? unitId,
    String? title,
    double? amount,
    String? category,
    String? description,
    String? receiptPath,
    DateTime? expenseDate,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      receiptPath: receiptPath ?? this.receiptPath,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
