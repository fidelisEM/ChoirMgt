import 'package:flutter/foundation.dart';
import '../services/report_service.dart';

class ReportController extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  Map<String, dynamic> _currentReport = {};
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get currentReport => _currentReport;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Generate membership report
  Future<void> generateMembershipReport({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
    String? membershipFilter,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      _currentReport = await _reportService.generateMembershipReport(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
        membershipFilter: membershipFilter,
      );
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to generate membership report: $e');
      _setLoading(false);
    }
  }

  // Generate attendance report
  Future<void> generateAttendanceReport({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      _currentReport = await _reportService.generateAttendanceReport(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to generate attendance report: $e');
      _setLoading(false);
    }
  }

  // Generate financial report
  Future<void> generateFinancialReport({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      _currentReport = await _reportService.generateFinancialReport(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to generate financial report: $e');
      _setLoading(false);
    }
  }

  // Generate choir overview report
  Future<void> generateChoirOverviewReport({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      _currentReport = await _reportService.generateChoirOverviewReport(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to generate choir overview report: $e');
      _setLoading(false);
    }
  }

  // Load dashboard statistics
  Future<void> loadDashboardStats(String choirId) async {
    try {
      _setLoading(true);
      _clearError();
      
      _dashboardStats = await _reportService.getDashboardStats(choirId);
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load dashboard statistics: $e');
      _setLoading(false);
    }
  }

  // Export current report to CSV
  String exportCurrentReportToCSV() {
    if (_currentReport.isEmpty) return '';
    
    final reportType = _currentReport['report_type'] as String? ?? '';
    return _reportService.exportToCSV(_currentReport, reportType);
  }

  // Get report summary
  Map<String, dynamic> getReportSummary() {
    return _currentReport['summary'] as Map<String, dynamic>? ?? {};
  }

  // Get specific report data
  dynamic getReportData(String key) {
    return _currentReport[key];
  }

  // Check if report has data
  bool get hasReportData => _currentReport.isNotEmpty;

  // Get report generation date
  DateTime? get reportGeneratedAt {
    final dateStr = _currentReport['generated_at'] as String?;
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  // Get report period
  Map<String, DateTime?> get reportPeriod {
    final fromStr = _currentReport['period_from'] as String?;
    final toStr = _currentReport['period_to'] as String?;
    
    return {
      'from': fromStr != null ? DateTime.parse(fromStr) : null,
      'to': toStr != null ? DateTime.parse(toStr) : null,
    };
  }

  // Calculate trends from dashboard stats
  Map<String, double> calculateTrends() {
    if (_dashboardStats.isEmpty) return {};

    final current = _dashboardStats['current_period'] as Map<String, dynamic>? ?? {};
    final previous = _dashboardStats['previous_period'] as Map<String, dynamic>? ?? {};

    final currentMembership = current['membership'] as Map<String, dynamic>? ?? {};
    final previousMembership = previous['membership'] as Map<String, dynamic>? ?? {};

    final currentAttendance = current['attendance'] as Map<String, dynamic>? ?? {};
    final previousAttendance = previous['attendance'] as Map<String, dynamic>? ?? {};

    final currentFinancial = current['financial'] as Map<String, dynamic>? ?? {};
    final previousFinancial = previous['financial'] as Map<String, dynamic>? ?? {};

    return {
      'membership_growth': _calculatePercentageChange(
        previousMembership['total_members'] ?? 0,
        currentMembership['total_members'] ?? 0,
      ),
      'attendance_change': _calculatePercentageChange(
        previousAttendance['avg_attendance_rate'] ?? 0,
        currentAttendance['avg_attendance_rate'] ?? 0,
      ),
      'revenue_change': _calculatePercentageChange(
        previousFinancial['completed_amount'] ?? 0,
        currentFinancial['completed_amount'] ?? 0,
      ),
      'collection_rate_change': _calculatePercentageChange(
        previousFinancial['collection_rate'] ?? 0,
        currentFinancial['collection_rate'] ?? 0,
      ),
    };
  }

  double _calculatePercentageChange(num previous, num current) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  // Get top performers
  List<Map<String, dynamic>> getTopPerformers() {
    if (_currentReport['report_type'] != 'attendance') return [];

    final memberAttendance = _currentReport['member_attendance'] as Map<String, dynamic>? ?? {};
    
    final performers = <Map<String, dynamic>>[];
    
    memberAttendance.forEach((memberId, data) {
      final memberData = data['member_data'] ?? {};
      final userData = memberData['users'] ?? {};
      
      performers.add({
        'member_id': memberId,
        'name': userData['full_name'] ?? '',
        'registration_number': memberData['registration_number'] ?? '',
        'attendance_rate': data['attendance_rate'] ?? 0.0,
        'total_sessions': data['total_sessions'] ?? 0,
        'present': data['present'] ?? 0,
      });
    });

    // Sort by attendance rate
    performers.sort((a, b) => b['attendance_rate'].compareTo(a['attendance_rate']));
    
    return performers.take(10).toList();
  }

  // Get payment insights
  Map<String, dynamic> getPaymentInsights() {
    if (_currentReport['report_type'] != 'financial') return {};

    final summary = _currentReport['summary'] as Map<String, dynamic>? ?? {};
    final breakdowns = _currentReport['breakdowns'] as Map<String, dynamic>? ?? {};

    return {
      'total_collected': summary['completed_amount'] ?? 0.0,
      'collection_rate': summary['collection_rate'] ?? 0.0,
      'outstanding_amount': summary['total_outstanding'] ?? 0.0,
      'most_popular_method': _getMostPopular(breakdowns['by_method'] ?? {}),
      'most_common_type': _getMostPopular(breakdowns['by_type'] ?? {}),
      'monthly_trend': breakdowns['by_month'] ?? {},
    };
  }

  String _getMostPopular(Map<String, dynamic> breakdown) {
    if (breakdown.isEmpty) return '';
    
    var maxEntry = breakdown.entries.first;
    for (final entry in breakdown.entries) {
      if (entry.value > maxEntry.value) {
        maxEntry = entry;
      }
    }
    
    return maxEntry.key;
  }

  // Clear data
  void clearData() {
    _currentReport.clear();
    _dashboardStats.clear();
    _clearError();
    notifyListeners();
  }

  void clearReport() {
    _currentReport.clear();
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
}