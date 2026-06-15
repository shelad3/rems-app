class Application {
  final String? id;
  final String unitId;
  final String tenantId;
  final String tenantName;
  final String? caretakerId;
  final String status;
  final double proposedRent;
  final double proposedDeposit;
  final String proposedDuration;
  final double? caretakerCounterRent;
  final double? caretakerCounterDeposit;
  final String? caretakerNotes;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  Application({
    this.id,
    required this.unitId,
    required this.tenantId,
    required this.tenantName,
    this.caretakerId,
    this.status = 'pending',
    this.proposedRent = 0,
    this.proposedDeposit = 0,
    this.proposedDuration = '1 year',
    this.caretakerCounterRent,
    this.caretakerCounterDeposit,
    this.caretakerNotes,
    DateTime? createdAt,
    this.reviewedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPending => status == 'pending';
  bool get isCountered => status == 'countered';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';

  double get effectiveRent => caretakerCounterRent ?? proposedRent;
  double get effectiveDeposit => caretakerCounterDeposit ?? proposedDeposit;

  Map<String, dynamic> toMap() => {
    'unitId': unitId,
    'tenantId': tenantId,
    'tenantName': tenantName,
    'caretakerId': caretakerId ?? '',
    'status': status,
    'proposedRent': proposedRent,
    'proposedDeposit': proposedDeposit,
    'proposedDuration': proposedDuration,
    if (caretakerCounterRent != null) 'caretakerCounterRent': caretakerCounterRent,
    if (caretakerCounterDeposit != null) 'caretakerCounterDeposit': caretakerCounterDeposit,
    if (caretakerNotes != null) 'caretakerNotes': caretakerNotes,
    'createdAt': createdAt.toIso8601String(),
    if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
  };

  factory Application.fromMap(Map<String, dynamic> map, String docId) => Application(
    id: docId,
    unitId: map['unitId'] as String,
    tenantId: map['tenantId'] as String,
    tenantName: (map['tenantName'] as String?) ?? '',
    caretakerId: (map['caretakerId'] as String?),
    status: (map['status'] as String?) ?? 'pending',
    proposedRent: ((map['proposedRent'] as num?)?.toDouble()) ?? 0,
    proposedDeposit: ((map['proposedDeposit'] as num?)?.toDouble()) ?? 0,
    proposedDuration: (map['proposedDuration'] as String?) ?? '1 year',
    caretakerCounterRent: (map['caretakerCounterRent'] as num?)?.toDouble(),
    caretakerCounterDeposit: (map['caretakerCounterDeposit'] as num?)?.toDouble(),
    caretakerNotes: map['caretakerNotes'] as String?,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'] as String)
        : DateTime.now(),
    reviewedAt: map['reviewedAt'] != null
        ? DateTime.parse(map['reviewedAt'] as String)
        : null,
  );
}
