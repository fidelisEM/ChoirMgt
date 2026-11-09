import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../services/export_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
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
  final List<String> _filterOptions = [
    'All Members',
    'Active Only',
    'With Low Attendance',
  ];

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
        title: Text(context.tr('attExportAttendanceTitle')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
          Text(
            context.tr('attExportAttendanceDataHeading'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('attExportHeaderSubtitle'),
            style: const TextStyle(color: AppColors.gray600, fontSize: 16),
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
          Text(
            context.tr('attDateRangeHeading'),
            style: const TextStyle(
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
                  context.tr('attFromDateLabel'),
                  _fromDate,
                  (date) => setState(() => _fromDate = date),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  context.tr('attToDateLabel'),
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
                  child: Text(context.tr('attLast7Days')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _setLastMonth,
                  child: Text(context.tr('attLast30Days')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _setLastQuarter,
                  child: Text(context.tr('attLast3Months')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    Function(DateTime) onDateChanged,
  ) {
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
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.gray600,
                ),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : context.tr('attSelectDatePlaceholder'),
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
          Text(
            context.tr('attExportFormatHeading'),
            style: const TextStyle(
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
                      format == 'PDF'
                          ? Icons.picture_as_pdf
                          : Icons.table_chart,
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
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFormat == 'PDF'
                        ? context.tr('attPdfFormatDescription')
                        : context.tr('attExcelFormatDescription'),
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
          Text(
            context.tr('attFilterOptionsHeading'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedFilter,
            decoration: InputDecoration(
              labelText: context.tr('attMemberFilterLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.filter_list),
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
            style: const TextStyle(color: AppColors.gray600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getFilterDescription() {
    switch (_selectedFilter) {
      case 'All Members':
        return context.tr('attFilterAllDescription');
      case 'Active Only':
        return context.tr('attFilterActiveDescription');
      case 'With Low Attendance':
        return context.tr('attFilterLowAttendanceDescription');
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
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(context.tr('attNoChoirSelectedTitle')),
                  Text(context.tr('attSelectChoirExportPrompt')),
                ],
              ),
            ),
          );
        }

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('attExportPreviewHeading'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 16),
              _buildPreviewItem(
                context.tr('attChoirLabel'),
                selectedChoir.name,
              ),
              _buildPreviewItem(
                context.tr('attDateRangeHeading'),
                '${DateFormat('MMM dd').format(_fromDate!)} - ${DateFormat('MMM dd, yyyy').format(_toDate!)}',
              ),
              _buildPreviewItem(context.tr('attFormatLabel'), _selectedFormat),
              _buildPreviewItem(context.tr('attFilterLabel'), _selectedFilter),
              _buildPreviewItem(
                context.tr('attEstimatedMembersLabel'),
                '${selectedChoir.memberCount}',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('attReadyToExport'),
                        style: const TextStyle(
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  '${context.tr('attExport')} ${_selectedFormat.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _selectDate(
    DateTime? currentDate,
    Function(DateTime) onDateChanged,
  ) async {
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
      Helpers.showErrorSnackbar(context.tr('attSelectDateRangeError'));
      return;
    }

    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    if (choirController.selectedChoir == null) {
      Helpers.showErrorSnackbar(context.tr('attSelectChoirFirstError'));
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Generate attendance report data
      final attendanceController = Provider.of<AttendanceController>(
        context,
        listen: false,
      );
      final reportData = await attendanceController
          .generateAttendanceReportData(
            choirId: choirController.selectedChoir!.id,
            fromDate: _fromDate!,
            toDate: _toDate!,
            filter: _selectedFilter,
          );

      if (!mounted) return;
      if (reportData == null || reportData.isEmpty) {
        Helpers.showErrorSnackbar(context.tr('attNoDataFoundPeriod'));
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

      if (!mounted) return;
      if (filePath != null) {
        Helpers.showSuccessSnackbar(context.tr('attExportedSuccessfully'));

        // Show file location dialog
        _showExportSuccessDialog(filePath);
      } else {
        Helpers.showErrorSnackbar(context.tr('attFailedExportData'));
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showErrorSnackbar('${context.tr('attErrorExportingPrefix')}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showExportSuccessDialog(String filePath) {
    Get.dialog(
      AlertDialog(
        title: Text(context.tr('attExportSuccessfulTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('attDataExportedSuccessMsg')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${context.tr('attFileSavedToPrefix')} $filePath',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.back(); // Return to previous screen
            },
            child: Text(context.tr('done')),
          ),
        ],
      ),
    );
  }
}
