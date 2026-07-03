import 'package:flutter/material.dart';

import '../../services/export_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_utils.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';

class ReportDetailScreen extends StatefulWidget {

  const ReportDetailScreen({
    super.key,
    required this.reportType,
    required this.reportData,
  });
  final String reportType;
  final Map<String, dynamic> reportData;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.reportType} Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export as Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.text_snippet, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader(),
              const SizedBox(height: 24),
              _buildReportSummary(),
              const SizedBox(height: 24),
              _buildReportContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    final generatedAt = widget.reportData['generated_at'] as String?;
    final period = _getReportPeriod();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getReportIcon(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.reportType} Report',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                    ),
                    if (generatedAt != null)
                      Text(
                        'Generated: ${Helpers.formatDateTime(DateTime.parse(generatedAt))}',
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 14,
                        ),
                      ),
                    if (period.isNotEmpty)
                      Text(
                        'Period: $period',
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummary() {
    final summary = widget.reportData['summary'] as Map<String, dynamic>? ?? {};

    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryGrid(summary),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> summary) {
    final items = <Widget>[];

    summary.forEach((key, value) {
      if (value != null) {
        items.add(_buildSummaryItem(
          label: _formatSummaryKey(key),
          value: _formatSummaryValue(key, value),
        ));
      }
    });

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items,
    );
  }

  Widget _buildSummaryItem({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.gray600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    switch (widget.reportType.toLowerCase()) {
      case 'membership':
        return _buildMembershipContent();
      case 'attendance':
        return _buildAttendanceContent();
      case 'financial':
        return _buildFinancialContent();
      case 'overview':
      case 'choir_overview':
        return _buildOverviewContent();
      default:
        return _buildDefaultContent();
    }
  }

  Widget _buildMembershipContent() {
    final members = widget.reportData['members'] as List? ?? [];
    final summary = widget.reportData['summary'] as Map<String, dynamic>? ?? {};
    final growthData = widget.reportData['growth_data'] as Map<String, dynamic>? ?? {};
    
    return Column(
      children: [
        // Summary Statistics
        _buildMembershipSummary(summary),
        const SizedBox(height: 20),
        
        // Growth Chart Data
        if (growthData.isNotEmpty) ...[
          _buildGrowthData(growthData),
          const SizedBox(height: 20),
        ],
        
        // Members List
        _buildMembersList(members),
      ],
    );
  }

  Widget _buildMembershipSummary(Map<String, dynamic> summary) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Membership Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                label: 'Total Members',
                value: '${summary['total_members'] ?? 0}',
                color: AppColors.primary,
              ),
              _buildStatCard(
                label: 'Active Members',
                value: '${summary['active_members'] ?? 0}',
                color: AppColors.success,
              ),
              _buildStatCard(
                label: 'Inactive Members', 
                value: '${summary['inactive_members'] ?? 0}',
                color: AppColors.warning,
              ),
              _buildStatCard(
                label: 'Suspended Members',
                value: '${summary['suspended_members'] ?? 0}',
                color: AppColors.error,
              ),
              _buildStatCard(
                label: 'Total Outstanding',
                value: CurrencyUtils.formatAmount(summary['total_outstanding'] ?? 0.0, 'TZS'),
                color: AppColors.error,
              ),
              _buildStatCard(
                label: 'Total Paid',
                value: CurrencyUtils.formatAmount(summary['total_paid'] ?? 0.0, 'TZS'),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (color ?? AppColors.primary).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthData(Map<String, dynamic> growthData) {
    final sortedEntries = growthData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Growth',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: sortedEntries.map((entry) => 
              _buildGrowthItem(entry.key, entry.value)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthItem(String month, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            month,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List members) {
    if (members.isEmpty) {
      return _buildEmptyState('No members found');
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Members List (${members.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: members.map((member) => _buildMemberItem(member)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(Map<String, dynamic> member) {
    final userData = member['users'] ?? {};
    final name = userData['full_name'] ?? 'Unknown';
    final email = userData['email'] ?? '';
    final status = member['status'] ?? 'unknown';
    final regNumber = member['registration_number'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getStatusColor(status),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.gray800,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: 14,
                    ),
                  ),
                Text(
                  'Reg: $regNumber',
                  style: const TextStyle(
                    color: AppColors.gray600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent() {
    final memberAttendance = widget.reportData['member_attendance'] as Map<String, dynamic>? ?? {};
    final summary = widget.reportData['summary'] as Map<String, dynamic>? ?? {};
    final sessions = widget.reportData['sessions'] as List? ?? [];
    
    return Column(
      children: [
        // Attendance Summary
        _buildAttendanceSummary(summary),
        const SizedBox(height: 20),
        
        // Sessions List
        if (sessions.isNotEmpty) ...[
          _buildSessionsList(sessions),
          const SizedBox(height: 20),
        ],
        
        // Member Attendance
        _buildMemberAttendance(memberAttendance),
      ],
    );
  }

  Widget _buildAttendanceSummary(Map<String, dynamic> summary) {
    final eventTypeBreakdown = summary['event_type_breakdown'] as Map<String, dynamic>? ?? {};
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                label: 'Total Sessions',
                value: '${summary['total_sessions'] ?? 0}',
                color: AppColors.primary,
              ),
              _buildStatCard(
                label: 'Average Attendance',
                value: '${(summary['avg_attendance_rate'] ?? 0.0).toStringAsFixed(1)}%',
                color: AppColors.success,
              ),
            ],
          ),
          if (eventTypeBreakdown.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Event Types',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gray800,
              ),
            ),
            const SizedBox(height: 12),
            ...eventTypeBreakdown.entries.map((entry) => 
              _buildEventTypeItem(entry.key, entry.value)
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventTypeItem(String type, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(List sessions) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Sessions (${sessions.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: sessions.take(10).map((session) => _buildSessionItem(session)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session) {
    final date = session['date'] ?? '';
    final title = session['title'] ?? 'No title';
    final eventType = session['event_type'] ?? 'other';
    
    Color eventColor;
    switch (eventType) {
      case 'rehearsal':
        eventColor = AppColors.primary;
        break;
      case 'service':
        eventColor = AppColors.success;
        break;
      case 'meeting':
        eventColor = AppColors.warning;
        break;
      default:
        eventColor = AppColors.gray600;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: eventColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: eventColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      eventType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: eventColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAttendance(Map<String, dynamic> memberAttendance) {
    if (memberAttendance.isEmpty) {
      return _buildEmptyState('No attendance data found');
    }

    // Sort members by attendance rate
    final sortedMembers = memberAttendance.entries.toList()
      ..sort((a, b) => (b.value['attendance_rate'] ?? 0.0).compareTo(a.value['attendance_rate'] ?? 0.0));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Member Attendance (${memberAttendance.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: sortedMembers.map((entry) => _buildAttendanceItem(entry.value)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(Map<String, dynamic> attendance) {
    final memberData = attendance['member_data'] ?? {};
    final userData = memberData['users'] ?? {};
    final name = userData['full_name'] ?? 'Unknown';
    final attendanceRate = (attendance['attendance_rate'] ?? 0.0) as double;
    final present = attendance['present'] ?? 0;
    final totalSessions = attendance['total_sessions'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.gray800,
                  ),
                ),
                Text(
                  '$present / $totalSessions sessions',
                  style: const TextStyle(
                    color: AppColors.gray600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getAttendanceColor(attendanceRate).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${attendanceRate.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getAttendanceColor(attendanceRate),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialContent() {
    final payments = widget.reportData['payments'] as List? ?? [];
    
    if (payments.isEmpty) {
      return _buildEmptyState('No payment data found');
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Payments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          ...payments.take(20).map((payment) => _buildPaymentItem(payment)),
          if (payments.length > 20)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Showing 20 of ${payments.length} payments',
                style: const TextStyle(
                  color: AppColors.gray600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final memberData = payment['choir_members'] ?? {};
    final userData = memberData['users'] ?? {};
    final name = userData['full_name'] ?? 'Unknown';
    final amount = payment['amount'] ?? 0.0;
    final method = payment['method'] ?? 'unknown';
    final date = payment['payment_date'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payment,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.gray800,
                  ),
                ),
                Text(
                  'via $method',
                  style: const TextStyle(
                    color: AppColors.gray600,
                    fontSize: 12,
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    Helpers.formatDate(DateTime.parse(date)),
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            CurrencyUtils.formatAmount(amount, 'TZS'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent() {
    return Column(
      children: [
        // Executive Summary Dashboard
        _buildExecutiveSummary(),
        const SizedBox(height: 24),
        
        // Key Performance Indicators
        _buildKPISection(),
        const SizedBox(height: 24),
        
        // Detailed Sections
        if (widget.reportData['membership'] != null) ...[
          _buildEnhancedOverviewSection('Membership Overview', widget.reportData['membership'], Icons.people, AppColors.primary),
          const SizedBox(height: 16),
        ],
        if (widget.reportData['attendance'] != null) ...[
          _buildEnhancedOverviewSection('Attendance Overview', widget.reportData['attendance'], Icons.check_circle, AppColors.success),
          const SizedBox(height: 16),
        ],
        if (widget.reportData['financial'] != null) ...[
          _buildEnhancedOverviewSection('Financial Overview', widget.reportData['financial'], Icons.attach_money, AppColors.warning),
          const SizedBox(height: 16),
        ],
        
        // Health Score Summary
        _buildChoirHealthScore(),
      ],
    );
  }

  Widget _buildExecutiveSummary() {
    final membershipData = widget.reportData['membership'] as Map<String, dynamic>? ?? {};
    final attendanceData = widget.reportData['attendance'] as Map<String, dynamic>? ?? {};
    final financialData = widget.reportData['financial'] as Map<String, dynamic>? ?? {};
    final choirInfo = widget.reportData['choir_info'] as Map<String, dynamic>? ?? {};

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choirInfo['name'] ?? 'Choir Overview',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                    ),
                    const Text(
                      'Executive Summary Dashboard',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  'Total Members',
                  '${membershipData['total_members'] ?? 0}',
                  AppColors.primary,
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetric(
                  'Avg Attendance',
                  '${(attendanceData['avg_attendance_rate'] ?? 0.0).toStringAsFixed(1)}%',
                  AppColors.success,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetric(
                  'Total Revenue',
                  CurrencyUtils.formatAmount(financialData['total_payments'] ?? 0.0, 'TZS'),
                  AppColors.warning,
                  Icons.attach_money,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    final membershipData = widget.reportData['membership'] as Map<String, dynamic>? ?? {};
    final attendanceData = widget.reportData['attendance'] as Map<String, dynamic>? ?? {};
    final financialData = widget.reportData['financial'] as Map<String, dynamic>? ?? {};

    // Calculate health metrics
    final totalMembers = membershipData['total_members'] ?? 0;
    final activeMembers = membershipData['active_members'] ?? 0;
    final memberEngagement = totalMembers > 0 ? (activeMembers / totalMembers * 100) : 0.0;
    
    final avgAttendance = attendanceData['avg_attendance_rate'] ?? 0.0;
    final totalOutstanding = financialData['total_outstanding'] ?? 0.0;
    final totalPaid = financialData['total_payments'] ?? 0.0;
    final paymentRate = (totalPaid + totalOutstanding) > 0 ? (totalPaid / (totalPaid + totalOutstanding) * 100) : 0.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Performance Indicators',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildKPICard(
                'Member Engagement',
                '${memberEngagement.toStringAsFixed(1)}%',
                memberEngagement >= 80 ? AppColors.success : memberEngagement >= 60 ? AppColors.warning : AppColors.error,
                Icons.people_outline,
              ),
              _buildKPICard(
                'Attendance Rate',
                '${avgAttendance.toStringAsFixed(1)}%',
                avgAttendance >= 80 ? AppColors.success : avgAttendance >= 60 ? AppColors.warning : AppColors.error,
                Icons.check_circle_outline,
              ),
              _buildKPICard(
                'Payment Rate',
                '${paymentRate.toStringAsFixed(1)}%',
                paymentRate >= 80 ? AppColors.success : paymentRate >= 60 ? AppColors.warning : AppColors.error,
                Icons.payment,
              ),
              _buildKPICard(
                'Outstanding Amount',
                CurrencyUtils.formatAmount(totalOutstanding, 'TZS'),
                totalOutstanding < 1000 ? AppColors.success : totalOutstanding < 5000 ? AppColors.warning : AppColors.error,
                Icons.money_off,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPerformanceLabel(value, color),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOverviewSection(String title, Map<String, dynamic> data, IconData icon, Color color) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryGrid(data),
        ],
      ),
    );
  }

  Widget _buildChoirHealthScore() {
    final membershipData = widget.reportData['membership'] as Map<String, dynamic>? ?? {};
    final attendanceData = widget.reportData['attendance'] as Map<String, dynamic>? ?? {};
    final financialData = widget.reportData['financial'] as Map<String, dynamic>? ?? {};

    // Calculate overall health score (0-100)
    final totalMembers = membershipData['total_members'] ?? 0;
    final activeMembers = membershipData['active_members'] ?? 0;
    final memberScore = totalMembers > 0 ? (activeMembers / totalMembers * 30) : 0.0;
    
    final avgAttendance = attendanceData['avg_attendance_rate'] ?? 0.0;
    final attendanceScore = avgAttendance * 0.4; // 40% weight
    
    final totalPaid = financialData['total_payments'] ?? 0.0;
    final totalOutstanding = financialData['total_outstanding'] ?? 0.0;
    final financialScore = (totalPaid + totalOutstanding) > 0 
        ? (totalPaid / (totalPaid + totalOutstanding) * 30) 
        : 0.0;

    final overallScore = (memberScore + attendanceScore + financialScore).clamp(0.0, 100.0);
    
    Color scoreColor;
    String scoreLabel;
    if (overallScore >= 85) {
      scoreColor = AppColors.success;
      scoreLabel = 'Excellent';
    } else if (overallScore >= 70) {
      scoreColor = Colors.lightGreen;
      scoreLabel = 'Good';
    } else if (overallScore >= 55) {
      scoreColor = AppColors.warning;
      scoreLabel = 'Fair';
    } else {
      scoreColor = AppColors.error;
      scoreLabel = 'Needs Attention';
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Choir Health Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        scoreColor.withValues(alpha: 0.2),
                        scoreColor.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(color: scoreColor, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${overallScore.toInt()}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        scoreLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreBreakdown('Membership', memberScore, 30),
                    _buildScoreBreakdown('Attendance', attendanceScore, 40),
                    _buildScoreBreakdown('Financial', financialScore, 30),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(String label, double score, int weight) {
    final percentage = (score / weight * 100).clamp(0.0, 100.0);
    return Column(
      children: [
        Text(
          '${percentage.toInt()}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: percentage >= 80 ? AppColors.success : percentage >= 60 ? AppColors.warning : AppColors.error,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
          ),
        ),
        Text(
          '($weight%)',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }

  String _getPerformanceLabel(String value, Color color) {
    if (color == AppColors.success) return 'GOOD';
    if (color == AppColors.warning) return 'OK';
    return 'LOW';
  }


  Widget _buildDefaultContent() {
    return const GlassCard(
      child: Column(
        children: [
          Icon(
            Icons.insert_chart,
            size: 64,
            color: AppColors.gray400,
          ),
          SizedBox(height: 16),
          Text(
            'Report Generated Successfully',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This report contains data that can be exported to various formats.',
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final exportService = ExportService();
      String? filePath;

      switch (action) {
        case 'export_pdf':
          filePath = await _exportToPDF(exportService);
          break;
        case 'export_excel':
          filePath = await _exportToExcel(exportService);
          break;
        case 'export_csv':
          filePath = await _exportToCSV();
          break;
      }

      if (filePath != null) {
        Helpers.showSuccessSnackbar('Report exported successfully');
      } else {
        Helpers.showErrorSnackbar('Failed to export report');
      }

    } catch (e) {
      Helpers.showErrorSnackbar('Export failed: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<String?> _exportToPDF(ExportService exportService) async {
    final reportType = widget.reportType.toLowerCase();
    switch (reportType) {
      case 'membership':
        return await exportService.exportMembershipToPDF(widget.reportData);
      case 'attendance':
        return await exportService.exportAttendanceToPDF(widget.reportData);
      case 'financial':
        return await exportService.exportFinancialToPDF(widget.reportData);
      case 'overview':
      case 'choir overview':
      case 'choir_overview':
        return await exportService.exportOverviewToPDF(widget.reportData);
      default:
        throw Exception('PDF export not supported for ${widget.reportType}');
    }
  }

  Future<String?> _exportToExcel(ExportService exportService) async {
    final reportType = widget.reportType.toLowerCase();
    switch (reportType) {
      case 'membership':
        return await exportService.exportMembershipToExcel(widget.reportData);
      case 'attendance':
        return await exportService.exportAttendanceToExcel(widget.reportData);
      case 'financial':
        return await exportService.exportFinancialToExcel(widget.reportData);
      case 'overview':
      case 'choir overview':
      case 'choir_overview':
        return await exportService.exportOverviewToExcel(widget.reportData);
      default:
        throw Exception('Excel export not supported for ${widget.reportType}');
    }
  }

  Future<String?> _exportToCSV() async {
    try {
      final exportService = ExportService();
      return await exportService.exportReportToCSV(widget.reportData, widget.reportType.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  IconData _getReportIcon() {
    switch (widget.reportType) {
      case 'Membership':
        return Icons.people;
      case 'Attendance':
        return Icons.check_circle;
      case 'Financial':
        return Icons.money;
      case 'Overview':
        return Icons.dashboard;
      default:
        return Icons.insert_chart;
    }
  }

  String _getReportPeriod() {
    final periodFrom = widget.reportData['period_from'] as String?;
    final periodTo = widget.reportData['period_to'] as String?;

    if (periodFrom != null && periodTo != null) {
      final from = Helpers.formatDate(DateTime.parse(periodFrom));
      final to = Helpers.formatDate(DateTime.parse(periodTo));
      return '$from - $to';
    } else if (periodFrom != null) {
      return 'From ${Helpers.formatDate(DateTime.parse(periodFrom))}';
    }
    
    return 'All time';
  }

  String _formatSummaryKey(String key) {
    return key.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatSummaryValue(String key, dynamic value) {
    if (value is double) {
      if (key.contains('rate') || key.contains('percentage')) {
        return '${value.toStringAsFixed(1)}%';
      } else if (key.contains('amount') || key.contains('fee') || key.contains('paid') || key.contains('outstanding')) {
        return CurrencyUtils.formatAmount(value, 'TZS');
      } else {
        return value.toStringAsFixed(1);
      }
    } else if (value is int) {
      return value.toString();
    } else {
      return value.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 80) return AppColors.success;
    if (rate >= 60) return AppColors.warning;
    return AppColors.error;
  }
}