enum NotificationType {
  announcement,
  event,
  payment,
  attendance,
  system,
  attendanceReminder,
  paymentReminder,
  welcome,
  paymentConfirmation,
}

enum NotificationPriority { low, medium, high, urgent }

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.recipientId,
    this.choirId,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.data = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (type) => type.toString().split('.').last == json['type'],
        orElse: () => NotificationType.announcement,
      ),
      priority: NotificationPriority.values.firstWhere(
        (priority) => priority.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      recipientId: json['recipientId'],
      choirId: json['choirId'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      readAt: (json['read_at'] ?? json['readAt']) != null
          ? DateTime.parse(json['read_at'] ?? json['readAt'])
          : null,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final String? recipientId;
  final String? choirId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'recipientId': recipientId,
      'choirId': choirId,
      'isRead': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    String? recipientId,
    String? choirId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      recipientId: recipientId ?? this.recipientId,
      choirId: choirId ?? this.choirId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }
}
