import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../services/export_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';

class AttendanceExportScreen extends StatefulWidget {
  const AttendanceExportScreen({super.key});

  @override
  State<AttendanceExportScreen> createState() => _AttendanceExportScreenState();
}

class _AttendanceExportScreenState extends State<AttendanceExportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedFormat = 'PDF';
  String _selectedFilter = 'All Members';
  bool _isExporting = false;

  final List<String> _exportFormats = ['PDF', 'Excel'];
  final List<String> _filterOptions = ['All Members', 'Active Only', 'With Low Attendance'];

  @override
  void initState() {
    super.initState();
    // Set default date range (last 30 days)
    _toDate = DateTime.now();
    _fromDate = _toDate!.subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildDateRangeSection(),
                const SizedBox(height: 16),
                _buildFormatSection(),
                const SizedBox(height: 16),
                _buildFilterSection(),
                const SizedBox(height: 16),
                _buildPreviewSection(),
                const SizedBox(height: 32),
                _buildExportButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.file_download,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Export Attendance Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate detailed attendance reports for analysis',
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'From Date',
                  _fromDate,
                  (date) => setState(() => _fromDate = date),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  'To Date',
                  _toDate,
                  (date) => setState(() => _toDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _setLastWeek,
                  child: const Text('Last 7 days'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _setLastMonth,
                  child: const Text('Last 30 days'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _setLastQuarter,
                  child: const Text('Last 3 months'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime) onDateChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(date, onDateChanged),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: AppColors.gray600),
                const SizedBox(width: 12),
                Text(
                  date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select date',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppColors.gray600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Format',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: _exportFormats.map((format) {
              final isSelected = _selectedFormat == format;
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      format == 'PDF' ? Icons.picture_as_pdf : Icons.table_chart,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.gray600,
                    ),
                    const SizedBox(width: 8),
                    Text(format),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedFormat = format;
                  });
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFormat == 'PDF' 
                        ? 'PDF format is ideal for viewing and printing reports'
                        : 'Excel format allows for detailed data analysis and filtering',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedFilter,
            decoration: const InputDecoration(
              labelText: 'Member Filter',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: _filterOptions.map((filter) {
              return DropdownMenuItem<String>(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
            },
          ),
          const SizedBox(height: 12),
          Text(
            _getFilterDescription(),
            style: const TextStyle(
              color: AppColors.gray600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterDescription() {
    switch (_selectedFilter) {
      case 'All Members':
        return 'Include all members in the attendance report';
      case 'Active Only':
        return 'Include only active members in the report';
      case 'With Low Attendance':
        return 'Include only members with attendance rate below 75%';
      default:
        return '';
    }
  }

  Widget _buildPreviewSection() {
    return Consumer2<AttendanceController, ChoirController>(
      builder: (context, attendanceController, choirController, child) {
        final selectedChoir = choirController.selectedChoir;
        
        if (selectedChoir == null) {
          return GlassCard(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No Choir Selected'),
                  Text('Please select a choir to export attendance data'),
                ],
              ),
            ),
          );
        }

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 16),
              _buildPreviewItem('Choir', selectedChoir.name),
              _buildPreviewItem(
                'Date Range', 
                '${DateFormat('MMM dd').format(_fromDate!)} - ${DateFormat('MMM dd, yyyy').format(_toDate!)}',
              ),
              _buildPreviewItem('Format', _selectedFormat),
              _buildPreviewItem('Filter', _selectedFilter),
              _buildPreviewItem('Estimated Members', '${selectedChoir.memberCount}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ready to export attendance data',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton(
      onPressed: _isExporting ? null : _exportAttendance,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download),
                const SizedBox(width: 8),
                Text(
                  'Export ${_selectedFormat.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _selectDate(DateTime? currentDate, Function(DateTime) onDateChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      onDateChanged(date);
    }
  }

  void _setLastWeek() {
    setState(() {
      _toDate = DateTime.now();
      _fromDate = _toDate!.subtract(const Duration(days: 7));
    });
  }

  void _setLastMonth() {
    setState(() {
      _toDate = DateTime.now();
      _fromDate = _toDate!.subtract(const Duration(days: 30));
    });
  }

  void _setLastQuarter() {
    setState(() {
      _toDate = DateTime.now();
      _fromDate = _toDate!.subtract(const Duration(days: 90));
    });
  }

  Future<void> _exportAttendance() async {
    if (_fromDate == null || _toDate == null) {
      Helpers.showErrorSnackbar('Please select date range');
      return;
    }

    final choirController = Provider.of<ChoirController>(context, listen: false);
    if (choirController.selectedChoir == null) {
      Helpers.showErrorSnackbar('Please select a choir first');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Generate attendance report data
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      final reportData = await attendanceController.generateAttendanceReportData(
        choirId: choirController.selectedChoir!.id,
        fromDate: _fromDate!,
        toDate: _toDate!,
        filter: _selectedFilter,
      );

      if (reportData == null || reportData.isEmpty) {
        Helpers.showErrorSnackbar('No attendance data found for the selected period');
        return;
      }

      // Export based on selected format
      final exportService = ExportService();
      String? filePath;

      if (_selectedFormat == 'PDF') {
        filePath = await exportService.exportAttendanceToPDF(reportData);
      } else {
        filePath = await exportService.exportAttendanceToExcel(reportData);
      }

      if (filePath != null) {
        Helpers.showSuccessSnackbar('Attendance exported successfully');
        
        // Show file location dialog
        _showExportSuccessDialog(filePath);
      } else {
        Helpers.showErrorSnackbar('Failed to export attendance data');
      }
    } catch (e) {
      Helpers.showErrorSnackbar('Error exporting attendance: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showExportSuccessDialog(String filePath) {
    Get.dialog(
      AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance data has been exported successfully.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'File saved to: $filePath',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.back(); // Return to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}