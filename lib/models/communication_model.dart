class MessageModel { // For threading support

  MessageModel({
    required this.id,
    required this.choirId,
    required this.senderId,
    required this.senderName,
    required this.subject,
    required this.content,
    required this.type,
    this.recipients = const [],
    this.readBy = const [],
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.replies = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      choirId: json['choir_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? '',
      subject: json['subject'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'discussion',
      recipients: List<String>.from(json['recipients'] ?? []),
      readBy: List<String>.from(json['read_by'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isActive: json['is_active'] ?? true,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => MessageReplyModel.fromJson(reply as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  final String id;
  final String choirId;
  final String senderId;
  final String senderName;
  final String subject;
  final String content;
  final String type; // announcement, discussion, reminder, urgent
  final List<String> recipients; // Empty list means all choir members
  final List<String> readBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final List<MessageReplyModel> replies;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'choir_id': choirId,
      'sender_id': senderId,
      'sender_name': senderName,
      'subject': subject,
      'content': content,
      'type': type,
      'recipients': recipients,
      'read_by': readBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }
  
  // Database-specific JSON for Supabase (excludes replies to avoid circular issues)
  Map<String, dynamic> toDatabaseJson() {
    return {
      'choir_id': choirId,
      'sender_id': senderId,
      'sender_name': senderName,
      'subject': subject,
      'content': content,
      'type': type,
      'recipients': recipients,
      'read_by': readBy,
      'is_active': isActive,
    };
  }

  MessageModel copyWith({
    String? id,
    String? choirId,
    String? senderId,
    String? senderName,
    String? subject,
    String? content,
    String? type,
    List<String>? recipients,
    List<String>? readBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<MessageReplyModel>? replies,
  }) {
    return MessageModel(
      id: id ?? this.id,
      choirId: choirId ?? this.choirId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      type: type ?? this.type,
      recipients: recipients ?? this.recipients,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      replies: replies ?? this.replies,
    );
  }
  
  // Helper method to check if message is read by a specific user
  bool isReadByUser(String userId) {
    return readBy.contains(userId);
  }
  
  // Helper method to get unread reply count for a user
  int getUnreadReplyCount(String userId) {
    return replies.where((reply) => !reply.readBy.contains(userId)).length;
  }
  
  // Helper method to check if user can view this message
  bool canUserView(String userId, List<String> userChoirMemberIds) {
    // User can view if:
    // 1. Recipients is empty (all members) OR
    // 2. User is in recipients list OR
    // 3. User is the sender
    return recipients.isEmpty || 
           recipients.contains(userId) || 
           senderId == userId;
  }
}

class MessageReplyModel {

  MessageReplyModel({
    required this.id,
    required this.messageId,
    this.parentReplyId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.readBy = const [],
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory MessageReplyModel.fromJson(Map<String, dynamic> json) {
    return MessageReplyModel(
      id: json['id'] ?? '',
      messageId: json['message_id'] ?? '',
      parentReplyId: json['parent_reply_id'],
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? '',
      content: json['content'] ?? '',
      readBy: List<String>.from(json['read_by'] ?? []),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
  final String id;
  final String messageId;
  final String? parentReplyId; // For nested replies
  final String senderId;
  final String senderName;
  final String content;
  final List<String> readBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'parent_reply_id': parentReplyId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'read_by': readBy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  // Database-specific JSON for Supabase
  Map<String, dynamic> toDatabaseJson() {
    return {
      'message_id': messageId,
      'parent_reply_id': parentReplyId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'read_by': readBy,
      'is_active': isActive,
    };
  }
  
  // Helper method to check if reply is read by a specific user
  bool isReadByUser(String userId) {
    return readBy.contains(userId);
  }
  
  // Copy with method for immutable updates
  MessageReplyModel copyWith({
    String? id,
    String? messageId,
    String? parentReplyId,
    String? senderId,
    String? senderName,
    String? content,
    List<String>? readBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageReplyModel(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      parentReplyId: parentReplyId ?? this.parentReplyId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      readBy: readBy ?? this.readBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}