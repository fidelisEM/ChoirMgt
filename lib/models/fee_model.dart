enum FeeType { weekly, monthly, quarterly, annual, oneTime, event }

enum FeeStatus { pending, paid, overdue, partial }

class FeeDefinitionModel {
  FeeDefinitionModel({
    required this.id,
    required this.choirId,
    required this.name,
    required this.description,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.category,
    this.metadata = const {},
  });

  factory FeeDefinitionModel.fromJson(Map<String, dynamic> json) {
    return FeeDefinitionModel(
      id: json['id'] ?? '',
      choirId: json['choir_id'] ?? json['choirId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      type: FeeType.values.firstWhere(
        (type) => type.toString().split('.').last == json['type'],
        orElse: () => FeeType.monthly,
      ),
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      startDate: (json['start_date'] ?? json['startDate']) != null
          ? DateTime.parse(json['start_date'] ?? json['startDate'])
          : null,
      endDate: (json['end_date'] ?? json['endDate']) != null
          ? DateTime.parse(json['end_date'] ?? json['endDate'])
          : null,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      category: json['category'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  final String id;
  final String choirId;
  final String name;
  final String description;
  final double amount;
  final FeeType type;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? category;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'choir_id': choirId,
      'name': name,
      'description': description,
      'amount': amount,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'category': category,
      'metadata': metadata,
    };
  }

  FeeDefinitionModel copyWith({
    String? id,
    String? choirId,
    String? name,
    String? description,
    double? amount,
    FeeType? type,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return FeeDefinitionModel(
      id: id ?? this.id,
      choirId: choirId ?? this.choirId,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }

  // Calculate next due date for recurring fees
  DateTime? getNextDueDate({DateTime? fromDate}) {
    final baseDate = fromDate ?? DateTime.now();

    if (!isActive || type == FeeType.oneTime) {
      return null;
    }

    switch (type) {
      case FeeType.weekly:
        return baseDate.add(const Duration(days: 7));
      case FeeType.monthly:
        return DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
      case FeeType.quarterly:
        return DateTime(baseDate.year, baseDate.month + 3, baseDate.day);
      case FeeType.annual:
        return DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
      case FeeType.oneTime:
      case FeeType.event:
        return startDate;
    }
  }

  // Check if fee should be applied to a member at a given date
  bool isApplicableAt(DateTime date) {
    if (!isActive) return false;
    if (startDate != null && date.isBefore(startDate!)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    return true;
  }
}

class MemberFeeModel {
  MemberFeeModel({
    required this.id,
    required this.memberId,
    required this.feeDefinitionId,
    required this.choirId,
    required this.amountDue,
    this.amountPaid = 0.0,
    required this.dueDate,
    this.status = FeeStatus.pending,
    required this.createdAt,
    this.paidAt,
    this.paymentReference,
    this.notes,
    this.metadata = const {},
  });

  factory MemberFeeModel.fromJson(Map<String, dynamic> json) {
    return MemberFeeModel(
      id: json['id'] ?? '',
      memberId: json['member_id'] ?? json['memberId'] ?? '',
      feeDefinitionId:
          json['fee_definition_id'] ?? json['feeDefinitionId'] ?? '',
      choirId: json['choir_id'] ?? json['choirId'] ?? '',
      amountDue: (json['amount_due'] ?? json['amountDue'] ?? 0.0).toDouble(),
      amountPaid: (json['amount_paid'] ?? json['amountPaid'] ?? 0.0).toDouble(),
      dueDate: DateTime.parse(
        json['due_date'] ?? json['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      status: FeeStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => FeeStatus.pending,
      ),
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      paidAt: (json['paid_at'] ?? json['paidAt']) != null
          ? DateTime.parse(json['paid_at'] ?? json['paidAt'])
          : null,
      paymentReference: json['payment_reference'] ?? json['paymentReference'],
      notes: json['notes'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  final String id;
  final String memberId;
  final String feeDefinitionId;
  final String choirId;
  final double amountDue;
  final double amountPaid;
  final DateTime dueDate;
  final FeeStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? paymentReference;
  final String? notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'fee_definition_id': feeDefinitionId,
      'choir_id': choirId,
      'amount_due': amountDue,
      'amount_paid': amountPaid,
      'due_date': dueDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'payment_reference': paymentReference,
      'notes': notes,
      'metadata': metadata,
    };
  }

  MemberFeeModel copyWith({
    String? id,
    String? memberId,
    String? feeDefinitionId,
    String? choirId,
    double? amountDue,
    double? amountPaid,
    DateTime? dueDate,
    FeeStatus? status,
    DateTime? createdAt,
    DateTime? paidAt,
    String? paymentReference,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return MemberFeeModel(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      feeDefinitionId: feeDefinitionId ?? this.feeDefinitionId,
      choirId: choirId ?? this.choirId,
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Utility getters
  double get outstandingAmount => amountDue - amountPaid;
  bool get isPaid => amountPaid >= amountDue;
  bool get isPartial => amountPaid > 0 && amountPaid < amountDue;
  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isPaid;

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  double get paymentProgress =>
      amountDue > 0 ? (amountPaid / amountDue).clamp(0.0, 1.0) : 0.0;
}

class FeePaymentModel {
  FeePaymentModel({
    required this.id,
    required this.memberFeeId,
    required this.memberId,
    required this.choirId,
    required this.amount,
    required this.paidAt,
    required this.paymentMethod,
    this.reference,
    this.notes,
    required this.recordedBy,
    this.metadata = const {},
  });

  factory FeePaymentModel.fromJson(Map<String, dynamic> json) {
    return FeePaymentModel(
      id: json['id'] ?? '',
      memberFeeId: json['member_fee_id'] ?? json['memberFeeId'] ?? '',
      memberId: json['member_id'] ?? json['memberId'] ?? '',
      choirId: json['choir_id'] ?? json['choirId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paidAt: DateTime.parse(
        json['paid_at'] ?? json['paidAt'] ?? DateTime.now().toIso8601String(),
      ),
      paymentMethod: json['payment_method'] ?? json['paymentMethod'] ?? '',
      reference: json['reference'],
      notes: json['notes'],
      recordedBy: json['recorded_by'] ?? json['recordedBy'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  final String id;
  final String memberFeeId;
  final String memberId;
  final String choirId;
  final double amount;
  final DateTime paidAt;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final String recordedBy;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_fee_id': memberFeeId,
      'member_id': memberId,
      'choir_id': choirId,
      'amount': amount,
      'paid_at': paidAt.toIso8601String(),
      'payment_method': paymentMethod,
      'reference': reference,
      'notes': notes,
      'recorded_by': recordedBy,
      'metadata': metadata,
    };
  }
}
