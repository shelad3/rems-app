class Payment {
  final int? id;
  final int leaseId;
  final int tenantId;
  final double amount;
  final DateTime paymentDate;
  final String paymentType;
  final String status;
  final String notes;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.leaseId,
    required this.tenantId,
    required this.amount,
    required this.paymentDate,
    this.paymentType = 'Rent',
    this.status = 'Paid',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lease_id': leaseId,
      'tenant_id': tenantId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_type': paymentType,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      leaseId: map['lease_id'] as int,
      tenantId: map['tenant_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentType: (map['payment_type'] as String?) ?? 'Rent',
      status: (map['status'] as String?) ?? 'Paid',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'leaseId': leaseId,
      'tenantId': tenantId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentType': paymentType,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'oldPaymentId': id,
    };
  }

  Payment copyWith({
    int? id,
    int? leaseId,
    int? tenantId,
    double? amount,
    DateTime? paymentDate,
    String? paymentType,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      leaseId: leaseId ?? this.leaseId,
      tenantId: tenantId ?? this.tenantId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
