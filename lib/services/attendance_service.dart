import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/logger.dart';

class AttendanceService {
  factory AttendanceService() => _instance;
  AttendanceService._internal();
  static final AttendanceService _instance = AttendanceService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// uuid columns reject placeholders like '', 'unknown' or 'current-user-id',
  /// so send null instead of failing the whole write.
  String? _uuidOrNull(String? value) =>
      value != null && _uuidPattern.hasMatch(value) ? value : null;
  static const String _attendanceKey = 'attendance_records';
  static const String _sessionsKey = 'attendance_sessions';

  Future<List<AttendanceModel>> getChoirAttendance(String choirId) async {
    try {
      // Try to load from Supabase database first
      final dbRecords = await _loadAttendanceFromDatabase(choirId);
      if (dbRecords.isNotEmpty) {
        Logger.debug('AttendanceService.getChoirAttendance - Loaded ${dbRecords.length} records from database');
        return dbRecords;
      }
    } catch (e) {
      Logger.error('AttendanceService.getChoirAttendance - Error loading from database', e);
      // Fall back to SharedPreferences
    }

    // Fall back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final attendanceJson = prefs.getString('${_attendanceKey}_$choirId');

    Logger.debug('AttendanceService.getChoirAttendance - Looking for key: ${_attendanceKey}_$choirId');

    if (attendanceJson == null) return [];

    final List<dynamic> attendanceData = jsonDecode(attendanceJson);
    final records = attendanceData.map((data) => AttendanceModel.fromJson(data)).toList();
    Logger.debug('AttendanceService.getChoirAttendance - Loaded ${records.length} attendance records');
    return records;
  }

  // Helper method to load attendance from Supabase database
  Future<List<AttendanceModel>> _loadAttendanceFromDatabase(String choirId) async {
    // First get sessions for the choir
    final sessionsResponse = await _supabase
        .from('attendance_sessions')
        .select('id')
        .eq('choir_id', choirId);

    if (sessionsResponse.isEmpty) {
      return [];
    }

    final sessionIds = sessionsResponse.map((s) => s['id']).toList();

    // Then get attendance records for those sessions
    final response = await _supabase
        .from('attendance_records')
        .select('''
          *,
          attendance_sessions!attendance_records_session_id_fkey (
            date,
            start_time,
            event_type,
            title
          )
        ''')
        .inFilter('session_id', sessionIds)
        .order('recorded_at', ascending: false);

    return response.map<AttendanceModel>((record) {
      final session = record['attendance_sessions'] as Map<String, dynamic>?;
      final eventDate = session != null
          ? DateTime.parse(session['date'] ?? DateTime.now().toIso8601String())
          : DateTime.now();

      return AttendanceModel(
        id: record['id'] ?? '',
        sessionId: record['session_id'] ?? '',
        memberId: record['member_id'] ?? '',
        userId: record['user_id'] ?? '',
        choirId: choirId,
        eventDate: eventDate,
        status: AttendanceStatus.values.firstWhere(
          (status) => status.toString().split('.').last == record['status'],
          orElse: () => AttendanceStatus.absent,
        ),
        recordedBy: record['recorded_by'] ?? '',
        recordedAt: DateTime.parse(record['recorded_at'] ?? DateTime.now().toIso8601String()),
        notes: record['notes'],
      );
    }).toList();
  }

