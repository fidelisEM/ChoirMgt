import '../models/models.dart';
import '../services/fee_service.dart';
import '../services/member_service.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';

class MemberStatusService {
  factory MemberStatusService() => _instance;
  MemberStatusService._internal();
  static final MemberStatusService _instance = MemberStatusService._internal();

  final MemberService _memberService = MemberService();
  final FeeService _feeService = FeeService();

  // Automation rules configuration
  static const int minAttendancesPerMonth = 3;
  static const double maxOutstandingFeesForActive = 500.0;
  static const int maxAbsenceDaysForActive = 30;

  Future<void> updateAllMemberStatuses(String choirId) async {
    try {
      Logger.info('Starting automatic status update for choir: $choirId');

      // Get all members of the choir
      final members = await _memberService.getChoirMembersWithUserInfo(choirId);

      for (final memberData in members) {
        await _updateMemberStatus(memberData);
      }

      Logger.info(
        'Completed automatic status update for ${members.length} members',
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to update member statuses', e, stackTrace);
    }
  }

  Future<void> _updateMemberStatus(Map<String, dynamic> memberData) async {
    try {
      final memberId = memberData['id'] as String;
      final choirId = memberData['choir_id'] as String;
      final currentStatus = MemberStatus.values.firstWhere(
        (status) => status.toString().split('.').last == memberData['status'],
        orElse: () => MemberStatus.active,
      );

      // Calculate new status based on rules
      final newStatus = await _calculateMemberStatus(
        memberId,
        choirId,
        memberData,
      );

      // Update status if changed
      if (newStatus != currentStatus) {
        await _memberService.updateMemberStatus(
          memberId: memberId,
          status: newStatus,
        );
        Logger.info(
          'Updated member $memberId status from $currentStatus to $newStatus',
        );

        // Optional: Send notification about status change
        await _notifyStatusChange(memberData, currentStatus, newStatus);
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to update status for member ${memberData['id']}',
        e,
        stackTrace,
      );
    }
  }

  Future<MemberStatus> _calculateMemberStatus(
    String memberId,
    String choirId,
    Map<String, dynamic> memberData,
  ) async {
    try {
      // Get member statistics
      final attendanceStats = await _getAttendanceStatistics(memberId, choirId);
      final paymentStats = await _getPaymentStatistics(memberId);
      final lastAttendance = _getLastAttendance(memberData);

      // Apply automation rules

      // Rule 1: Check outstanding fees
      if (paymentStats['outstandingFees'] > maxOutstandingFeesForActive) {
        return MemberStatus.inactive;
      }

      // Rule 2: Check recent attendance
      if (attendanceStats['attendancesThisMonth'] < minAttendancesPerMonth) {
        return MemberStatus.inactive;
      }

      // Rule 3: Check long absence
      if (lastAttendance != null) {
        final daysSinceLastAttendance = DateTime.now()
            .difference(lastAttendance)
            .inDays;
        if (daysSinceLastAttendance > maxAbsenceDaysForActive) {
          return MemberStatus.inactive;
        }
      }

      // Rule 4: Check attendance rate
      final attendanceRate = attendanceStats['attendanceRate'] as double;
      if (attendanceRate < 0.5) {
        // Less than 50% attendance
        return MemberStatus.inactive;
      }

      // If all rules pass, member is active
      return MemberStatus.active;
    } catch (e, stackTrace) {
      Logger.error('Failed to calculate member status', e, stackTrace);
      // Return current status if calculation fails
      return MemberStatus.values.firstWhere(
        (status) => status.toString().split('.').last == memberData['status'],
        orElse: () => MemberStatus.active,
      );
    }
  }

  Future<Map<String, dynamic>> _getAttendanceStatistics(
    String memberId,
    String choirId,
  ) async {
    try {
      // For now, use the member data that's already available
      // In a full implementation, this would query attendance records directly

      // Calculate attendance rate from member's existing statistics
      const totalAttendances = 0; // memberData['total_attendances'] ?? 0
      const totalAbsences = 0; // memberData['total_absences'] ?? 0
      const totalSessions = totalAttendances + totalAbsences;

      const attendanceRate = totalSessions > 0
          ? totalAttendances / totalSessions
          : 0.0;

      // Estimate monthly attendance based on overall statistics
      // This is a simplified calculation
      final estimatedMonthlyAttendances = (attendanceRate * 4)
          .round(); // Assuming 4 sessions per month

      return {
        'attendancesThisMonth': estimatedMonthlyAttendances,
        'totalSessionsThisMonth': 4, // Assumed
        'attendanceRate': attendanceRate,
      };
    } catch (e) {
      Logger.error('Failed to get attendance statistics', e);
      return {
        'attendancesThisMonth': 0,
        'totalSessionsThisMonth': 0,
        'attendanceRate': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _getPaymentStatistics(String memberId) async {
    try {
      final memberFees = await _feeService.getMemberFees(memberId);
      final outstandingAmount = memberFees.fold<double>(
        0,
        (sum, fee) => sum + fee.outstandingAmount,
      );
      final totalPaid = memberFees.fold<double>(
        0,
        (sum, fee) => sum + fee.amountPaid,
      );

      return {
        'outstandingFees': outstandingAmount,
        'totalPaid': totalPaid,
        'overdueFeesCount': memberFees.where((fee) => fee.isOverdue).length,
        'totalFeesCount': memberFees.length,
      };
    } catch (e) {
      Logger.error('Failed to get payment statistics', e);
      return {
        'outstandingFees': 0.0,
        'totalPaid': 0.0,
        'overdueFeesCount': 0,
        'totalFeesCount': 0,
      };
    }
  }

  DateTime? _getLastAttendance(Map<String, dynamic> memberData) {
    final lastAttendanceStr = memberData['last_attendance'];
    if (lastAttendanceStr != null) {
      return DateTime.tryParse(lastAttendanceStr);
    }
    return null;
  }

  Future<void> _notifyStatusChange(
    Map<String, dynamic> memberData,
    MemberStatus oldStatus,
    MemberStatus newStatus,
  ) async {
    try {
      Logger.info(
        'Member ${memberData['id']} status changed from $oldStatus to $newStatus',
      );

      final notificationService = NotificationService();
      final userId = memberData['user_id'] as String?;
      final choirId = memberData['choir_id'] as String?;
      final fullName = memberData['users']?['full_name'] ?? 'Member';

      if (userId != null && choirId != null) {
        // Send notification to the member about their status change
        final memberMessage = _getStatusChangeMessage(oldStatus, newStatus);
        await notificationService.createNotification(
          title: 'Membership Status Update',
          body: memberMessage,
          type: NotificationType.system,
          recipientId: userId,
          choirId: choirId,
          data: {
            'old_status': oldStatus.toString(),
            'new_status': newStatus.toString(),
            'member_id': memberData['id'],
          },
        );

        // Send notification to choir leaders about member status change
        await _notifyChoirLeaders(choirId, fullName, oldStatus, newStatus);

        // Log the status change for audit purposes
        await _logStatusChange(memberData['id'], oldStatus, newStatus);
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to send status change notification', e, stackTrace);
    }
  }

  String _getStatusChangeMessage(
    MemberStatus oldStatus,
    MemberStatus newStatus,
  ) {
    if (newStatus == MemberStatus.active) {
      return 'Your membership status has been updated to Active. Welcome back!';
    } else if (newStatus == MemberStatus.inactive) {
      return 'Your membership status has been updated to Inactive. Please contact your choir leader if you have questions.';
    } else {
      return 'Your membership status has been updated from ${oldStatus.toString().split('.').last} to ${newStatus.toString().split('.').last}.';
    }
  }

  Future<void> _notifyChoirLeaders(
    String choirId,
    String memberName,
    MemberStatus oldStatus,
    MemberStatus newStatus,
  ) async {
    try {
      final notificationService = NotificationService();

      // Get choir leaders (this would need to be implemented based on your choir leader structure)
      // For now, we'll assume there's a way to get choir leader IDs
      final choirLeaderIds = await _getChoirLeaderIds(choirId);

      if (choirLeaderIds.isNotEmpty) {
        await notificationService.createBulkNotifications(
          title: 'Member Status Update',
          body:
              '$memberName\'s status changed from ${oldStatus.toString().split('.').last} to ${newStatus.toString().split('.').last}',
          type: NotificationType.system,
          recipientIds: choirLeaderIds,
          choirId: choirId,
          data: {
            'member_name': memberName,
            'old_status': oldStatus.toString(),
            'new_status': newStatus.toString(),
          },
        );
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to notify choir leaders', e, stackTrace);
    }
  }

  Future<List<String>> _getChoirLeaderIds(String choirId) async {
    try {
      // This would typically query the database for choir leaders
      // For now, return empty list as a placeholder
      // In a real implementation, you would:
      // 1. Get the choir record
      // 2. Get the leader_id and admin_id from the choir
      // 3. Return both IDs
      return [];
    } catch (e) {
      Logger.error('Failed to get choir leader IDs', e);
      return [];
    }
  }

  Future<void> _logStatusChange(
    String memberId,
    MemberStatus oldStatus,
    MemberStatus newStatus,
  ) async {
    try {
      // Log the status change for audit purposes
      // This could be implemented as an audit log table
      Logger.info(
        'AUDIT: Member $memberId status changed from $oldStatus to $newStatus at ${DateTime.now()}',
      );

      // In a real implementation, you might:
      // 1. Insert into an audit_log table
      // 2. Track the timestamp, user who made the change, etc.
    } catch (e, stackTrace) {
      Logger.error('Failed to log status change', e, stackTrace);
    }
  }

  // Manual status check for a single member
  Future<MemberStatus> checkMemberStatus(
    String memberId,
    String choirId,
    Map<String, dynamic> memberData,
  ) async {
    try {
      return await _calculateMemberStatus(memberId, choirId, memberData);
    } catch (e, stackTrace) {
      Logger.error('Failed to check member status', e, stackTrace);
      rethrow;
    }
  }

  // Get automation rule summary
  Map<String, dynamic> getAutomationRules() {
    return {
      'minAttendancesPerMonth': minAttendancesPerMonth,
      'maxOutstandingFeesForActive': maxOutstandingFeesForActive,
      'maxAbsenceDaysForActive': maxAbsenceDaysForActive,
      'minAttendanceRate': 0.5,
      'description': {
        'attendanceRule':
            'Must attend at least $minAttendancesPerMonth sessions per month',
        'feeRule':
            'Outstanding fees must not exceed \$${maxOutstandingFeesForActive.toStringAsFixed(2)}',
        'absenceRule':
            'Must not be absent for more than $maxAbsenceDaysForActive consecutive days',
        'attendanceRateRule': 'Must maintain at least 50% attendance rate',
      },
    };
  }

  // Schedule automatic status updates (would typically be called by a cron job or scheduled task)
  Future<void> scheduleStatusUpdate(String choirId) async {
    // This would typically set up a recurring task
    // For now, we'll just run the update immediately
    await updateAllMemberStatuses(choirId);
  }
}
