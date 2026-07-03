import '../models/activity_model.dart';
import '../utils/logger.dart';

class ActivityService {
  // In a real app, this would connect to your backend/database
  // For now, we'll generate sample activities based on choir data
  
  Future<List<ActivityModel>> getChoirActivities(String choirId, {int limit = 10}) async {
    // Generate realistic activities based on recent choir operations
    final now = DateTime.now();
    
    final activities = <ActivityModel>[
      ActivityModel(
        id: 'activity_1',
        choirId: choirId,
        userId: 'system',
        type: ActivityType.memberJoined,
        title: 'New member joined',
        description: 'A new member has joined the choir',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityModel(
        id: 'activity_2',
        choirId: choirId,
        userId: 'system',
        type: ActivityType.attendanceRecorded,
        title: 'Attendance recorded',
        description: 'Sunday service attendance has been recorded',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ActivityModel(
        id: 'activity_3',
        choirId: choirId,
        userId: 'system',
        type: ActivityType.paymentReceived,
        title: 'Payment received',
        description: 'Monthly dues payment received',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      ActivityModel(
        id: 'activity_4',
        choirId: choirId,
        userId: 'system',
        type: ActivityType.choirUpdated,
        title: 'Choir information updated',
        description: 'Choir schedule and location updated',
        timestamp: now.subtract(const Duration(days: 5)),
      ),
      ActivityModel(
        id: 'activity_5',
        choirId: choirId,
        userId: 'system',
        type: ActivityType.eventCreated,
        title: 'New event created',
        description: 'Special Christmas concert event added',
        timestamp: now.subtract(const Duration(days: 7)),
      ),
    ];
    
    // Sort by timestamp (newest first) and limit
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(limit).toList();
  }

  Future<void> recordActivity({
    required String choirId,
    required String userId,
    required ActivityType type,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    // In a real implementation, this would save to database
    final activity = ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      choirId: choirId,
      userId: userId,
      type: type,
      title: title,
      description: description,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    // For now, just log the activity (in real app, save to database)
    Logger.debug('Activity recorded: ${activity.toJson()}');
  }

  // Helper method to create activity when member joins
  Future<void> recordMemberJoined(String choirId, String newMemberUserId, String memberName) async {
    await recordActivity(
      choirId: choirId,
      userId: 'system', // or the user who added the member
      type: ActivityType.memberJoined,
      title: 'New member joined',
      description: '$memberName joined the choir',
      metadata: {'member_user_id': newMemberUserId},
    );
  }

  // Helper method to create activity when attendance is recorded
  Future<void> recordAttendanceSession(String choirId, String sessionName, int attendeeCount) async {
    await recordActivity(
      choirId: choirId,
      userId: 'system',
      type: ActivityType.attendanceRecorded,
      title: 'Attendance recorded',
      description: '$sessionName - $attendeeCount members attended',
      metadata: {'session_name': sessionName, 'attendee_count': attendeeCount},
    );
  }

  // Helper method to create activity when payment is received
  Future<void> recordPaymentReceived(String choirId, String memberName, double amount) async {
    await recordActivity(
      choirId: choirId,
      userId: 'system',
      type: ActivityType.paymentReceived,
      title: 'Payment received',
      description: '$memberName paid \$${amount.toStringAsFixed(2)}',
      metadata: {'member_name': memberName, 'amount': amount},
    );
  }
}