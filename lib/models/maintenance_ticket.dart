class MaintenanceTicket {
  final String? id;
  final String unitId;
  final String tenantId;
  final String issue;
  final String status;
  final DateTime createdAt;

  MaintenanceTicket({
    this.id,
    required this.unitId,
    required this.tenantId,
    required this.issue,
    this.status = 'open',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'unitId': unitId,
    'tenantId': tenantId,
    'issue': issue,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MaintenanceTicket.fromMap(Map<String, dynamic> map, String docId) =>
      MaintenanceTicket(
        id: docId,
        unitId: map['unitId'] as String,
        tenantId: map['tenantId'] as String,
        issue: map['issue'] as String,
        status: (map['status'] as String?) ?? 'open',
        createdAt: (map['createdAt'] as String?) != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
      );
}
