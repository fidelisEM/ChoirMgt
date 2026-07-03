

enum AttendanceStatus { present, late, absent }
enum EventType { rehearsal, service, meeting, other }

class AttendanceModel {

  AttendanceModel({
    required this.id,
    required this.sessionId,
    required this.memberId,
    required this.userId,
    required this.choirId,
    required this.eventDate,
    required this.status,
    required this.recordedBy,
    required this.recordedAt,
    this.notes,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      sessionId: json['sessionId'] ?? '',
      memberId: json['memberId'] ?? '',
      userId: json['userId'] ?? '',
      choirId: json['choirId'] ?? '',
      eventDate: DateTime.tryParse(json['eventDate'] ?? '') ?? DateTime.now(),
      status: AttendanceStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      recordedBy: json['recordedBy'] ?? '',
      recordedAt: DateTime.tryParse(json['recordedAt'] ?? '') ?? DateTime.now(),
      notes: json['notes'],
    );
  }
  final String id;
  final String sessionId;
  final String memberId;
  final String userId;
  final String choirId;
  final DateTime eventDate;
  final AttendanceStatus status;
  final String recordedBy;
  final DateTime recordedAt;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'memberId': memberId,
      'userId': userId,
      'choirId': choirId,
      'eventDate': eventDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'recordedBy': recordedBy,
      'recordedAt': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? sessionId,
    String? memberId,
    String? userId,
    String? choirId,
    DateTime? eventDate,
    AttendanceStatus? status,
    String? recordedBy,
    DateTime? recordedAt,
    String? notes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      memberId: memberId ?? this.memberId,
      userId: userId ?? this.userId,
      choirId: choirId ?? this.choirId,
      eventDate: eventDate ?? this.eventDate,
      status: status ?? this.status,
      recordedBy: recordedBy ?? this.recordedBy,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
    );
  }
}

class AttendanceSessionModel {

  AttendanceSessionModel({
    required this.id,
    required this.choirId,
    required this.leaderId,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.eventType,
    required this.title,
    this.description,
    this.graceMinutes = 15,
    this.isActive = true,
    required this.createdAt,
  });

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionModel(
      id: json['id'] ?? '',
      choirId: json['choirId'] ?? '',
      leaderId: json['leaderId'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null 
          ? DateTime.tryParse(json['endTime'] ?? '') 
          : null,
      eventType: EventType.values.firstWhere(
        (type) => type.toString().split('.').last == json['eventType'],
        orElse: () => EventType.other,
      ),
      title: json['title'] ?? '',
      description: json['description'],
      graceMinutes: json['graceMinutes'] ?? 15,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
  final String id;
  final String choirId;
  final String leaderId;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final EventType eventType;
  final String title;
  final String? description;
  final int graceMinutes;
  final bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'choirId': choirId,
      'leaderId': leaderId,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'eventType': eventType.toString().split('.').last,
      'title': title,
      'description': description,
      'graceMinutes': graceMinutes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AttendanceRecordModel {

  AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.memberId,
    required this.userId,
    required this.status,
    this.checkInTime,
    this.notes,
    required this.recordedAt,
    required this.recordedBy,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] ?? '',
      sessionId: json['sessionId'] ?? '',
      memberId: json['memberId'] ?? '',
      userId: json['userId'] ?? '',
      status: AttendanceStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      checkInTime: json['checkInTime'] != null 
          ? DateTime.tryParse(json['checkInTime'] ?? '') 
          : null,
      notes: json['notes'],
      recordedAt: DateTime.tryParse(json['recordedAt'] ?? '') ?? DateTime.now(),
      recordedBy: json['recordedBy'] ?? '',
    );
  }
  final String id;
  final String sessionId;
  final String memberId;
  final String userId;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final String? notes;
  final DateTime recordedAt;
  final String recordedBy;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'memberId': memberId,
      'userId': userId,
      'status': status.toString().split('.').last,
      'checkInTime': checkInTime?.toIso8601String(),
      'notes': notes,
      'recordedAt': recordedAt.toIso8601String(),
      'recordedBy': recordedBy,
    };
  }

  AttendanceRecordModel copyWith({
    String? id,
    String? sessionId,
    String? memberId,
    String? userId,
    AttendanceStatus? status,
    DateTime? checkInTime,
    String? notes,
    DateTime? recordedAt,
    String? recordedBy,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      memberId: memberId ?? this.memberId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }
}