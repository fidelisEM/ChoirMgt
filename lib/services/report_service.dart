import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class ReportService {
  factory ReportService() => _instance;
  ReportService._internal();
  static final ReportService _instance = ReportService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Generate membership report
  Future<Map<String, dynamic>> generateMembershipReport({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
    String? membershipFilter,
  }) async {
    try {
      // Get members data with optional status filter
      var membersQuery = _supabase
          .from('choir_members')
          .select('''
            *,
            users!choir_members_user_id_fkey (
              id,
              full_name,
              email,
              phone_number
            )
          ''')
          .eq('choir_id', choirId);
      
      // Apply membership filter if specified
      if (membershipFilter != null && membershipFilter != 'all') {
        membersQuery = membersQuery.eq('status', membershipFilter);
      }

      final membersResponse = await membersQuery;
      final members = List<Map<String, dynamic>>.from(membersResponse);

      // Calculate statistics
      final totalMembers = members.length;
      final activeMembers = members.where((m) => m['status'] == 'active').length;
      final inactiveMembers = members.where((m) => m['status'] == 'inactive').length;
      final suspendedMembers = members.where((m) => m['status'] == 'suspended').length;

      final totalFees = members.fold<double>(
        0, (sum, m) => sum + (m['outstanding_fees'] ?? 0.0)
      );
      final totalPaid = members.fold<double>(
        0, (sum, m) => sum + (m['total_paid'] ?? 0.0)
      );

      // Group by join date (monthly)
      final membersByMonth = <String, int>{};
      for (final member in members) {
        final joinDate = DateTime.parse(member['join_date']);
        final monthKey = '${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}';
        membersByMonth[monthKey] = (membersByMonth[monthKey] ?? 0) + 1;
      }

      return {
        'report_type': 'membership',
        'choir_id': choirId,
        'generated_at': DateTime.now().toIso8601String(),
        'period_from': fromDate?.toIso8601String(),
        'period_to': toDate?.toIso8601String(),
        'summary': {
          'total_members': totalMembers,
          'active_members': activeMembers,
          'inactive_members': inactiveMembers,
          'suspended_members': suspendedMembers,
          'total_outstanding': totalFees,
          'total_paid': totalPaid,
          'collection_rate': totalFees > 0 ? (totalPaid / (totalPaid + totalFees)) * 100 : 0,
        },
        'growth_data': membersByMonth,
        'members': members,
      };
    } catch (e) {
      Logger.error('Error generating membership report', e);
      return {};
    }
  }

  // Generate attendance report
  Future<Map<String, dynamic>> generateAttendanceReport({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Get attendance sessions
      Logger.debug('About to query attendance_sessions for choir_id: $choirId');

      // First try to get ANY attendance sessions to test connection
      final allSessions = await _supabase
          .from('attendance_sessions')
          .select();
      Logger.debug('Total attendance sessions in database: ${allSessions.length}');

      final sessionsQuery = _supabase
          .from('attendance_sessions')
          .select()
          .eq('choir_id', choirId);

      final sessions = await sessionsQuery.order('date', ascending: false);

      // Debug: log what we're finding
      Logger.debug('Choir ID: $choirId');
      Logger.debug('Found ${sessions.length} sessions');
      if (sessions.isNotEmpty) {
        Logger.debug('First session: ${sessions[0]}');
      }

      // Get attendance records for these sessions
      
      final Map<String, List<Map<String, dynamic>>> recordsBySession = {};
      double totalAttendanceRate = 0.0;
      final int totalSessions = sessions.length;

      for (final session in sessions) {
        final records = await _supabase
            .from('attendance_records')
            .select('''
              *,
              choir_members!attendance_records_member_id_fkey (
                registration_number,
                users!choir_members_user_id_fkey (
                  id,
                  full_name
                )
              )
            ''')
            .eq('session_id', session['id']);

        recordsBySession[session['id']] = List<Map<String, dynamic>>.from(records);

        // Calculate attendance rate for this session
        if (records.isNotEmpty) {
          final presentCount = records.where(
            (r) => r['status'] == 'present' || r['status'] == 'late'
          ).length;
          final sessionRate = (presentCount / records.length) * 100;
          totalAttendanceRate += sessionRate;
        }
      }

      final avgAttendanceRate = totalSessions > 0 ? totalAttendanceRate / totalSessions : 0.0;

      // Member attendance summary
      final memberAttendance = <String, Map<String, dynamic>>{};
      
      for (final session in sessions) {
        final records = recordsBySession[session['id']] ?? [];
        for (final record in records) {
          final memberId = record['member_id'];
          final memberData = record['choir_members'];
          
          if (memberAttendance.containsKey(memberId)) {
            memberAttendance[memberId]!['total_sessions'] += 1;
            if (record['status'] == 'present') {
              memberAttendance[memberId]!['present'] += 1;
            } else if (record['status'] == 'late') {
              memberAttendance[memberId]!['late'] += 1;
            } else {
              memberAttendance[memberId]!['absent'] += 1;
            }
          } else {
            memberAttendance[memberId] = {
              'member_data': memberData,
              'total_sessions': 1,
              'present': record['status'] == 'present' ? 1 : 0,
              'late': record['status'] == 'late' ? 1 : 0,
              'absent': record['status'] == 'absent' ? 1 : 0,
            };
          }
        }
      }

      // Calculate individual attendance rates
      memberAttendance.forEach((memberId, data) {
        final attendanceCount = data['present'] + data['late'];
        data['attendance_rate'] = (attendanceCount / data['total_sessions']) * 100;
      });

      // Event type breakdown
      final eventTypeBreakdown = <String, int>{};
      for (final session in sessions) {
        final eventType = session['event_type'] ?? 'other';
        eventTypeBreakdown[eventType] = (eventTypeBreakdown[eventType] ?? 0) + 1;
      }

      return {
        'report_type': 'attendance',
        'choir_id': choirId,
        'generated_at': DateTime.now().toIso8601String(),
        'period_from': fromDate?.toIso8601String(),
        'period_to': toDate?.toIso8601String(),
        'summary': {
          'total_sessions': totalSessions,
          'avg_attendance_rate': avgAttendanceRate,
          'event_type_breakdown': eventTypeBreakdown,
        },
        'sessions': sessions,
        'member_attendance': memberAttendance,
        'records_by_session': recordsBySession,
      };
    } catch (e) {
      Logger.error('Error generating attendance report', e);
      return {};
    }
  }

  // Generate financial report
  Future<Map<String, dynamic>> generateFinancialReport({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Get payments data
      var paymentsQuery = _supabase
          .from('payments')
          .select('''
            *,
            choir_members!payments_member_id_fkey (
              registration_number,
              users!choir_members_user_id_fkey (
                id,
                full_name
              )
            )
          ''')
          .eq('choir_id', choirId);

      if (fromDate != null) {
        paymentsQuery = paymentsQuery.gte('payment_date', fromDate.toIso8601String());
      }
      if (toDate != null) {
        paymentsQuery = paymentsQuery.lte('payment_date', toDate.toIso8601String());
      }

      final payments = await paymentsQuery.order('payment_date', ascending: false);

      // Calculate totals
      double totalAmount = 0.0;
      double completedAmount = 0.0;
      double pendingAmount = 0.0;
      double refundedAmount = 0.0;

      final typeBreakdown = <String, double>{};
      final methodBreakdown = <String, double>{};
      final monthlyBreakdown = <String, double>{};

      for (final payment in payments) {
        final amount = payment['amount'].toDouble();
        final status = payment['status'] as String;
        final type = payment['type'] as String;
        final method = payment['method'] as String;
        
        totalAmount += amount;

        switch (status) {
          case 'completed':
            completedAmount += amount;
            break;
          case 'pending':
            pendingAmount += amount;
            break;
          case 'refunded':
            refundedAmount += amount;
            break;
        }

        // Type breakdown
        typeBreakdown[type] = (typeBreakdown[type] ?? 0.0) + amount;
        
        // Method breakdown  
        methodBreakdown[method] = (methodBreakdown[method] ?? 0.0) + amount;

        // Monthly breakdown
        final paymentDate = DateTime.parse(payment['payment_date']);
        final monthKey = '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}';
        monthlyBreakdown[monthKey] = (monthlyBreakdown[monthKey] ?? 0.0) + amount;
      }

      // Get outstanding fees
      final outstandingResponse = await _supabase
          .from('choir_members')
          .select('outstanding_fees')
          .eq('choir_id', choirId)
          .gt('outstanding_fees', 0);

      final totalOutstanding = outstandingResponse.fold<double>(
        0, (sum, member) => sum + (member['outstanding_fees'] ?? 0.0)
      );

      // Top paying members
      final memberPayments = <String, double>{};
      for (final payment in payments) {
        final memberId = payment['member_id'];
        if (payment['status'] == 'completed') {
          memberPayments[memberId] = (memberPayments[memberId] ?? 0.0) + payment['amount'];
        }
      }

      final topPayers = memberPayments.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'report_type': 'financial',
        'choir_id': choirId,
        'generated_at': DateTime.now().toIso8601String(),
        'period_from': fromDate?.toIso8601String(),
        'period_to': toDate?.toIso8601String(),
        'summary': {
          'total_amount': totalAmount,
          'completed_amount': completedAmount,
          'pending_amount': pendingAmount,
          'refunded_amount': refundedAmount,
          'total_outstanding': totalOutstanding,
          'collection_rate': (totalAmount > 0) ? (completedAmount / totalAmount) * 100 : 0,
        },
        'breakdowns': {
          'by_type': typeBreakdown,
          'by_method': methodBreakdown,
          'by_month': monthlyBreakdown,
        },
        'top_payers': topPayers.take(10).toList(),
        'payments': payments,
      };
    } catch (e) {
      Logger.error('Error generating financial report', e);
      return {};
    }
  }

  // Generate comprehensive choir report
  Future<Map<String, dynamic>> generateChoirOverviewReport({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final membershipData = await generateMembershipReport(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
      );

      final attendanceData = await generateAttendanceReport(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
      );

      final financialData = await generateFinancialReport(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Get choir information
      final choirQuery = await _supabase
          .from('choirs')
          .select()
          .eq('id', choirId);
      
      if (choirQuery.isEmpty) {
        throw Exception('Choir not found with ID: $choirId');
      }
      
      final choirResponse = choirQuery.first;

      return {
        'report_type': 'choir_overview',
        'choir_id': choirId,
        'choir_info': choirResponse,
        'generated_at': DateTime.now().toIso8601String(),
        'period_from': fromDate?.toIso8601String(),
        'period_to': toDate?.toIso8601String(),
        'membership': membershipData['summary'],
        'attendance': attendanceData['summary'],
        'financial': financialData['summary'],
        'detailed_data': {
          'membership': membershipData,
          'attendance': attendanceData,
          'financial': financialData,
        },
      };
    } catch (e) {
      Logger.error('Error generating choir overview report', e);
      return {};
    }
  }

  // Export report data to CSV format
  String exportToCSV(Map<String, dynamic> reportData, String reportType) {
    try {
      switch (reportType) {
        case 'membership':
          return _exportMembershipToCSV(reportData);
        case 'attendance':
          return _exportAttendanceToCSV(reportData);
        case 'financial':
          return _exportFinancialToCSV(reportData);
        default:
          return '';
      }
    } catch (e) {
      Logger.error('Error exporting to CSV', e);
      return '';
    }
  }

  String _exportMembershipToCSV(Map<String, dynamic> data) {
    final members = data['members'] as List<Map<String, dynamic>>? ?? [];
    final csv = StringBuffer();
    
    // Header
    csv.writeln('Registration Number,Full Name,Email,Phone,Status,Join Date,Outstanding Fees,Total Paid');
    
    // Data rows
    for (final member in members) {
      final userData = member['users'] ?? {};
      csv.writeln([
        member['registration_number'] ?? '',
        userData['full_name'] ?? '',
        userData['email'] ?? '',
        userData['phone_number'] ?? '',
        member['status'] ?? '',
        member['join_date'] ?? '',
        member['outstanding_fees'] ?? 0,
        member['total_paid'] ?? 0,
      ].join(','));
    }
    
    return csv.toString();
  }

  String _exportAttendanceToCSV(Map<String, dynamic> data) {
    final memberAttendance = data['member_attendance'] as Map<String, dynamic>? ?? {};
    final csv = StringBuffer();
    
    // Header
    csv.writeln('Member Name,Registration Number,Total Sessions,Present,Late,Absent,Attendance Rate');
    
    // Data rows
    memberAttendance.forEach((memberId, attendance) {
      final memberData = attendance['member_data'] ?? {};
      final userData = memberData['users'] ?? {};
      
      csv.writeln([
        userData['full_name'] ?? '',
        memberData['registration_number'] ?? '',
        attendance['total_sessions'] ?? 0,
        attendance['present'] ?? 0,
        attendance['late'] ?? 0,
        attendance['absent'] ?? 0,
        '${(attendance['attendance_rate'] ?? 0).toStringAsFixed(1)}%',
      ].join(','));
    });
    
    return csv.toString();
  }

  String _exportFinancialToCSV(Map<String, dynamic> data) {
    final payments = data['payments'] as List<Map<String, dynamic>>? ?? [];
    final csv = StringBuffer();
    
    // Header
    csv.writeln('Payment Date,Member Name,Registration Number,Amount,Type,Method,Status,Reference');
    
    // Data rows
    for (final payment in payments) {
      final memberData = payment['choir_members'] ?? {};
      final userData = memberData['users'] ?? {};
      
      csv.writeln([
        payment['payment_date'] ?? '',
        userData['full_name'] ?? '',
        memberData['registration_number'] ?? '',
        payment['amount'] ?? 0,
        payment['type'] ?? '',
        payment['method'] ?? '',
        payment['status'] ?? '',
        payment['reference'] ?? '',
      ].join(','));
    }
    
    return csv.toString();
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats(String choirId) async {
    try {
      // Get recent stats (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final overview = await generateChoirOverviewReport(
        choirId: choirId,
        fromDate: thirtyDaysAgo,
      );

      // Get trends
      final sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));
      final previousPeriod = await generateChoirOverviewReport(
        choirId: choirId,
        fromDate: sixtyDaysAgo,
        toDate: thirtyDaysAgo,
      );

      return {
        'current_period': overview,
        'previous_period': previousPeriod,
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting dashboard stats', e);
      return {};
    }
  }
}