  Future<List<AttendanceModel>> getAttendanceByDateRange({
    required String choirId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final allAttendance = await getChoirAttendance(choirId);

    return allAttendance.where((attendance) {
      final eventDate = attendance.eventDate;
      return eventDate.isAfter(fromDate.subtract(const Duration(days: 1))) &&
             eventDate.isBefore(toDate.add(const Duration(days: 1)));
    }).toList();
  }

  Future<String> recordAttendance(List<AttendanceModel> attendanceList) async {
    if (attendanceList.isEmpty) {
      Logger.warning('AttendanceService - Empty attendance list provided');
      return '';
    }

    final choirId = attendanceList.first.choirId;
    // Use the existing session ID from the first record, or generate a new one if not present
    final sessionId = attendanceList.first.sessionId.isNotEmpty
        ? attendanceList.first.sessionId
        : _uuid.v4();

    Logger.debug('AttendanceService - Recording ${attendanceList.length} records for session $sessionId in choir $choirId');

    var failedRecords = 0;
    try {
      // Save to Supabase database
      for (final attendance in attendanceList) {
        final attendanceRecord = {
          'id': attendance.id.isNotEmpty ? attendance.id : _uuid.v4(),
          'session_id': sessionId,
          'member_id': attendance.memberId,
          'user_id': _uuidOrNull(attendance.userId),
          'status': attendance.status.toString().split('.').last,
          'check_in_time': attendance.status == AttendanceStatus.present || attendance.status == AttendanceStatus.late
              ? attendance.recordedAt.toIso8601String()
              : null,
          'notes': attendance.notes,
          'recorded_at': attendance.recordedAt.toIso8601String(),
          'recorded_by': _uuidOrNull(attendance.recordedBy),
        };

        // Insert or update attendance record
        try {
          await _supabase
              .from('attendance_records')
              .upsert(attendanceRecord, onConflict: 'session_id,member_id');
        } catch (e) {
          // Keep going: one bad row must not drop the rest of the session.
          failedRecords++;
          Logger.error('AttendanceService - Error saving record for member ${attendance.memberId}', e);
        }
      }

      Logger.info('AttendanceService - Successfully saved ${attendanceList.length} records to database');

    } catch (e) {
      Logger.error('AttendanceService - Error saving to database', e);
      // Continue with SharedPreferences fallback
    }

    // Also save to SharedPreferences for backward compatibility
    final existingAttendance = await getChoirAttendance(choirId);
    Logger.debug('AttendanceService - Found ${existingAttendance.length} existing attendance records');

    // Remove any existing records for this session to avoid duplicates
    final beforeRemoval = existingAttendance.length;
    existingAttendance.removeWhere((existing) => existing.sessionId == sessionId);
    Logger.debug('AttendanceService - Removed ${beforeRemoval - existingAttendance.length} duplicate records for session $sessionId');

    // Ensure all records have the same session ID and unique individual IDs
    final updatedAttendance = attendanceList.map((a) =>
      a.copyWith(
        sessionId: sessionId,
        id: a.id.isNotEmpty ? a.id : _uuid.v4()
      )
    ).toList();

    existingAttendance.addAll(updatedAttendance);
    Logger.debug('AttendanceService - Total records after adding new ones: ${existingAttendance.length}');

    final prefs = await SharedPreferences.getInstance();
    final attendanceJson = jsonEncode(existingAttendance.map((a) => a.toJson()).toList());
    await prefs.setString('${_attendanceKey}_$choirId', attendanceJson);

    Logger.debug('AttendanceService - Successfully saved attendance data to SharedPreferences');

    // The local copy above keeps the data, but the caller must not be told the
    // save succeeded when the server rejected some of it.
    if (failedRecords > 0) {
      throw Exception(
        '$failedRecords of ${attendanceList.length} attendance records could not be saved to the server',
      );
    }
    return sessionId;
  }

  Future<bool> updateSessionAttendance(String choirId, String sessionId, List<AttendanceModel> updatedRecords) async {
    try {
      final existingAttendance = await getChoirAttendance(choirId);

      // Remove old records for this session
      final filteredAttendance = existingAttendance.where((a) => a.sessionId != sessionId).toList();

      // Add updated records
      filteredAttendance.addAll(updatedRecords);

      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = jsonEncode(filteredAttendance.map((a) => a.toJson()).toList());
      await prefs.setString('${_attendanceKey}_$choirId', attendanceJson);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAttendanceSession(String sessionId, String choirId) async {
    final attendance = await getChoirAttendance(choirId);
    final updatedAttendance = attendance.where((a) => a.sessionId != sessionId).toList();

    final prefs = await SharedPreferences.getInstance();
    final attendanceJson = jsonEncode(updatedAttendance.map((a) => a.toJson()).toList());
    await prefs.setString('${_attendanceKey}_$choirId', attendanceJson);

    return true;
  }

  // Clear all attendance data for a choir
  Future<bool> clearChoirAttendance(String choirId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_attendanceKey}_$choirId');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, double>> getAttendanceStats(String choirId) async {
    final attendance = await getChoirAttendance(choirId);

    if (attendance.isEmpty) {
      return {
        'overall_percentage': 0.0,
        'recent_percentage': 0.0,
        'total_sessions': 0.0,
        'present_count': 0.0,
        'late_count': 0.0,
        'absent_count': 0.0,
        'late_percentage': 0.0,
        'absent_percentage': 0.0,
      };
    }

    final totalRecords = attendance.length;
    final presentRecords = attendance.where((a) => a.status == AttendanceStatus.present).length;
    final lateRecords = attendance.where((a) => a.status == AttendanceStatus.late).length;
    final absentRecords = attendance.where((a) => a.status == AttendanceStatus.absent).length;

    // Recent attendance (last 30 days)
    final recentDate = DateTime.now().subtract(const Duration(days: 30));
    final recentAttendance = attendance.where((a) => a.eventDate.isAfter(recentDate)).toList();
    final recentPresent = recentAttendance.where((a) => a.status == AttendanceStatus.present).length;

    // Get unique session count
    final uniqueSessions = attendance.map((a) => a.sessionId).toSet().length;

    return {
      'overall_percentage': totalRecords > 0 ? (presentRecords / totalRecords) * 100 : 0.0,
      'recent_percentage': recentAttendance.isNotEmpty ? (recentPresent / recentAttendance.length) * 100 : 0.0,
      'total_sessions': uniqueSessions.toDouble(),
      'present_count': presentRecords.toDouble(),
      'late_count': lateRecords.toDouble(),
      'absent_count': absentRecords.toDouble(),
      'late_percentage': totalRecords > 0 ? (lateRecords / totalRecords) * 100 : 0.0,
      'absent_percentage': totalRecords > 0 ? (absentRecords / totalRecords) * 100 : 0.0,
    };
  }

  // Session Management
  //
  // Sessions are read from Supabase first so they are the same on every device
  // and browser; SharedPreferences is a cache and an offline fallback. Newest
  // first, so callers can treat `.first` as the latest session.
  Future<List<AttendanceSessionModel>> getSessions(String choirId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${_sessionsKey}_$choirId';

    try {
      final rows = await _supabase
          .from('attendance_sessions')
          .select()
          .eq('choir_id', choirId)
          .order('created_at', ascending: false);

      if (rows.isNotEmpty) {
        final sessions = rows.map<AttendanceSessionModel>(_sessionFromRow).toList();
        await prefs.setString(
          cacheKey,
          jsonEncode(sessions.map((s) => s.toJson()).toList()),
        );
        Logger.debug('AttendanceService.getSessions - Loaded ${sessions.length} sessions from database');
        return sessions;
      }
    } catch (e) {
      Logger.error('AttendanceService.getSessions - Error loading from database', e);
    }

    final sessionsJson = prefs.getString(cacheKey);
    if (sessionsJson == null) return [];

    final List<dynamic> sessionsData = jsonDecode(sessionsJson);
    final sessions = sessionsData
        .map((data) => AttendanceSessionModel.fromJson(data))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    Logger.debug('AttendanceService.getSessions - Loaded ${sessions.length} sessions from local cache');
    return sessions;
  }

  AttendanceSessionModel _sessionFromRow(Map<String, dynamic> row) {
    return AttendanceSessionModel(
      id: row['id'] ?? '',
      choirId: row['choir_id'] ?? '',
      leaderId: row['leader_id'] ?? '',
      date: DateTime.tryParse(row['date'] ?? '') ?? DateTime.now(),
      startTime: DateTime.tryParse(row['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(row['end_time'] ?? ''),
      eventType: EventType.values.firstWhere(
        (type) => type.toString().split('.').last == row['event_type'],
        orElse: () => EventType.other,
      ),
      title: row['title'] ?? '',
      description: row['description'],
      graceMinutes: row['grace_minutes'] ?? 15,
      isActive: row['is_active'] ?? true,
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Future<AttendanceSessionModel> createSession({
    required String choirId,
    required String leaderId,
    required DateTime date,
    required DateTime startTime,
    required EventType eventType,
    required String title,
    String? description,
    int graceMinutes = 15,
  }) async {
    final session = AttendanceSessionModel(
      id: _uuid.v4(),
      choirId: choirId,
      leaderId: leaderId,
      date: date,
      startTime: startTime,
      eventType: eventType,
      title: title,
      description: description,
      graceMinutes: graceMinutes,
      createdAt: DateTime.now(),
    );

    try {
      // Save to Supabase database
      final sessionRecord = {
        'id': session.id,
        'choir_id': session.choirId,
        'leader_id': _uuidOrNull(session.leaderId),
        'date': session.date.toIso8601String().split('T')[0], // Date only
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime?.toIso8601String(),
        'event_type': session.eventType.toString().split('.').last,
        'title': session.title,
        'description': session.description,
        'grace_minutes': session.graceMinutes,
        'is_active': session.isActive,
        'created_at': session.createdAt.toIso8601String(),
      };

      await _supabase
          .from('attendance_sessions')
          .upsert(sessionRecord);

      Logger.info('AttendanceService.createSession - Successfully saved session to database');

    } catch (e) {
      Logger.error('AttendanceService.createSession - Error saving session to database', e);
      // Continue with SharedPreferences fallback
    }

    // Also save to SharedPreferences for backward compatibility
    // getSessions already includes the session if the database save worked.
    final sessions = await getSessions(choirId);
    if (!sessions.any((s) => s.id == session.id)) {
      sessions.insert(0, session);
    }

    Logger.debug('AttendanceService.createSession - Creating session ${session.id} for choir $choirId');
    Logger.debug('AttendanceService.createSession - Total sessions after adding: ${sessions.length}');

    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString('${_sessionsKey}_$choirId', sessionsJson);

    Logger.debug('AttendanceService.createSession - Successfully saved ${sessions.length} sessions to key: ${_sessionsKey}_$choirId');
    return session;
  }

  Future<List<AttendanceRecordModel>> getSessionAttendance(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString('attendance_records_$sessionId');

    if (recordsJson == null) {
      return [];
    }

    final List<dynamic> recordsData = jsonDecode(recordsJson);
    return recordsData.map((data) => AttendanceRecordModel.fromJson(data)).toList();
  }

  Future<bool> saveSessionAttendance(String sessionId, List<AttendanceRecordModel> records) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString('attendance_records_$sessionId', recordsJson);
    return true;
  }

  Future<Map<String, int>> getAttendanceCountsBySession(String sessionId) async {
    final records = await getSessionAttendance(sessionId);

    final present = records.where((r) => r.status == AttendanceStatus.present).length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;
    final absent = records.where((r) => r.status == AttendanceStatus.absent).length;

    return {
      'present': present,
      'late': late,
      'absent': absent,
      'total': records.length,
    };
  }

  Future<List<AttendanceModel>> getAttendanceHistory({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
    AttendanceStatus? statusFilter,
    String? memberFilter,
  }) async {
    var attendance = await getChoirAttendance(choirId);

    // Apply filters
    if (fromDate != null) {
      attendance = attendance.where((a) =>
        a.eventDate.isAfter(fromDate.subtract(const Duration(days: 1)))
      ).toList();
    }

    if (toDate != null) {
      attendance = attendance.where((a) =>
        a.eventDate.isBefore(toDate.add(const Duration(days: 1)))
      ).toList();
    }

    if (statusFilter != null) {
      attendance = attendance.where((a) => a.status == statusFilter).toList();
    }

    if (memberFilter != null && memberFilter.isNotEmpty) {
      attendance = attendance.where((a) =>
        a.userId.toLowerCase().contains(memberFilter.toLowerCase()) ||
        a.memberId.toLowerCase().contains(memberFilter.toLowerCase())
      ).toList();
    }

    // Sort by date (most recent first)
    attendance.sort((a, b) => b.eventDate.compareTo(a.eventDate));

    return attendance;
  }

  Future<void> clearAllAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) =>
      key.startsWith(_attendanceKey) || key.startsWith(_sessionsKey)
    );

    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // Debug method to inspect SharedPreferences
  Future<void> debugSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    Logger.debug('=== SharedPreferences Debug ===');
    Logger.debug('Total keys: ${allKeys.length}');

    for (final key in allKeys) {
      if (key.startsWith(_attendanceKey) || key.startsWith(_sessionsKey) || key.contains('selected_choir')) {
        final value = prefs.getString(key);
        Logger.debug('Key: $key');
        Logger.debug('Value length: ${value?.length ?? 0}');
        if (value != null && value.length < 500) {
          Logger.debug('Value: $value');
        }
        Logger.debug('---');
      }
    }
    Logger.debug('=== End SharedPreferences Debug ===');
  }
}
