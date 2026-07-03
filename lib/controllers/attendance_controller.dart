import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/attendance_service.dart';
import '../services/attendance_time_service.dart';
import '../services/member_service.dart';
import '../utils/logger.dart';

class AttendanceController extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  final AttendanceTimeService _timeService = AttendanceTimeService();

  List<AttendanceModel> _attendanceRecords = [];
  List<AttendanceSessionModel> _sessions = [];
  List<AttendanceRecordModel> _currentSessionRecords = [];
  AttendanceSessionModel? _currentSession;
  String? _activeChoirId;
  Map<String, double> _attendanceStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  List<AttendanceSessionModel> get sessions => _sessions;
  List<AttendanceRecordModel> get currentSessionRecords => _currentSessionRecords;
  AttendanceSessionModel? get currentSession => _currentSession;
  AttendanceSessionModel? get activeSession => _sessions.isNotEmpty ? _sessions.firstWhere((s) => s.isActive, orElse: () => _sessions.first) : null;
  String? get activeChoirId => _activeChoirId;
  Map<String, double> get attendanceStats => _attendanceStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load attendance records for a choir
  Future<void> loadChoirAttendance(String choirId) async {
    try {
      _setLoading(true);
      _clearError();
      _activeChoirId = choirId;
      
      _attendanceRecords = await _attendanceService.getChoirAttendance(choirId);
      _attendanceStats = await _attendanceService.getAttendanceStats(choirId);
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load attendance records: $e');
      _setLoading(false);
    }
  }

  // Record attendance for multiple members (original batch method)
  Future<bool> recordAttendanceBatch(List<AttendanceModel> attendanceList) async {
    try {
      _setLoading(true);
      _clearError();

      final sessionId = await _attendanceService.recordAttendance(attendanceList);
      
      if (sessionId.isNotEmpty) {
        // Reload attendance data from storage to get the actual saved records
        if (attendanceList.isNotEmpty) {
          final choirId = attendanceList.first.choirId;
          await loadChoirAttendance(choirId);
        }
        
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to record attendance');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error recording attendance: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete attendance session
  Future<bool> deleteAttendanceSession(String sessionId, String choirId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _attendanceService.deleteAttendanceSession(sessionId, choirId);
      
      if (success) {
        // Remove records with this session ID from local list
        _attendanceRecords.removeWhere((record) => record.sessionId == sessionId);
        
        // Refresh stats
        _attendanceStats = await _attendanceService.getAttendanceStats(choirId);
        
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to delete attendance session');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error deleting attendance session: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get attendance records for a specific member
  List<AttendanceModel> getMemberAttendance(String memberId) {
    return _attendanceRecords.where((record) => record.memberId == memberId).toList();
  }

  // Get attendance records by date range
  List<AttendanceModel> getAttendanceByDateRange(DateTime startDate, DateTime endDate) {
    return _attendanceRecords.where((record) {
      return record.eventDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             record.eventDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Calculate overall attendance rate
  double getOverallAttendanceRate() {
    if (_attendanceRecords.isEmpty) return 0.0;
    
    final presentCount = _attendanceRecords.where(
      (record) => record.status == AttendanceStatus.present || record.status == AttendanceStatus.late
    ).length;
    
    return (presentCount / _attendanceRecords.length) * 100;
  }

  // Get unique session IDs
  List<String> getSessionIds() {
    return _attendanceRecords.map((record) => record.sessionId).toSet().toList();
  }

  // Clear all attendance data
  Future<void> clearAllAttendance() async {
    try {
      _setLoading(true);
      _clearError();

      await _attendanceService.clearAllAttendance();
      
      _attendanceRecords.clear();
      _sessions.clear();
      _currentSessionRecords.clear();
      _currentSession = null;
      _attendanceStats.clear();
      _activeChoirId = null;
      
      _setLoading(false);
    } catch (e) {
      _setError('Error clearing attendance data: $e');
      _setLoading(false);
    }
  }

  // Clear local data
  void clearData() {
    _attendanceRecords.clear();
    _sessions.clear();
    _currentSessionRecords.clear();
    _currentSession = null;
    _attendanceStats.clear();
    _activeChoirId = null;
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Generate attendance report data
  Future<Map<String, dynamic>?> generateAttendanceReportData({
    required String choirId,
    required DateTime fromDate,
    required DateTime toDate,
    String filter = 'All Members',
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Get all choir members first
      final memberService = MemberService();
      final allMembers = await memberService.getChoirMembersWithUserInfo(choirId);
      
      // Remove duplicate members based on registration number or user ID
      final uniqueMembers = <String, Map<String, dynamic>>{};
      for (final member in allMembers) {
        final memberId = member['id'].toString();
        final regNumber = member['registration_number']?.toString() ?? '';
        final userId = member['user_id']?.toString() ?? '';
        
        // Use registration number as primary key, fallback to user_id, then member_id
        final uniqueKey = regNumber.isNotEmpty ? regNumber : (userId.isNotEmpty ? userId : memberId);
        
        if (!uniqueMembers.containsKey(uniqueKey)) {
          uniqueMembers[uniqueKey] = member;
        } else {
          Logger.debug('Skipping duplicate member: $uniqueKey - ${member['users']?['full_name']}');
        }
      }
      
      final deduplicatedMembers = uniqueMembers.values.toList();
      final totalMembers = deduplicatedMembers.length;
      
      Logger.debug('Original choir members: ${allMembers.length}, After deduplication: $totalMembers');

      // Get attendance records for the date range
      final attendanceRecords = await _attendanceService.getAttendanceByDateRange(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      Logger.debug('Attendance records found: ${attendanceRecords.length}');

      if (attendanceRecords.isEmpty && deduplicatedMembers.isEmpty) {
        // Return empty report data if no members and no attendance
        return {
          'summary': {
            'total_sessions': 0,
            'total_members': 0,
            'avg_attendance_rate': 0.0,
          },
          'member_attendance': {},
        };
      }

      // Get all sessions in the date range from session data, not just attendance records
      final allSessions = await _attendanceService.getSessions(choirId);
      final sessionsInRange = allSessions.where((session) {
        return session.date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
               session.date.isBefore(toDate.add(const Duration(days: 1)));
      }).toList();
      final totalSessions = sessionsInRange.length;
      
      Logger.debug('Total sessions in date range: $totalSessions');
      Logger.debug('Sessions: ${sessionsInRange.map((s) => '${s.title} (${s.date})').join(', ')}');

      // Initialize attendance data for ALL choir members
      final memberAttendance = <String, Map<String, dynamic>>{};
      final memberRecords = <String, List<AttendanceModel>>{};

      // Create entries for all choir members (including those with no attendance records)
      for (final member in deduplicatedMembers) {
        final memberId = member['id'].toString();
        Logger.debug('Processing member: $memberId - ${member['users']?['full_name']}');
        
        // Check for duplicate member IDs
        if (memberAttendance.containsKey(memberId)) {
          Logger.warning('Duplicate member ID found: $memberId');
          continue; // Skip duplicates
        }
        
        memberAttendance[memberId] = {
          'member_data': member,
          'total_sessions': totalSessions, // This is the total sessions available
          'sessions_attended': 0, // This is the sessions this member actually attended
          'present': 0,
          'late': 0,
          'absent': 0,
          'attendance_rate': 0.0,
        };
        memberRecords[memberId] = [];
      }

      // Group attendance records by member
      for (final record in attendanceRecords) {
        final memberId = record.memberId;
        Logger.debug('Processing attendance record for member: $memberId');
        
        // Only add records for members that exist in the choir
        if (memberRecords.containsKey(memberId)) {
          memberRecords[memberId]!.add(record);
        } else {
          Logger.warning('Attendance record for unknown member: $memberId');
        }
      }

      // Calculate attendance stats for each member
      for (final memberId in memberAttendance.keys) {
        final records = memberRecords[memberId]!;
        final sessionRecords = <String, AttendanceModel>{};
        
        // Get the latest record for each session (in case of duplicates)
        for (final record in records) {
          sessionRecords[record.sessionId] = record;
        }
        
        // Count attendance statuses
        for (final record in sessionRecords.values) {
          switch (record.status) {
            case AttendanceStatus.present:
              memberAttendance[memberId]!['present'] = (memberAttendance[memberId]!['present'] as int) + 1;
              break;
            case AttendanceStatus.late:
              memberAttendance[memberId]!['late'] = (memberAttendance[memberId]!['late'] as int) + 1;
              break;
            case AttendanceStatus.absent:
              memberAttendance[memberId]!['absent'] = (memberAttendance[memberId]!['absent'] as int) + 1;
              break;
          }
        }
        
        // Calculate sessions attended: sessions with ANY attendance record (present/late/absent)
        final sessionsWithRecords = sessionRecords.length;
        memberAttendance[memberId]!['sessions_attended'] = sessionsWithRecords;
        
        // Calculate total absent sessions:
        // Sessions with no record + sessions explicitly marked as absent
        final explicitAbsentCount = memberAttendance[memberId]!['absent'] as int;
        final sessionsWithNoRecord = totalSessions - sessionsWithRecords;
        memberAttendance[memberId]!['absent'] = explicitAbsentCount + sessionsWithNoRecord;
      }

      // Calculate attendance rates
      for (final member in memberAttendance.values) {
        final present = member['present'] as int;
        final late = member['late'] as int;
        final total = member['total_sessions'] as int;
        
        if (total > 0) {
          member['attendance_rate'] = ((present + late) / total) * 100;
        }
      }

      // Apply filters
      if (filter == 'Active Only') {
        memberAttendance.removeWhere((memberId, data) {
          final memberData = data['member_data'] as Map<String, dynamic>? ?? {};
          return memberData['status'] != 'active';
        });
      } else if (filter == 'With Low Attendance') {
        memberAttendance.removeWhere((memberId, data) {
          return (data['attendance_rate'] as double) >= 75.0;
        });
      }

      // Calculate summary statistics  
      double avgAttendanceRate = 0.0;
      
      if (memberAttendance.isNotEmpty) {
        final totalRate = memberAttendance.values
            .map((m) => m['attendance_rate'] as double)
            .reduce((a, b) => a + b);
        avgAttendanceRate = totalRate / memberAttendance.length;
      }

      final reportData = {
        'member_attendance': memberAttendance,
        'summary': {
          'total_sessions': totalSessions,
          'avg_attendance_rate': avgAttendanceRate,
          'total_members': totalMembers, // Use actual total members from choir
          'date_range': {
            'from': fromDate.toIso8601String(),
            'to': toDate.toIso8601String(),
          },
        },
      };

      Logger.debug('Final report summary - total_sessions: $totalSessions, total_members: $totalMembers');
      Logger.debug('Member attendance entries: ${memberAttendance.length}');

      _setLoading(false);
      return reportData;
    } catch (e) {
      _setError('Error generating attendance report: $e');
      _setLoading(false);
      return null;
    }
  }

  // Load attendance sessions for a choir
  Future<void> loadAttendanceSessions({required String choirId}) async {
    try {
      _setLoading(true);
      _clearError();
      _activeChoirId = choirId;

      Logger.debug('Loading attendance sessions for choir $choirId');
      
      // Debug: Inspect what's in SharedPreferences
      await _attendanceService.debugSharedPreferences();
      
      // First, try to load actual saved sessions from SharedPreferences
      _sessions = await _attendanceService.getSessions(choirId);
      Logger.debug('Loaded ${_sessions.length} saved sessions from SharedPreferences');
      
      // If no saved sessions exist, create sessions from existing attendance records as fallback
      if (_sessions.isEmpty) {
        Logger.debug('No saved sessions found, creating sessions from attendance records');
        final attendanceRecords = await _attendanceService.getChoirAttendance(choirId);
        final sessionIds = attendanceRecords.map((r) => r.sessionId).toSet().toList();
        
        if (sessionIds.isNotEmpty) {
          _sessions = sessionIds.map((sessionId) {
            final sessionRecords = attendanceRecords.where((r) => r.sessionId == sessionId).toList();
            final firstRecord = sessionRecords.first;
            
            return AttendanceSessionModel(
              id: sessionId,
              choirId: choirId,
              leaderId: firstRecord.recordedBy,
              date: firstRecord.eventDate,
              startTime: firstRecord.eventDate,
              endTime: null,
              eventType: EventType.service,
              title: firstRecord.notes ?? 'Attendance Session',
              description: 'Generated session from attendance records',
              graceMinutes: 15,
              isActive: false, // Mark as inactive since these are reconstructed
              createdAt: firstRecord.recordedAt,
            );
          }).toList();
          Logger.debug('Created ${_sessions.length} sessions from attendance records');
        } else {
          Logger.debug('No attendance records found, sessions list remains empty');
        }
      }

      // Sort by date descending
      _sessions.sort((a, b) => b.date.compareTo(a.date));
      
      // Load attendance records and stats
      await loadChoirAttendance(choirId);
      
      Logger.debug('Session loading completed. Total sessions: ${_sessions.length}');
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load attendance sessions: $e');
      Logger.error('Error loading sessions: $e');
      _setLoading(false);
    }
  }

  // Select a session and load its records
  Future<void> selectSession(AttendanceSessionModel session) async {
    try {
      _setLoading(true);
      _clearError();
      _currentSession = session;

      // Get all attendance records for this session
      final allRecords = await _attendanceService.getChoirAttendance(session.choirId);
      final sessionAttendance = allRecords.where((r) => r.sessionId == session.id).toList();
      
      // Convert to AttendanceRecordModel format
      _currentSessionRecords = sessionAttendance.map((attendance) {
        return AttendanceRecordModel(
          id: attendance.id,
          sessionId: attendance.sessionId,
          memberId: attendance.memberId,
          userId: attendance.userId,
          status: attendance.status,
          checkInTime: attendance.eventDate,
          notes: attendance.notes,
          recordedAt: attendance.recordedAt,
          recordedBy: attendance.recordedBy,
        );
      }).toList();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to select session: $e');
      _setLoading(false);
    }
  }

  // Get attendance record for a specific member in the current session
  AttendanceRecordModel? getAttendanceRecord(String memberId) {
    try {
      return _currentSessionRecords.firstWhere(
        (record) => record.memberId == memberId,
      );
    } catch (e) {
      return null;
    }
  }

  // End an attendance session
  Future<bool> endAttendanceSession(String sessionId) async {
    try {
      _setLoading(true);
      _clearError();

      // Find the session in our list and mark it as inactive
      final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex != -1) {
        _sessions[sessionIndex] = AttendanceSessionModel(
          id: _sessions[sessionIndex].id,
          choirId: _sessions[sessionIndex].choirId,
          leaderId: _sessions[sessionIndex].leaderId,
          date: _sessions[sessionIndex].date,
          startTime: _sessions[sessionIndex].startTime,
          endTime: DateTime.now(),
          eventType: _sessions[sessionIndex].eventType,
          title: _sessions[sessionIndex].title,
          description: _sessions[sessionIndex].description,
          graceMinutes: _sessions[sessionIndex].graceMinutes,
          isActive: false,
          createdAt: _sessions[sessionIndex].createdAt,
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to end session: $e');
      _setLoading(false);
      return false;
    }
  }

  // Create a new attendance session
  Future<bool> createAttendanceSession({
    required String choirId,
    required String title,
    required EventType eventType,
    String? leaderId,
    DateTime? date,
    DateTime? startTime,
    String? description,
    int graceMinutes = 15,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final now = DateTime.now();
      
      // Create session using the service to save it persistently
      final newSession = await _attendanceService.createSession(
        choirId: choirId,
        leaderId: leaderId ?? 'current-user-id',
        date: date ?? now,
        startTime: startTime ?? now,
        eventType: eventType,
        title: title,
        description: description,
        graceMinutes: graceMinutes,
      );

      // Add to local sessions list
      _sessions.insert(0, newSession);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create session: $e');
      _setLoading(false);
      return false;
    }
  }

  // Bulk record attendance for all members
  Future<bool> bulkRecordAttendance({
    required String sessionId,
    required AttendanceStatus status,
    required List<String> memberIds,
    required String recordedBy,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final now = DateTime.now();
      
      for (int i = 0; i < memberIds.length; i++) {
        final memberId = memberIds[i];
        final existingRecordIndex = _currentSessionRecords.indexWhere(
          (r) => r.memberId == memberId && r.sessionId == sessionId
        );

        // Generate unique ID by adding index to avoid duplicates when processing multiple records at once
        final recordId = existingRecordIndex != -1 
          ? _currentSessionRecords[existingRecordIndex].id
          : '${sessionId}_${memberId}_${now.millisecondsSinceEpoch}_$i';

        final record = AttendanceRecordModel(
          id: recordId,
          sessionId: sessionId,
          memberId: memberId,
          userId: memberId, // Assuming member ID equals user ID
          status: status,
          checkInTime: now,
          recordedAt: now,
          recordedBy: recordedBy,
        );

        if (existingRecordIndex != -1) {
          _currentSessionRecords[existingRecordIndex] = record;
        } else {
          _currentSessionRecords.add(record);
        }
      }

      await _syncWithMainRecords();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to bulk record attendance: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get session attendance rate
  double getSessionAttendanceRate(String sessionId) {
    final sessionRecords = _currentSessionRecords.where((r) => r.sessionId == sessionId).toList();
    if (sessionRecords.isEmpty) return 0.0;
    
    final presentCount = sessionRecords.where((r) => r.status == AttendanceStatus.present).length;
    return (presentCount / sessionRecords.length) * 100;
  }

  // Record a single attendance (with named parameters for UI compatibility)
  Future<bool> recordAttendance({
    required String sessionId,
    required String memberId,
    required String userId,
    AttendanceStatus? status,
    required String recordedBy,
    DateTime? checkInTime,
    String? notes,
    bool useTimeBasedStatus = true,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final now = DateTime.now();
      final actualCheckInTime = checkInTime ?? now;
      
      // Get session for time-based calculations
      final session = _sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => _sessions.isNotEmpty ? _sessions.first : _createDefaultSession(),
      );

      // Determine status based on time if not explicitly provided and useTimeBasedStatus is true
      AttendanceStatus finalStatus = status ?? AttendanceStatus.present;
      
      if (useTimeBasedStatus && status == null) {
        finalStatus = _timeService.determineAttendanceStatus(
          checkInTime: actualCheckInTime,
          sessionStartTime: session.startTime,
          graceMinutes: session.graceMinutes,
        );
      }

      // Check if record already exists for this member in this session
      final existingRecordIndex = _currentSessionRecords.indexWhere(
        (r) => r.memberId == memberId && r.sessionId == sessionId
      );

      // Generate unique ID using UUID-style approach for single records
      final recordId = existingRecordIndex != -1 
        ? _currentSessionRecords[existingRecordIndex].id
        : '${sessionId}_${memberId}_${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch.toString().substring(10)}';

      final record = AttendanceRecordModel(
        id: recordId,
        sessionId: sessionId,
        memberId: memberId,
        userId: userId,
        status: finalStatus,
        checkInTime: actualCheckInTime,
        recordedAt: now,
        recordedBy: recordedBy,
        notes: notes ?? _generateTimeBasedNote(finalStatus, actualCheckInTime, session.startTime),
      );

      // Update or add to current session records
      if (existingRecordIndex != -1) {
        _currentSessionRecords[existingRecordIndex] = record;
      } else {
        _currentSessionRecords.add(record);
      }
      
      // Sync with main records
      await _syncWithMainRecords();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to record attendance: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update attendance record (overload for UI compatibility)
  Future<bool> updateAttendanceRecord({
    required String recordId,
    String? sessionId,
    AttendanceStatus? status,
    DateTime? checkInTime,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Find and update the record
      final recordIndex = _currentSessionRecords.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        _currentSessionRecords[recordIndex] = _currentSessionRecords[recordIndex].copyWith(
          status: status,
          checkInTime: checkInTime,
          notes: notes,
          recordedAt: DateTime.now(),
        );
        
        // Also update in the main attendance records
        await _syncWithMainRecords();
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update attendance record: $e');
      _setLoading(false);
      return false;
    }
  }

  // Helper method to sync session records with main attendance records
  Future<void> _syncWithMainRecords() async {
    if (_currentSession == null) return;

    // Deduplicate records by member ID before syncing
    final uniqueRecords = <String, AttendanceRecordModel>{};
    for (final record in _currentSessionRecords) {
      uniqueRecords[record.memberId] = record;
    }
    _currentSessionRecords = uniqueRecords.values.toList();

    // Convert current session records back to AttendanceModel format
    final attendanceRecords = _currentSessionRecords.map((record) {
      return AttendanceModel(
        id: record.id,
        sessionId: record.sessionId,
        memberId: record.memberId,
        userId: record.userId,
        choirId: _currentSession!.choirId,
        eventDate: record.checkInTime ?? DateTime.now(),
        status: record.status,
        recordedBy: record.recordedBy,
        recordedAt: record.recordedAt,
        notes: record.notes,
      );
    }).toList();

    // Update the service using the new update method
    await _attendanceService.updateSessionAttendance(
      _currentSession!.choirId,
      _currentSession!.id,
      attendanceRecords,
    );
  }

  // Helper methods
  AttendanceSessionModel _createDefaultSession() {
    return AttendanceSessionModel(
      id: 'default',
      choirId: 'default',
      leaderId: 'system',
      title: 'Default Session',
      date: DateTime.now(),
      startTime: DateTime.now(),
      eventType: EventType.rehearsal,
      graceMinutes: 15,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  String _generateTimeBasedNote(AttendanceStatus status, DateTime checkInTime, DateTime sessionStartTime) {
    final timeDifference = checkInTime.difference(sessionStartTime);
    
    switch (status) {
      case AttendanceStatus.present:
        if (timeDifference.inMinutes <= 0) {
          return 'Checked in on time';
        } else {
          return 'Checked in ${timeDifference.inMinutes}min after start (within grace period)';
        }
      case AttendanceStatus.late:
        return 'Checked in ${timeDifference.inMinutes}min late';
      case AttendanceStatus.absent:
        return 'No check-in recorded';
    }
  }

  // Time-based utility methods
  Map<String, dynamic> getSessionTimingInfo(String sessionId) {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => _createDefaultSession(),
    );

    return _timeService.getSessionTimingInfo(
      sessionStartTime: session.startTime,
      graceMinutes: session.graceMinutes,
    );
  }

  bool shouldAutoCloseSession(String sessionId) {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => _createDefaultSession(),
    );

    return _timeService.shouldAutoCloseSession(
      sessionStartTime: session.startTime,
      graceMinutes: session.graceMinutes,
    );
  }

  Duration getTimeUntilAutoClose(String sessionId) {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => _createDefaultSession(),
    );

    return _timeService.getTimeUntilAutoClose(
      sessionStartTime: session.startTime,
      graceMinutes: session.graceMinutes,
    );
  }
}