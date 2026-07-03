

enum MemberStatus { active, inactive, suspended }

enum MemberRole { 
  leader, 
  committee, 
  board, 
  choir, 
  patron, 
  trainer 
}

enum MemberLevel {
  national,
  diocese,
  parish,
  choir
}

class ChoirMemberModel {

  ChoirMemberModel({
    required this.id,
    required this.userId,
    required this.choirId,
    required this.registrationNumber,
    required this.joinDate,
    this.status = MemberStatus.active,
    this.role = MemberRole.choir,
    this.level = MemberLevel.choir,
    this.lastAttendance,
    this.totalAttendances = 0,
    this.totalAbsences = 0,
    this.totalLateArrivals = 0,
    this.outstandingFees = 0.0,
    this.totalPaid = 0.0,
    this.qrCode,
    this.metadata = const {},
  });

  factory ChoirMemberModel.fromJson(Map<String, dynamic> json) {
    return ChoirMemberModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      choirId: json['choir_id'] ?? json['choirId'] ?? '',
      registrationNumber: json['registration_number'] ?? json['registrationNumber'] ?? '',
      joinDate: DateTime.parse(json['join_date'] ?? json['joinDate'] ?? DateTime.now().toIso8601String()),
      status: MemberStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => MemberStatus.active,
      ),
      role: MemberRole.values.firstWhere(
        (role) => role.toString().split('.').last == json['role'],
        orElse: () => MemberRole.choir,
      ),
      level: MemberLevel.values.firstWhere(
        (level) => level.toString().split('.').last == json['level'],
        orElse: () => MemberLevel.choir,
      ),
      lastAttendance: (json['last_attendance'] ?? json['lastAttendance']) != null
          ? DateTime.parse(json['last_attendance'] ?? json['lastAttendance'])
          : null,
      totalAttendances: json['total_attendances'] ?? json['totalAttendances'] ?? 0,
      totalAbsences: json['total_absences'] ?? json['totalAbsences'] ?? 0,
      totalLateArrivals: json['total_late_arrivals'] ?? json['totalLateArrivals'] ?? 0,
      outstandingFees: (json['outstanding_fees'] ?? json['outstandingFees'] ?? 0.0).toDouble(),
      totalPaid: (json['total_paid'] ?? json['totalPaid'] ?? 0.0).toDouble(),
      qrCode: json['qr_code'] ?? json['qrCode'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  final String id;
  final String userId;
  final String choirId;
  final String registrationNumber;
  final DateTime joinDate;
  final MemberStatus status;
  final MemberRole role;
  final MemberLevel level;
  final DateTime? lastAttendance;
  final int totalAttendances;
  final int totalAbsences;
  final int totalLateArrivals;
  final double outstandingFees;
  final double totalPaid;
  final String? qrCode;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'choir_id': choirId,
      'registration_number': registrationNumber,
      'join_date': joinDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'role': role.toString().split('.').last,
      'level': level.toString().split('.').last,
      'last_attendance': lastAttendance?.toIso8601String(),
      'total_attendances': totalAttendances,
      'total_absences': totalAbsences,
      'total_late_arrivals': totalLateArrivals,
      'outstanding_fees': outstandingFees,
      'total_paid': totalPaid,
      'qr_code': qrCode,
      'metadata': metadata,
    };
  }

  ChoirMemberModel copyWith({
    String? id,
    String? userId,
    String? choirId,
    String? registrationNumber,
    DateTime? joinDate,
    MemberStatus? status,
    MemberRole? role,
    MemberLevel? level,
    DateTime? lastAttendance,
    int? totalAttendances,
    int? totalAbsences,
    int? totalLateArrivals,
    double? outstandingFees,
    double? totalPaid,
    String? qrCode,
    Map<String, dynamic>? metadata,
  }) {
    return ChoirMemberModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      choirId: choirId ?? this.choirId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      role: role ?? this.role,
      level: level ?? this.level,
      lastAttendance: lastAttendance ?? this.lastAttendance,
      totalAttendances: totalAttendances ?? this.totalAttendances,
      totalAbsences: totalAbsences ?? this.totalAbsences,
      totalLateArrivals: totalLateArrivals ?? this.totalLateArrivals,
      outstandingFees: outstandingFees ?? this.outstandingFees,
      totalPaid: totalPaid ?? this.totalPaid,
      qrCode: qrCode ?? this.qrCode,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isActive => status == MemberStatus.active;
  bool get hasOutstandingFees => outstandingFees > 0;
  bool get isLeader => role == MemberRole.leader;
  bool get isCommittee => role == MemberRole.committee;
  bool get isBoard => role == MemberRole.board;
  
  double get attendanceRate {
    final total = totalAttendances + totalAbsences;
    return total > 0 ? totalAttendances / total : 0.0;
  }
  
  String get levelDisplayName {
    switch (level) {
      case MemberLevel.national:
        return 'National';
      case MemberLevel.diocese:
        return 'Diocese';
      case MemberLevel.parish:
        return 'Parish';
      case MemberLevel.choir:
        return 'Choir';
    }
  }

  String get roleDisplayName {
    switch (role) {
      case MemberRole.leader:
        return 'Leader';
      case MemberRole.committee:
        return 'Committee Member';
      case MemberRole.board:
        return 'Board Member';
      case MemberRole.choir:
        return 'Choir Member';
      case MemberRole.patron:
        return 'Patron';
      case MemberRole.trainer:
        return 'Trainer';
    }
  }

  String get fullRoleDisplayName {
    return '$levelDisplayName $roleDisplayName';
  }
}