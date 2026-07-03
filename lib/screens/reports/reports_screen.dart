import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/report_controller.dart';
import '../../models/models.dart';
import '../../utils/helpers.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoadingChoirs = false;
  String _membershipFilter = 'all'; // all, active, inactive, suspended

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'type': 'membership',
      'title': 'Membership Report',
      'description': 'Member statistics and growth analysis',
      'icon': Icons.people,
      'color': Colors.blue,
    },
    {
      'type': 'attendance',
      'title': 'Attendance Report', 
      'description': 'Session attendance and member participation',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'type': 'financial',
      'title': 'Financial Report',
      'description': 'Payment collections and outstanding fees',
      'icon': Icons.attach_money,
      'color': Colors.orange,
    },
    {
      'type': 'overview',
      'title': 'Choir Overview',
      'description': 'Comprehensive choir performance summary',
      'icon': Icons.analytics,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Set default date range (last 6 months to capture test data)
    _toDate = DateTime.now();
    _fromDate = _toDate!.subtract(const Duration(days: 180));
    
    // Load choirs on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChoirs();
    });
  }

  Future<void> _loadChoirs() async {
    setState(() => _isLoadingChoirs = true);
    try {
      final choirController = Provider.of<ChoirController>(context, listen: false);
      final authController = Provider.of<AuthController>(context, listen: false);
      
      if (authController.currentUser != null) {
        if (authController.currentUser!.role == UserRole.admin) {
          await choirController.loadChoirs(adminView: true);
        } else {
          await choirController.loadChoirs(
            userId: authController.currentUser!.id,
            adminView: false,
          );
        }
      }
    } catch (e) {
      Helpers.showErrorSnackbar('Failed to load choirs: $e');
    } finally {
      setState(() => _isLoadingChoirs = false);
    }
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _toDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  void _generateReport(String reportType) async {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    if (choirController.selectedChoir == null) {
      Helpers.showErrorSnackbar('Please select a choir first');
      return;
    }

    final choirId = choirController.selectedChoir!.id;
    final reportController = Provider.of<ReportController>(context, listen: false);

    // Show loading dialog
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      switch (reportType) {
        case 'membership':
          await reportController.generateMembershipReport(
            choirId: choirId,
            fromDate: _fromDate,
            toDate: _toDate,
            membershipFilter: _membershipFilter,
          );
          break;
        case 'attendance':
          await reportController.generateAttendanceReport(
            choirId: choirId,
            fromDate: _fromDate,
            toDate: _toDate,
          );
          break;
        case 'financial':
          await reportController.generateFinancialReport(
            choirId: choirId,
            fromDate: _fromDate,
            toDate: _toDate,
          );
          break;
        case 'overview':
          await reportController.generateChoirOverviewReport(
            choirId: choirId,
            fromDate: _fromDate,
            toDate: _toDate,
          );
          break;
        case 'comprehensive':
          await reportController.generateChoirOverviewReport(
            choirId: choirId,
            fromDate: _fromDate,
            toDate: _toDate,
          );
          break;
        case 'trends':
          // For trends, we'll generate a membership report with historical data
          await reportController.generateMembershipReport(
            choirId: choirId,
            fromDate: _fromDate ?? DateTime.now().subtract(const Duration(days: 365)),
            toDate: _toDate,
            membershipFilter: _membershipFilter,
          );
          break;
        case 'export':
          // For export, generate overview report and then show export options
          await reportController.generateChoirOverviewReport(
            choirId: choirId,
            fromDate: _fromDate,
            toDate: _toDate,
          );
          break;
        default:
          throw Exception('Unknown report type: $reportType');
      }

      // Hide loading
      Get.back();

      if (reportController.hasReportData) {
        if (reportType == 'export') {
          // For export, show export options instead of navigating to detail screen
          _showExportOptions(reportController);
        } else {
          // Navigate to report details screen
          Get.to(() => ReportDetailScreen(
            reportType: reportType,
            reportData: reportController.currentReport,
          ));
        }
      } else {
        Helpers.showErrorSnackbar('No data available for this report');
      }

    } catch (e) {
      // Hide loading
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Helpers.showErrorSnackbar('Failed to generate report: $e');
    }
  }

  Widget _buildChoirSelection(ChoirController choirController) {
    if (_isLoadingChoirs) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading choirs...'),
          ],
        ),
      );
    }

    if (choirController.choirs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('No choirs available')),
            TextButton(
              onPressed: _loadChoirs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: choirController.selectedChoir?.id,
      decoration: const InputDecoration(
        labelText: 'Select Choir',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.music_note),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      isExpanded: true,
      items: choirController.choirs.map((choir) {
        return DropdownMenuItem<String>(
          value: choir.id,
          child: Text(choir.name),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final selectedChoir = choirController.choirs.firstWhere((c) => c.id == value);
          choirController.selectChoir(selectedChoir);
        }
      },
      validator: (value) => value == null ? 'Please select a choir' : null,
    );
  }

  Widget _buildMembershipFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Membership Filter',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip('All Members', 'all'),
            _buildFilterChip('Active', 'active'),
            _buildFilterChip('Inactive', 'inactive'),
            _buildFilterChip('Suspended', 'suspended'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _membershipFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _membershipFilter = value;
          });
        }
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        foregroundColor: Colors.black,
      ),
      body: Consumer3<ReportController, ChoirController, AuthController>(
        builder: (context, reportController, choirController, authController, child) {

          return Column(
            children: [
              // Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // Choir selection dropdown
                    _buildChoirSelection(choirController),
                    const SizedBox(height: 16),
                    
                    // Membership filter (only show if choir is selected)
                    if (choirController.selectedChoir != null) ...[
                      _buildMembershipFilter(),
                      const SizedBox(height: 16),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDateRange,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _fromDate != null && _toDate != null
                                          ? '${DateFormat('MMM dd').format(_fromDate!)} - ${DateFormat('MMM dd, yyyy').format(_toDate!)}'
                                          : 'Select date range',
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Report types grid
              Expanded(
                child: choirController.selectedChoir == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select a choir to generate reports',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose a choir from the dropdown above',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _reportTypes.length,
                          itemBuilder: (context, index) {
                            final reportType = _reportTypes[index];
                            return Card(
                              elevation: 4,
                              child: InkWell(
                                onTap: () => _generateReport(reportType['type']),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        reportType['color'].withOpacity(0.1),
                                        reportType['color'].withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        reportType['icon'],
                                        size: 48,
                                        color: reportType['color'],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        reportType['title'],
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        reportType['description'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showExportOptions(ReportController reportController) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Generate PDF report'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('pdf', reportController);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              subtitle: const Text('Generate Excel spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('excel', reportController);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: const Text('Export as CSV'),
              subtitle: const Text('Generate CSV file'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('csv', reportController);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport(String format, ReportController reportController) async {
    try {
      // Navigate to the detail screen with export actions
      final reportData = reportController.currentReport;
      if (reportData.isEmpty) {
        Helpers.showErrorSnackbar('No report data available');
        return;
      }
      
      Get.to(() => ReportDetailScreen(
        reportType: 'overview',
        reportData: reportData,
      ));
    } catch (e) {
      Helpers.showErrorSnackbar('Export failed: $e');
    }
  }

}