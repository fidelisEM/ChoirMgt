

enum PaymentMethod { cash, bankTransfer, mobilePayment, other }
enum PaymentStatus { completed, pending, refunded, failed }
enum PaymentType { registration, monthly, quarterly, annual, special, other }
enum FeeFrequency { weekly, monthly, quarterly, annually }

class PaymentModel {

  PaymentModel({
    required this.id,
    required this.choirId,
    required this.memberId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.method,
    required this.description,
    this.reference,
    this.status = PaymentStatus.completed,
    required this.paymentDate,
    this.receivedBy,
    this.notes,
    this.currency = 'KES',
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      choirId: json['choir_id'] ?? json['choirId'] ?? '',
      memberId: json['member_id'] ?? json['memberId'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      type: PaymentType.values.firstWhere(
        (type) => type.toString().split('.').last == json['type'],
        orElse: () => PaymentType.other,
      ),
      method: PaymentMethod.values.firstWhere(
        (method) => method.toString().split('.').last == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      description: json['description'] ?? '',
      reference: json['reference'],
      status: PaymentStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => PaymentStatus.completed,
      ),
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : DateTime.now(),
      receivedBy: json['received_by'] ?? json['receivedBy'],
      notes: json['notes'],
      currency: json['currency'] ?? 'KES',
    );
  }
  final String id;
  final String choirId;
  final String memberId;
  final String userId;
  final double amount;
  final PaymentType type;
  final PaymentMethod method;
  final String description;
  final String? reference;
  final PaymentStatus status;
  final DateTime paymentDate;
  final String? receivedBy;
  final String? notes;
  final String currency;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'choir_id': choirId,
      'member_id': memberId,
      'user_id': userId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'method': method.toString().split('.').last,
      'description': description,
      'reference': reference,
      'status': status.toString().split('.').last,
      'payment_date': paymentDate.toIso8601String(),
      'received_by': receivedBy,
      'notes': notes,
      'currency': currency,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? choirId,
    String? memberId,
    String? userId,
    double? amount,
    PaymentType? type,
    PaymentMethod? method,
    String? description,
    String? reference,
    PaymentStatus? status,
    DateTime? paymentDate,
    String? receivedBy,
    String? notes,
    String? currency,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      choirId: choirId ?? this.choirId,
      memberId: memberId ?? this.memberId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      method: method ?? this.method,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      receivedBy: receivedBy ?? this.receivedBy,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
    );
  }
}

class FeeStructureModel {

  FeeStructureModel({
    required this.id,
    required this.choirId,
    required this.name,
    required this.description,
    required this.amount,
    required this.frequency,
    required this.effectiveDate,
    this.expiryDate,
    this.isActive = true,
    required this.createdAt,
  });

  factory FeeStructureModel.fromJson(Map<String, dynamic> json) {
    return FeeStructureModel(
      id: json['id'] ?? '',
      choirId: json['choirId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      frequency: FeeFrequency.values.firstWhere(
        (freq) => freq.toString().split('.').last == json['frequency'],
        orElse: () => FeeFrequency.monthly,
      ),
      effectiveDate: (json['effectiveDate'] ),
      expiryDate: json['expiryDate'] != null 
          ? (json['expiryDate'] ) 
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: (json['createdAt'] ),
    );
  }
  final String id;
  final String choirId;
  final String name;
  final String description;
  final double amount;
  final FeeFrequency frequency;
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'choirId': choirId,
      'name': name,
      'description': description,
      'amount': amount,
      'frequency': frequency.toString().split('.').last,
      'effectiveDate': DateTime.now().toIso8601String(),
      'expiryDate': expiryDate != null ? DateTime.now().toIso8601String() : null,
      'isActive': isActive,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

class PaymentRecordModel {

  PaymentRecordModel({
    required this.id,
    required this.memberId,
    required this.userId,
    required this.choirId,
    required this.feeStructureId,
    required this.amount,
    required this.paymentMethod,
    this.transactionReference,
    required this.paymentDate,
    required this.recordedAt,
    required this.recordedBy,
    this.notes,
    required this.forPeriodStart,
    required this.forPeriodEnd,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: json['id'] ?? '',
      memberId: json['memberId'] ?? '',
      userId: json['userId'] ?? '',
      choirId: json['choirId'] ?? '',
      feeStructureId: json['feeStructureId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (method) => method.toString().split('.').last == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      transactionReference: json['transactionReference'],
      paymentDate: (json['paymentDate'] ),
      recordedAt: (json['recordedAt'] ),
      recordedBy: json['recordedBy'] ?? '',
      notes: json['notes'],
      forPeriodStart: (json['forPeriodStart'] ),
      forPeriodEnd: (json['forPeriodEnd'] ),
    );
  }
  final String id;
  final String memberId;
  final String userId;
  final String choirId;
  final String feeStructureId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? transactionReference;
  final DateTime paymentDate;
  final DateTime recordedAt;
  final String recordedBy;
  final String? notes;
  final DateTime forPeriodStart;
  final DateTime forPeriodEnd;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'userId': userId,
      'choirId': choirId,
      'feeStructureId': feeStructureId,
      'amount': amount,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'transactionReference': transactionReference,
      'paymentDate': DateTime.now().toIso8601String(),
      'recordedAt': DateTime.now().toIso8601String(),
      'recordedBy': recordedBy,
      'notes': notes,
      'forPeriodStart': DateTime.now().toIso8601String(),
      'forPeriodEnd': DateTime.now().toIso8601String(),
    };
  }
}

class MemberPaymentStatusModel {

  MemberPaymentStatusModel({
    required this.memberId,
    required this.userId,
    required this.choirId,
    required this.status,
    required this.totalDue,
    required this.totalPaid,
    required this.outstandingAmount,
    this.lastPaymentDate,
    this.nextDueDate,
    this.recentPayments = const [],
  });
  final String memberId;
  final String userId;
  final String choirId;
  final PaymentStatus status;
  final double totalDue;
  final double totalPaid;
  final double outstandingAmount;
  final DateTime? lastPaymentDate;
  final DateTime? nextDueDate;
  final List<PaymentRecordModel> recentPayments;

  bool get isUpToDate => status == PaymentStatus.completed;
  bool get isOverdue => outstandingAmount > 0;
}