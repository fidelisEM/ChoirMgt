import 'package:flutter/material.dart';

enum ActivityType {
  memberJoined,
  memberLeft,
  attendanceRecorded,
  paymentReceived,
  eventCreated,
  choirUpdated,
  userPromoted,
  userDemoted,
}

class ActivityModel {

  ActivityModel({
    required this.id,
    required this.choirId,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] ?? '',
      choirId: json['choir_id'] ?? '',
      userId: json['user_id'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ActivityType.choirUpdated,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'],
    );
  }
  final String id;
  final String choirId;
  final String userId; // Who performed the action
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'choir_id': choirId,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  IconData get icon {
    switch (type) {
      case ActivityType.memberJoined:
        return Icons.person_add;
      case ActivityType.memberLeft:
        return Icons.person_remove;
      case ActivityType.attendanceRecorded:
        return Icons.check_circle;
      case ActivityType.paymentReceived:
        return Icons.payment;
      case ActivityType.eventCreated:
        return Icons.event;
      case ActivityType.choirUpdated:
        return Icons.edit;
      case ActivityType.userPromoted:
        return Icons.trending_up;
      case ActivityType.userDemoted:
        return Icons.trending_down;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.memberJoined:
      case ActivityType.paymentReceived:
      case ActivityType.userPromoted:
        return Colors.green;
      case ActivityType.memberLeft:
      case ActivityType.userDemoted:
        return Colors.red;
      case ActivityType.attendanceRecorded:
      case ActivityType.eventCreated:
        return Colors.blue;
      case ActivityType.choirUpdated:
        return Colors.orange;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).round();
      return '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).round();
      return '$months months ago';
    }
  }
}