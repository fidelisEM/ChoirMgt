import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/member_controller.dart';
import '../../models/models.dart';
import '../../services/export_service.dart';
import '../../utils/app_translations.dart';
import '../../utils/helpers.dart';
import '../qr_scanner_screen.dart';

class SessionDetailScreen extends StatefulWidget {

  const SessionDetailScreen({
    super.key,
    required this.session,
  });
  final AttendanceSessionModel session;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessionData();
    });
  }

  void _loadSessionData() async {
    try {
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      final memberController = Provider.of<MemberController>(context, listen: false);
      
      // Ensure member data is loaded first
      if (memberController.membersWithUserInfo.isEmpty) {
        await memberController.loadChoirMembers(widget.session.choirId);
      }
      
      // Then select the session and load attendance records
      await attendanceController.selectSession(widget.session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('attFailedLoadSessionData')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.title,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              _formatSessionDateTime(widget.session),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AuthController>(
            builder: (context, authController, child) {
              if (!authController.isChoirLeader || !widget.session.isActive) {
                return const SizedBox.shrink();
              }
              
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'qr_scan':
                      _openQRScanner();
                      break;
                    case 'bulk_present':
                      _markAllAs(AttendanceStatus.present);
                      break;
                    case 'bulk_absent':
                      _markAllAs(AttendanceStatus.absent);
                      break;
                    case 'export':
                      _exportAttendance();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'qr_scan',
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(context.tr('attQrCodeScanner')),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'bulk_present',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(context.tr('attMarkAllPresent')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'bulk_absent',
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(context.tr('attMarkAllAbsent')),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        const Icon(Icons.download),
                        const SizedBox(width: 8),
                        Text(context.tr('attExportData')),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer3<AttendanceController, MemberController, AuthController>(
        builder: (context, attendanceController, memberController, authController, child) {
          if (attendanceController.isLoading || memberController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle error states
          if (attendanceController.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('attErrorLoadingData'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    attendanceController.errorMessage!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadSessionData(),
                    child: Text(context.tr('retry')),
                  ),
                ],
              ),
            );
          }

          // Handle case where members list is empty
          if (memberController.membersWithUserInfo.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('attNoMembersFound'),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('attAddMembersPrompt'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final members = memberController.membersWithUserInfo
              .where((member) => 
                  _searchQuery.isEmpty ||
                  (member['users']?['full_name']?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
                  (member['registration_number']?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase())
              )
              .toList();

          return Column(
            children: [
              // Session Info Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getEventTypeColor(widget.session.eventType).withAlpha(50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getEventTypeIcon(widget.session.eventType),
                              color: _getEventTypeColor(widget.session.eventType),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.session.eventType.toString().split('.').last.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                if (widget.session.description?.isNotEmpty ?? false)
                                  Text(
                                    widget.session.description!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.session.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context.tr('active').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildAttendanceStats(attendanceController, members),
                    ],
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.tr('attSearchMembersHint'),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Members List
              Expanded(
                child: members.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('attNoMembersFoundFiltered'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final attendanceRecord = attendanceController
                              .getAttendanceRecord(member['id']);
                          
                          return _buildMemberAttendanceCard(
                            member,
                            attendanceRecord,
                            authController.isChoirLeader && widget.session.isActive,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttendanceStats(AttendanceController attendanceController, List<Map<String, dynamic>> members) {
    final records = attendanceController.currentSessionRecords;
    
    // Deduplicate records by member ID to ensure accurate counts
    final uniqueRecords = <String, AttendanceRecordModel>{};
    for (final record in records) {
      uniqueRecords[record.memberId] = record;
    }
    final deduplicatedRecords = uniqueRecords.values.toList();
    
    final present = deduplicatedRecords.where((r) => r.status == AttendanceStatus.present).length;
    final late = deduplicatedRecords.where((r) => r.status == AttendanceStatus.late).length;
    final absent = deduplicatedRecords.where((r) => r.status == AttendanceStatus.absent).length;
    final totalMembers = members.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            context.tr('attPresent'),
            present.toString(),
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            context.tr('attLate'),
            late.toString(),
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            context.tr('attAbsent'),
            absent.toString(),
            Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            context.tr('attTotal'),
            totalMembers.toString(),
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAttendanceCard(
    Map<String, dynamic> member,
    AttendanceRecordModel? attendanceRecord,
    bool canEdit,
  ) {
    AttendanceStatus? currentStatus;
    DateTime? checkInTime;
    
    if (attendanceRecord != null) {
      currentStatus = attendanceRecord.status;
      checkInTime = attendanceRecord.checkInTime;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _getInitials(member),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMemberName(member),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _getMemberRegistration(member),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (checkInTime != null)
                    Text(
                      '${context.tr('attCheckedInPrefix')} ${_formatTime(checkInTime)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (currentStatus != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(currentStatus).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentStatus.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(currentStatus),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (canEdit) ...[
              const SizedBox(width: 8),
              PopupMenuButton<AttendanceStatus>(
                onSelected: (status) => _markAttendance(member, status),
                child: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: AttendanceStatus.present,
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('attPresent')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: AttendanceStatus.late,
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('attLate')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: AttendanceStatus.absent,
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('attAbsent')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _markAttendance(Map<String, dynamic> member, AttendanceStatus status) async {
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    final authController = Provider.of<AuthController>(context, listen: false);
    
    final existingRecord = attendanceController.getAttendanceRecord(member['id']);
    
    if (existingRecord != null) {
      await attendanceController.updateAttendanceRecord(
        recordId: existingRecord.id,
        sessionId: widget.session.id,
        status: status,
        checkInTime: status != AttendanceStatus.absent ? DateTime.now() : null,
      );
    } else {
      await attendanceController.recordAttendance(
        sessionId: widget.session.id,
        memberId: member['id'],
        userId: member['user_id'],
        status: status,
        recordedBy: authController.currentUser!.id,
        checkInTime: status != AttendanceStatus.absent ? DateTime.now() : null,
      );
    }
  }

  void _markAllAs(AttendanceStatus status) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('${context.tr('attMarkAll')} ${status.toString().split('.').last.toUpperCase()}'),
        content: Text('${context.tr('attConfirmMarkAllPrefix')} ${status.toString().split('.').last}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final memberController = Provider.of<MemberController>(context, listen: false);
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      final authController = Provider.of<AuthController>(context, listen: false);

      final memberAttendance = <String, AttendanceStatus>{};
      for (final member in memberController.membersWithUserInfo) {
        memberAttendance[member['id']] = status;
      }

      final memberIds = memberController.membersWithUserInfo.map<String>((m) => m['id'] as String).toList();
      
      final success = await attendanceController.bulkRecordAttendance(
        sessionId: widget.session.id,
        status: status,
        memberIds: memberIds,
        recordedBy: authController.currentUser!.id,
      );

      if (!mounted) return;
      if (success) {
        Get.snackbar(
          context.tr('attSuccessTitle'),
          context.tr('attRecordedAllMembers'),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    }
  }

  void _exportAttendance() {
    _showExportOptions();
  }

  void _showExportOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('attExportSessionTitle'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('attChooseExportFormatPrefix')} "${widget.session.title}"',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // PDF Export Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
              title: Text(context.tr('attExportAsPdf')),
              subtitle: Text(context.tr('attPdfDescription')),
              onTap: () {
                Get.back();
                _exportSessionToPDF();
              },
            ),

            // CSV Export Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart, color: Colors.green),
              ),
              title: Text(context.tr('attExportAsCsv')),
              subtitle: Text(context.tr('attCsvDescription')),
              onTap: () {
                Get.back();
                _exportSessionToCSV();
              },
            ),
            
            const SizedBox(height: 10),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportSessionToPDF() async {
    try {
      final memberController = Provider.of<MemberController>(context, listen: false);
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      
      // Show loading
      Get.dialog(
        AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(context.tr('attGeneratingPdf')),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Prepare session data for export
      final sessionData = await _prepareSessionDataForExport(
        memberController,
        attendanceController
      );

      final exportService = ExportService();
      final filePath = await exportService.exportSessionAttendanceToPDF(sessionData);

      Get.back(); // Close loading dialog

      if (!mounted) return;
      if (filePath != null) {
        Helpers.showSuccessSnackbar(context.tr('attPdfExportedSuccess'));
        _showExportSuccessDialog(filePath, 'PDF');
      } else {
        Helpers.showErrorSnackbar(context.tr('attFailedExportPdf'));
      }
    } catch (e) {
      Get.back(); // Close loading dialog if open
      if (!mounted) return;
      Helpers.showErrorSnackbar('${context.tr('attErrorExportingPdfPrefix')}: $e');
    }
  }

  Future<void> _exportSessionToCSV() async {
    try {
      final memberController = Provider.of<MemberController>(context, listen: false);
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      
      // Show loading
      Get.dialog(
        AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(context.tr('attGeneratingCsv')),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Prepare session data for export
      final sessionData = await _prepareSessionDataForExport(
        memberController,
        attendanceController
      );

      final exportService = ExportService();
      final filePath = await exportService.exportSessionAttendanceToCSV(sessionData);

      Get.back(); // Close loading dialog

      if (!mounted) return;
      if (filePath != null) {
        Helpers.showSuccessSnackbar(context.tr('attCsvExportedSuccess'));
        _showExportSuccessDialog(filePath, 'CSV');
      } else {
        Helpers.showErrorSnackbar(context.tr('attFailedExportCsv'));
      }
    } catch (e) {
      Get.back(); // Close loading dialog if open
      if (!mounted) return;
      Helpers.showErrorSnackbar('${context.tr('attErrorExportingCsvPrefix')}: $e');
    }
  }

  Future<Map<String, dynamic>> _prepareSessionDataForExport(
    MemberController memberController,
    AttendanceController attendanceController,
  ) async {
    final members = memberController.membersWithUserInfo;
    final records = attendanceController.currentSessionRecords;
    
    // Combine member and attendance data
    final attendanceList = <Map<String, dynamic>>[];
    
    for (final member in members) {
      final attendanceRecord = records.firstWhere(
        (record) => record.memberId == member['id'],
        orElse: () => AttendanceRecordModel(
          id: '',
          sessionId: widget.session.id,
          memberId: member['id'],
          userId: member['user_id'] ?? '',
          status: AttendanceStatus.absent,
          recordedAt: DateTime.now(),
          recordedBy: '',
        ),
      );

      attendanceList.add({
        'member_name': _getMemberName(member),
        'registration_number': _getMemberRegistration(member),
        'email': member['users']?['email'] ?? '',
        'status': attendanceRecord.status.toString().split('.').last.toUpperCase(),
        'check_in_time': attendanceRecord.checkInTime?.toString() ?? '',
        'notes': attendanceRecord.notes ?? '',
      });
    }

    // Calculate stats
    final present = records.where((r) => r.status == AttendanceStatus.present).length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;
    final absent = records.where((r) => r.status == AttendanceStatus.absent).length;
    final notMarked = members.length - records.length;

    return {
      'session': {
        'title': widget.session.title,
        'date': _formatDate(widget.session.date),
        'start_time': _formatTime(widget.session.startTime),
        'event_type': widget.session.eventType.toString().split('.').last.toUpperCase(),
        'description': widget.session.description ?? '',
        'grace_minutes': widget.session.graceMinutes,
      },
      'attendance': attendanceList,
      'statistics': {
        'total_members': members.length,
        'present': present,
        'late': late,
        'absent': absent + notMarked,
        'attendance_rate': members.isNotEmpty 
          ? ((present + late) / members.length * 100).toStringAsFixed(1)
          : '0.0',
      },
      'exported_at': DateTime.now().toString(),
    };
  }

  void _showExportSuccessDialog(String filePath, String format) {
    Get.dialog(
      AlertDialog(
        title: Text(context.tr('attExportSuccessfulTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$format ${context.tr('attFileExportedSuccess')}'),
            const SizedBox(height: 10),
            Text(
              '${context.tr('attLocationPrefix')} $filePath',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('attOk')),
          ),
        ],
      ),
    );
  }

  IconData _getEventTypeIcon(EventType eventType) {
    switch (eventType) {
      case EventType.rehearsal:
        return Icons.music_note;
      case EventType.service:
        return Icons.church;
      case EventType.meeting:
        return Icons.meeting_room;
      case EventType.other:
        return Icons.event;
    }
  }

  Color _getEventTypeColor(EventType eventType) {
    switch (eventType) {
      case EventType.rehearsal:
        return Colors.blue;
      case EventType.service:
        return Colors.purple;
      case EventType.meeting:
        return Colors.orange;
      case EventType.other:
        return Colors.grey;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
    }
  }

  String _formatSessionDateTime(AttendanceSessionModel session) {
    return '${_formatDate(session.date)} at ${_formatTime(session.startTime)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _openQRScanner() async {
    final result = await Get.to(() => QRScannerScreen(
      choirId: widget.session.choirId,
      sessionId: widget.session.id,
    ));
    
    if (result == true && mounted) {
      // Reload the attendance data after successful scan
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      attendanceController.selectSession(widget.session);
    }
  }

  // Helper methods for safe data access
  String _getInitials(Map<String, dynamic> member) {
    final fullName = member['users']?['full_name'] as String?;
    if (fullName != null && fullName.isNotEmpty) {
      final nameParts = fullName.trim().split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        return nameParts[0][0].toUpperCase();
      }
    }
    return 'M';
  }

  String _getMemberName(Map<String, dynamic> member) {
    return member['users']?['full_name'] as String? ?? context.tr('attUnknownMember');
  }

  String _getMemberRegistration(Map<String, dynamic> member) {
    final registration = member['registration_number'] as String?;
    return registration?.isNotEmpty == true ? registration! : context.tr('attNoRegistration');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}