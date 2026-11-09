import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/logger.dart';

// Platform-specific imports
import 'export_service_web.dart'
    if (dart.library.io) 'export_service_io.dart'
    as platform;

class ExportService {
  factory ExportService() => _instance;
  ExportService._internal();
  static final ExportService _instance = ExportService._internal();

  // Export membership report to PDF
  Future<String?> exportMembershipToPDF(Map<String, dynamic> reportData) async {
    try {
      final pdf = pw.Document();
      final members =
          reportData['members'] as List<Map<String, dynamic>>? ?? [];
      final summary = reportData['summary'] as Map<String, dynamic>? ?? {};

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Membership Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              // Generation info
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.')[0]}',
              ),
              pw.SizedBox(height: 20),

              // Summary section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Total Members: ${summary['total_members'] ?? 0}'),
                    pw.Text(
                      'Active Members: ${summary['active_members'] ?? 0}',
                    ),
                    pw.Text(
                      'Inactive Members: ${summary['inactive_members'] ?? 0}',
                    ),
                    pw.Text(
                      'Suspended Members: ${summary['suspended_members'] ?? 0}',
                    ),
                    pw.Text(
                      'Total Outstanding: KSH ${(summary['total_outstanding'] ?? 0.0).toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Total Paid: KSH ${(summary['total_paid'] ?? 0.0).toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Collection Rate: ${(summary['collection_rate'] ?? 0.0).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Members table
              pw.Text(
                'Member Details',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5), // Reg Number
                  1: const pw.FlexColumnWidth(2), // Name
                  2: const pw.FlexColumnWidth(2.5), // Email
                  3: const pw.FlexColumnWidth(1), // Status
                  4: const pw.FlexColumnWidth(1.5), // Outstanding
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Reg. No.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Email',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Status',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Outstanding',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...members.map((member) {
                    final userData = member['users'] ?? {};
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(member['registration_number'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(userData['full_name'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(userData['email'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(member['status'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'KSH ${(member['outstanding_fees'] ?? 0.0).toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      return await _savePdfFile(pdf, 'membership_report');
    } catch (e, stackTrace) {
      Logger.error('Error exporting membership to PDF', e, stackTrace);
      return null;
    }
  }

  // Export attendance report to PDF
  Future<String?> exportAttendanceToPDF(Map<String, dynamic> reportData) async {
    try {
      final pdf = pw.Document();
      final memberAttendance =
          reportData['member_attendance'] as Map<String, dynamic>? ?? {};
      final summary = reportData['summary'] as Map<String, dynamic>? ?? {};

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Attendance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              // Generation info
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.')[0]}',
              ),
              pw.SizedBox(height: 20),

              // Summary section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Total Sessions: ${summary['total_sessions'] ?? 0}',
                    ),
                    pw.Text('Total Members: ${summary['total_members'] ?? 0}'),
                    pw.Text(
                      'Average Attendance Rate: ${(summary['avg_attendance_rate'] ?? 0.0).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Attendance table
              pw.Text(
                'Member Attendance',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5), // Reg Number
                  1: const pw.FlexColumnWidth(2), // Name
                  2: const pw.FlexColumnWidth(1), // Total Sessions
                  3: const pw.FlexColumnWidth(1), // Present
                  4: const pw.FlexColumnWidth(1), // Late
                  5: const pw.FlexColumnWidth(1), // Absent
                  6: const pw.FlexColumnWidth(1.5), // Rate
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Reg. No.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Present',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Late',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Absent',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Rate',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...memberAttendance.entries.map((entry) {
                    final attendance = entry.value as Map<String, dynamic>;
                    final memberData = attendance['member_data'] ?? {};
                    final userData =
                        memberData['users'] ??
                        memberData; // Fallback to memberData if no users nested object

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            memberData['registration_number'] ?? '',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(userData['full_name'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${attendance['total_sessions'] ?? 0}',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${attendance['present'] ?? 0}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${attendance['late'] ?? 0}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${attendance['absent'] ?? 0}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${(attendance['attendance_rate'] ?? 0.0).toStringAsFixed(1)}%',
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      return await _savePdfFile(pdf, 'attendance_report');
    } catch (e, stackTrace) {
      Logger.error('Error exporting attendance to PDF', e, stackTrace);
      return null;
    }
  }

  // Export financial report to PDF
  Future<String?> exportFinancialToPDF(Map<String, dynamic> reportData) async {
    try {
      final pdf = pw.Document();
      final payments =
          reportData['payments'] as List<Map<String, dynamic>>? ?? [];
      final summary = reportData['summary'] as Map<String, dynamic>? ?? {};

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Financial Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              // Generation info
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.')[0]}',
              ),
              pw.SizedBox(height: 20),

              // Summary section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Total Amount: KSH ${(summary['total_amount'] ?? 0.0).toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Completed: KSH ${(summary['completed_amount'] ?? 0.0).toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Pending: KSH ${(summary['pending_amount'] ?? 0.0).toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Outstanding: KSH ${(summary['total_outstanding'] ?? 0.0).toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Collection Rate: ${(summary['collection_rate'] ?? 0.0).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Payments table
              pw.Text(
                'Payment Details',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5), // Date
                  1: const pw.FlexColumnWidth(2), // Member
                  2: const pw.FlexColumnWidth(1), // Amount
                  3: const pw.FlexColumnWidth(1), // Type
                  4: const pw.FlexColumnWidth(1), // Method
                  5: const pw.FlexColumnWidth(1), // Status
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Member',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Type',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Method',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Status',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data rows (limit to first 50 for space)
                  ...payments.take(50).map((payment) {
                    final memberData = payment['choir_members'] ?? {};
                    final userData = memberData['users'] ?? {};

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            payment['payment_date']?.toString().split('T')[0] ??
                                '',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(userData['full_name'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${payment['amount'] ?? 0}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(payment['type'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(payment['method'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(payment['status'] ?? ''),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              if (payments.length > 50)
                pw.Text(
                  'Note: Only showing first 50 payments. For complete data, export to Excel.',
                ),
            ];
          },
        ),
      );

      return await _savePdfFile(pdf, 'financial_report');
    } catch (e, stackTrace) {
      Logger.error('Error exporting financial to PDF', e, stackTrace);
      return null;
    }
  }

  // Export membership report to Excel
  Future<String?> exportMembershipToExcel(
    Map<String, dynamic> reportData,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Membership Report'];

      final members =
          reportData['members'] as List<Map<String, dynamic>>? ?? [];
      final summary = reportData['summary'] as Map<String, dynamic>? ?? {};

      // Add headers
      sheet.appendRow([
        TextCellValue('Registration Number'),
        TextCellValue('Full Name'),
        TextCellValue('Email'),
        TextCellValue('Phone Number'),
        TextCellValue('Status'),
        TextCellValue('Join Date'),
        TextCellValue('Outstanding Fees'),
        TextCellValue('Total Paid'),
      ]);

      // Add data rows
      for (final member in members) {
        final userData = member['users'] ?? {};
        sheet.appendRow([
          TextCellValue(member['registration_number'] ?? ''),
          TextCellValue(userData['full_name'] ?? ''),
          TextCellValue(userData['email'] ?? ''),
          TextCellValue(userData['phone_number'] ?? ''),
          TextCellValue(member['status'] ?? ''),
          TextCellValue(member['join_date'] ?? ''),
          DoubleCellValue(member['outstanding_fees'] ?? 0.0),
          DoubleCellValue(member['total_paid'] ?? 0.0),
        ]);
      }

      // Add summary sheet
      final summarySheet = excel['Summary'];
      summarySheet.appendRow([
        TextCellValue('Summary Statistics'),
        TextCellValue(''),
      ]);
      summarySheet.appendRow([
        TextCellValue('Total Members'),
        IntCellValue(summary['total_members'] ?? 0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Active Members'),
        IntCellValue(summary['active_members'] ?? 0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Inactive Members'),
        IntCellValue(summary['inactive_members'] ?? 0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Suspended Members'),
        IntCellValue(summary['suspended_members'] ?? 0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Total Outstanding'),
        DoubleCellValue(summary['total_outstanding'] ?? 0.0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Total Paid'),
        DoubleCellValue(summary['total_paid'] ?? 0.0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Collection Rate (%)'),
        DoubleCellValue(summary['collection_rate'] ?? 0.0),
      ]);

      excel.delete('Sheet1'); // Remove default sheet
      return await _saveExcelFile(excel, 'membership_report');
    } catch (e, stackTrace) {
      Logger.error('Error exporting membership to Excel', e, stackTrace);
      return null;
    }
  }

  // Export attendance report to Excel
  Future<String?> exportAttendanceToExcel(
    Map<String, dynamic> reportData,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Attendance Report'];

      final memberAttendance =
          reportData['member_attendance'] as Map<String, dynamic>? ?? {};
      final summary = reportData['summary'] as Map<String, dynamic>? ?? {};

      // Add headers
      sheet.appendRow([
        TextCellValue('Registration Number'),
        TextCellValue('Full Name'),
        TextCellValue('Total Sessions'),
        TextCellValue('Present'),
        TextCellValue('Late'),
        TextCellValue('Absent'),
        TextCellValue('Attendance Rate (%)'),
      ]);

      // Add data rows
      memberAttendance.forEach((memberId, attendance) {
        final memberData = attendance['member_data'] ?? {};
        final userData =
            memberData['users'] ??
            memberData; // Fallback to memberData if no users nested object

        sheet.appendRow([
          TextCellValue(memberData['registration_number'] ?? ''),
          TextCellValue(userData['full_name'] ?? ''),
          IntCellValue(attendance['total_sessions'] ?? 0),
          IntCellValue(attendance['present'] ?? 0),
          IntCellValue(attendance['late'] ?? 0),
          IntCellValue(attendance['absent'] ?? 0),
          DoubleCellValue(attendance['attendance_rate'] ?? 0.0),
        ]);
      });

      // Add summary sheet
      final summarySheet = excel['Summary'];
      summarySheet.appendRow([
        TextCellValue('Summary Statistics'),
        TextCellValue(''),
      ]);
      summarySheet.appendRow([
        TextCellValue('Total Sessions'),
        IntCellValue(summary['total_sessions'] ?? 0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Total Members'),
        IntCellValue(summary['total_members'] ?? 0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Average Attendance Rate (%)'),
        DoubleCellValue(summary['avg_attendance_rate'] ?? 0.0),
      ]);

      excel.delete('Sheet1'); // Remove default sheet
      return await _saveExcelFile(excel, 'attendance_report');
    } catch (e, stackTrace) {
      Logger.error('Error exporting attendance to Excel', e, stackTrace);
      return null;
    }
  }

  // Export financial report to Excel
  Future<String?> exportFinancialToExcel(
    Map<String, dynamic> reportData,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Financial Report'];

      final payments =
          reportData['payments'] as List<Map<String, dynamic>>? ?? [];
      final summary = reportData['summary'] as Map<String, dynamic>? ?? {};

      // Add headers
      sheet.appendRow([
        TextCellValue('Payment Date'),
        TextCellValue('Member Name'),
        TextCellValue('Registration Number'),
        TextCellValue('Amount'),
        TextCellValue('Type'),
        TextCellValue('Method'),
        TextCellValue('Status'),
        TextCellValue('Reference'),
        TextCellValue('Description'),
      ]);

      // Add data rows
      for (final payment in payments) {
        final memberData = payment['choir_members'] ?? {};
        final userData = memberData['users'] ?? {};

        sheet.appendRow([
          TextCellValue(payment['payment_date'] ?? ''),
          TextCellValue(userData['full_name'] ?? ''),
          TextCellValue(memberData['registration_number'] ?? ''),
          DoubleCellValue(payment['amount'] ?? 0.0),
          TextCellValue(payment['type'] ?? ''),
          TextCellValue(payment['method'] ?? ''),
          TextCellValue(payment['status'] ?? ''),
          TextCellValue(payment['reference'] ?? ''),
          TextCellValue(payment['description'] ?? ''),
        ]);
      }

      // Add summary sheet
      final summarySheet = excel['Summary'];
      summarySheet.appendRow([
        TextCellValue('Summary Statistics'),
        TextCellValue(''),
      ]);
      summarySheet.appendRow([
        TextCellValue('Total Amount'),
        DoubleCellValue(summary['total_amount'] ?? 0.0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Completed Amount'),
        DoubleCellValue(summary['completed_amount'] ?? 0.0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Pending Amount'),
        DoubleCellValue(summary['pending_amount'] ?? 0.0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Total Outstanding'),
        DoubleCellValue(summary['total_outstanding'] ?? 0.0),
      ]);
      summarySheet.appendRow([
        TextCellValue('Collection Rate (%)'),
        DoubleCellValue(summary['collection_rate'] ?? 0.0),
      ]);

      excel.delete('Sheet1'); // Remove default sheet
      return await _saveExcelFile(excel, 'financial_report');
    } catch (e, stackTrace) {
      Logger.error('Error exporting financial to Excel', e, stackTrace);
      return null;
    }
  }

  // Helper method to save PDF file
  Future<String> _savePdfFile(pw.Document pdf, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fullFileName = '${fileName}_$timestamp.pdf';
    final bytes = await pdf.save();

    if (kIsWeb) {
      _downloadFileOnWeb(bytes, fullFileName);
      return 'Downloaded: $fullFileName';
    }

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/$fullFileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // Helper method to save Excel file
  Future<String> _saveExcelFile(Excel excel, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fullFileName = '${fileName}_$timestamp.xlsx';
    final bytes = excel.save();

    if (bytes != null) {
      if (kIsWeb) {
        _downloadFileOnWeb(Uint8List.fromList(bytes), fullFileName);
        return 'Downloaded: $fullFileName';
      }

      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$fullFileName');
      await file.writeAsBytes(bytes);
      return file.path;
    }

    throw Exception('Failed to generate Excel file');
  }

  // Export choir overview report to PDF
  Future<String?> exportOverviewToPDF(Map<String, dynamic> reportData) async {
    try {
      final pdf = pw.Document();
      final choirInfo = reportData['choir_info'] ?? {};
      final membership = reportData['membership'] ?? {};
      final attendance = reportData['attendance'] ?? {};
      final financial = reportData['financial'] ?? {};

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Choir Overview Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              // Choir Information
              pw.Text('Choir: ${choirInfo['name'] ?? 'Unknown Choir'}'),
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.')[0]}',
              ),
              pw.SizedBox(height: 20),

              // Membership Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Membership Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Total Members: ${membership['total_members'] ?? 0}',
                    ),
                    pw.Text(
                      'Active Members: ${membership['active_members'] ?? 0}',
                    ),
                    pw.Text(
                      'Inactive Members: ${membership['inactive_members'] ?? 0}',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Attendance Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Attendance Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Total Sessions: ${attendance['total_sessions'] ?? 0}',
                    ),
                    pw.Text(
                      'Average Attendance Rate: ${(attendance['avg_attendance_rate'] ?? 0).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Financial Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Financial Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Total Revenue: KSH ${(financial['completed_amount'] ?? 0).toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Outstanding Amount: KSH ${(financial['total_outstanding'] ?? 0).toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Collection Rate: ${(financial['collection_rate'] ?? 0).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      return await _savePdfFile(pdf, 'choir_overview_report');
    } catch (e, stackTrace) {
      Logger.error('Error exporting overview to PDF', e, stackTrace);
      return null;
    }
  }

  // Export choir overview report to Excel
  Future<String?> exportOverviewToExcel(Map<String, dynamic> reportData) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Overview'];

      final choirInfo = reportData['choir_info'] ?? {};
      final membership = reportData['membership'] ?? {};
      final attendance = reportData['attendance'] ?? {};
      final financial = reportData['financial'] ?? {};

      // Add choir information
      int row = 0;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
          .value = TextCellValue(
        'CHOIR OVERVIEW REPORT',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
          .value = TextCellValue(
        'Choir Name: ${choirInfo['name'] ?? 'Unknown'}',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
          .value = TextCellValue(
        'Generated: ${DateTime.now().toString().split('.')[0]}',
      );
      row++; // Empty row

      // Membership section
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
          .value = TextCellValue(
        'MEMBERSHIP SUMMARY',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        'Total Members',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row++))
          .value = IntCellValue(
        membership['total_members'] ?? 0,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        'Active Members',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row++))
          .value = IntCellValue(
        membership['active_members'] ?? 0,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        'Inactive Members',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row++))
          .value = IntCellValue(
        membership['inactive_members'] ?? 0,
      );
      row++; // Empty row

      // Attendance section
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
          .value = TextCellValue(
        'ATTENDANCE SUMMARY',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        'Total Sessions',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row++))
          .value = IntCellValue(
        attendance['total_sessions'] ?? 0,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        'Avg Attendance Rate',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row++))
          .value = TextCellValue(
        '${(attendance['avg_attendance_rate'] ?? 0).toStringAsFixed(1)}%',
      );
      row++; // Empty row

      // Financial section
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
          .value = TextCellValue(
        'FINANCIAL SUMMARY',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        'Total Revenue',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row++))
          .value = TextCellValue(
        'KSH ${(financial['completed_amount'] ?? 0).toStringAsFixed(2)}',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        'Outstanding Amount',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row++))
          .value = TextCellValue(
        'KSH ${(financial['total_outstanding'] ?? 0).toStringAsFixed(2)}',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        'Collection Rate',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row++))
          .value = TextCellValue(
        '${(financial['collection_rate'] ?? 0).toStringAsFixed(1)}%',
      );

      excel.delete('Sheet1'); // Remove default sheet
      return await _saveExcelFile(excel, 'choir_overview_report');
    } catch (e, stackTrace) {
      Logger.error('Error exporting overview to Excel', e, stackTrace);
      return null;
    }
  }

  // Export QR codes for all choir members to PDF
  Future<String?> exportMemberQRCodesToPDF({
    required List<Map<String, dynamic>> members,
    required String choirName,
  }) async {
    try {
      final pdf = pw.Document();

      // Split members into groups of 6 per page (2x3 grid)
      const membersPerPage = 6;
      final pageCount = (members.length / membersPerPage).ceil();

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final startIndex = pageIndex * membersPerPage;
        final endIndex = (startIndex + membersPerPage < members.length)
            ? startIndex + membersPerPage
            : members.length;
        final pageMembers = members.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  // Page header
                  pw.Text(
                    '$choirName - Member QR Codes',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // QR codes grid
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: pageMembers.map((member) {
                      final userData = member['users'] ?? {};
                      final fullName = userData['full_name'] ?? 'Unknown';
                      final regNumber = member['registration_number'] ?? '';

                      return pw.Container(
                        width: 250,
                        height: 300,
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              fullName,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.Text(
                              'Reg: $regNumber',
                              style: const pw.TextStyle(fontSize: 10),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.SizedBox(height: 10),
                            // QR Code placeholder (would need actual QR generation)
                            pw.Container(
                              width: 150,
                              height: 150,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'QR Code\n$regNumber',
                                  textAlign: pw.TextAlign.center,
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Scan for attendance',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        );
      }

      return await _savePdfFile(pdf, 'member_qr_codes');
    } catch (e, stackTrace) {
      Logger.error('Error exporting QR codes to PDF', e, stackTrace);
      return null;
    }
  }

  // Export report data to CSV
  Future<String?> exportReportToCSV(
    Map<String, dynamic> reportData,
    String reportType,
  ) async {
    try {
      String csvContent = '';

      switch (reportType) {
        case 'membership':
          csvContent = _generateMembershipCSV(reportData);
          break;
        case 'attendance':
          csvContent = _generateAttendanceCSV(reportData);
          break;
        case 'financial':
          csvContent = _generateFinancialCSV(reportData);
          break;
        case 'overview':
        case 'comprehensive':
        case 'choir_overview':
          csvContent = _generateOverviewCSV(reportData);
          break;
        default:
          throw Exception('Unsupported report type: $reportType');
      }

      return await _saveCSVFile(csvContent, '${reportType}_report');
    } catch (e, stackTrace) {
      Logger.error('Error exporting $reportType to CSV', e, stackTrace);
      return null;
    }
  }

  String _generateMembershipCSV(Map<String, dynamic> data) {
    final members = data['members'] as List<Map<String, dynamic>>? ?? [];
    final csv = StringBuffer();

    // Header
    csv.writeln(
      'Registration Number,Full Name,Email,Phone,Status,Join Date,Outstanding Fees,Total Paid',
    );

    // Data rows
    for (final member in members) {
      final userData = member['users'] ?? {};
      csv.writeln(
        [
          member['registration_number'] ?? '',
          userData['full_name'] ?? '',
          userData['email'] ?? '',
          userData['phone_number'] ?? '',
          member['status'] ?? '',
          member['join_date'] ?? '',
          member['outstanding_fees'] ?? 0,
          member['total_paid'] ?? 0,
        ].join(','),
      );
    }

    return csv.toString();
  }

  String _generateAttendanceCSV(Map<String, dynamic> data) {
    final memberAttendance =
        data['member_attendance'] as Map<String, dynamic>? ?? {};
    final csv = StringBuffer();

    // Header
    csv.writeln(
      'Member Name,Registration Number,Total Sessions,Present,Late,Absent,Attendance Rate',
    );

    // Data rows
    memberAttendance.forEach((memberId, attendance) {
      final memberData = attendance['member_data'] ?? {};
      final userData = memberData['users'] ?? {};

      csv.writeln(
        [
          userData['full_name'] ?? '',
          memberData['registration_number'] ?? '',
          attendance['total_sessions'] ?? 0,
          attendance['present'] ?? 0,
          attendance['late'] ?? 0,
          attendance['absent'] ?? 0,
          '${(attendance['attendance_rate'] ?? 0).toStringAsFixed(1)}%',
        ].join(','),
      );
    });

    return csv.toString();
  }

  String _generateFinancialCSV(Map<String, dynamic> data) {
    final payments = data['payments'] as List<Map<String, dynamic>>? ?? [];
    final csv = StringBuffer();

    // Header
    csv.writeln(
      'Payment Date,Member Name,Registration Number,Amount,Type,Method,Status,Reference',
    );

    // Data rows
    for (final payment in payments) {
      final memberData = payment['choir_members'] ?? {};
      final userData = memberData['users'] ?? {};

      csv.writeln(
        [
          payment['payment_date'] ?? '',
          userData['full_name'] ?? '',
          memberData['registration_number'] ?? '',
          payment['amount'] ?? 0,
          payment['type'] ?? '',
          payment['method'] ?? '',
          payment['status'] ?? '',
          payment['reference'] ?? '',
        ].join(','),
      );
    }

    return csv.toString();
  }

  String _generateOverviewCSV(Map<String, dynamic> data) {
    final csv = StringBuffer();
    final choirInfo = data['choir_info'] ?? {};
    final membership = data['membership'] ?? {};
    final attendance = data['attendance'] ?? {};
    final financial = data['financial'] ?? {};

    // Choir Information
    csv.writeln('Choir Overview Report');
    csv.writeln('Choir Name,${choirInfo['name'] ?? ''}');
    csv.writeln('Generated At,${data['generated_at'] ?? ''}');
    csv.writeln('');

    // Summary Data
    csv.writeln('Category,Metric,Value');
    csv.writeln('Membership,Total Members,${membership['total_members'] ?? 0}');
    csv.writeln(
      'Membership,Active Members,${membership['active_members'] ?? 0}',
    );
    csv.writeln(
      'Membership,Inactive Members,${membership['inactive_members'] ?? 0}',
    );
    csv.writeln(
      'Attendance,Average Attendance Rate,${(attendance['avg_attendance_rate'] ?? 0).toStringAsFixed(1)}%',
    );
    csv.writeln(
      'Financial,Total Revenue,${financial['completed_amount'] ?? 0}',
    );
    csv.writeln(
      'Financial,Outstanding Amount,${financial['total_outstanding'] ?? 0}',
    );
    csv.writeln(
      'Financial,Collection Rate,${(financial['collection_rate'] ?? 0).toStringAsFixed(1)}%',
    );

    return csv.toString();
  }

  // Helper method to save CSV file
  Future<String> _saveCSVFile(String content, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fullFileName = '${fileName}_$timestamp.csv';
    final bytes = Uint8List.fromList(content.codeUnits);

    if (kIsWeb) {
      _downloadFileOnWeb(bytes, fullFileName);
      return 'Downloaded: $fullFileName';
    }

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/$fullFileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // Clean up old export files (older than 7 days)
  Future<void> cleanupOldExports() async {
    if (kIsWeb) {
      // No cleanup needed for web downloads
      return;
    }

    try {
      final output = await getApplicationDocumentsDirectory();
      final directory = Directory(output.path);
      final files = directory.listSync();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      for (final file in files) {
        if (file is File &&
            (file.path.endsWith('.pdf') ||
                file.path.endsWith('.xlsx') ||
                file.path.endsWith('.csv'))) {
          final stat = file.statSync();
          if (stat.modified.isBefore(cutoffDate)) {
            try {
              await file.delete();
              Logger.info('Deleted old export file: ${file.path}');
            } catch (e) {
              Logger.warning('Failed to delete old export file: ${file.path}');
            }
          }
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Error cleaning up old export files', e, stackTrace);
    }
  }

  // Export session attendance to PDF
  Future<String?> exportSessionAttendanceToPDF(
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final pdf = pw.Document();
      final session = sessionData['session'] as Map<String, dynamic>;
      final attendance = sessionData['attendance'] as List<dynamic>;
      final statistics = sessionData['statistics'] as Map<String, dynamic>;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Session Attendance Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      session['title'] ?? 'Unnamed Session',
                      style: const pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Session Info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Session Information',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Date: ${session['date']}'),
                        pw.Text('Time: ${session['start_time']}'),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Type: ${session['event_type']}'),
                        pw.Text(
                          'Grace Period: ${session['grace_minutes']} min',
                        ),
                      ],
                    ),
                    if (session['description']?.isNotEmpty == true)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Text(
                          'Description: ${session['description']}',
                        ),
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Statistics
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Attendance Statistics',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text(
                              '${statistics['present']}',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Present',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text(
                              '${statistics['late']}',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Late',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text(
                              '${statistics['absent']}',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Absent',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text(
                              '${statistics['attendance_rate']}%',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Rate',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Attendance Table
              pw.Text(
                'Member Attendance',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Member Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Registration',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Status',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Check-in Time',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...attendance.map((record) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            record['member_name']?.toString() ?? '',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            record['registration_number']?.toString() ?? '',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(record['status']?.toString() ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            record['check_in_time']?.toString().split('.')[0] ??
                                '',
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${sessionData['exported_at']?.toString().split('.')[0] ?? DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'session_attendance_${session['title']?.replaceAll(' ', '_') ?? 'report'}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        _downloadFileOnWeb(bytes, fileName);
        return fileName;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);

        return file.path;
      }
    } catch (e, stackTrace) {
      Logger.error('Error exporting session attendance to PDF', e, stackTrace);
      return null;
    }
  }

  // Export session attendance to CSV
  Future<String?> exportSessionAttendanceToCSV(
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final session = sessionData['session'] as Map<String, dynamic>;
      final attendance = sessionData['attendance'] as List<dynamic>;
      final statistics = sessionData['statistics'] as Map<String, dynamic>;

      final csvData = StringBuffer();

      // Header information
      csvData.writeln('Session Attendance Report');
      csvData.writeln('Session Title,${session['title']}');
      csvData.writeln('Date,${session['date']}');
      csvData.writeln('Start Time,${session['start_time']}');
      csvData.writeln('Event Type,${session['event_type']}');
      csvData.writeln('Grace Period,${session['grace_minutes']} minutes');
      if (session['description']?.isNotEmpty == true) {
        csvData.writeln('Description,"${session['description']}"');
      }
      csvData.writeln();

      // Statistics
      csvData.writeln('Attendance Statistics');
      csvData.writeln('Total Members,${statistics['total_members']}');
      csvData.writeln('Present,${statistics['present']}');
      csvData.writeln('Late,${statistics['late']}');
      csvData.writeln('Absent,${statistics['absent']}');
      csvData.writeln('Attendance Rate,${statistics['attendance_rate']}%');
      csvData.writeln();

      // Member attendance data
      csvData.writeln(
        'Member Name,Registration Number,Email,Status,Check-in Time,Notes',
      );

      for (final record in attendance) {
        csvData.writeln(
          [
            '"${record['member_name'] ?? ''}"',
            '"${record['registration_number'] ?? ''}"',
            '"${record['email'] ?? ''}"',
            record['status'] ?? '',
            record['check_in_time'] ?? '',
            '"${record['notes'] ?? ''}"',
          ].join(','),
        );
      }

      csvData.writeln();
      csvData.writeln(
        'Generated on,${sessionData['exported_at']?.toString().split('.')[0] ?? DateTime.now().toString().split('.')[0]}',
      );

      final fileName =
          'session_attendance_${session['title']?.replaceAll(' ', '_') ?? 'report'}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final bytes = utf8.encode(csvData.toString());

      if (kIsWeb) {
        _downloadFileOnWeb(bytes, fileName);
        return fileName;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvData.toString());

        return file.path;
      }
    } catch (e, stackTrace) {
      Logger.error('Error exporting session attendance to CSV', e, stackTrace);
      return null;
    }
  }

  // Platform-specific download function
  void _downloadFileOnWeb(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      // Create a data URL and trigger download
      final base64Data = base64Encode(bytes);
      final mimeType = fileName.endsWith('.pdf')
          ? 'application/pdf'
          : fileName.endsWith('.xlsx')
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'text/csv';
      // Use platform-specific download implementation
      platform.PlatformExport.downloadFile(base64Data, fileName, mimeType);
    }
  }
}
