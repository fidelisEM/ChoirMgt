import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/member_controller.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
import '../../utils/logger.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key, this.sessionId, this.existingSession});
  final String? sessionId;
  final AttendanceSessionModel? existingSession;

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final _searchController = TextEditingController();
  final _sessionTitleController = TextEditingController();
  final _sessionDescriptionController = TextEditingController();

  EventType _selectedEventType = EventType.service;
  int _graceMinutes = 15;
  bool _isNewSession = true;
  AttendanceSessionModel? _currentSession;
  List<Map<String, dynamic>> _filteredMembers = [];
  final Map<String, AttendanceStatus> _attendanceStatus = {};
  bool _showOnlyUnmarked = false;

  @override
  void initState() {
    super.initState();
    _isNewSession = widget.sessionId == null && widget.existingSession == null;
    _currentSession = widget.existingSession;

    if (_currentSession != null) {
      _sessionTitleController.text = _currentSession!.title;
      _sessionDescriptionController.text = _currentSession!.description ?? '';
      _selectedEventType = _currentSession!.eventType;
      _graceMinutes = _currentSession!.graceMinutes;
    } else {
      _sessionTitleController.text =
          '${context.tr('attDefaultSessionTitlePrefix')} ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMembers();
    });
  }

  void _loadMembers() {
    final memberController = Provider.of<MemberController>(
      context,
      listen: false,
    );
    final allMembers = memberController.membersWithUserInfo;

    setState(() {
      _filteredMembers = allMembers
          .where((member) => (member['status'] ?? 'active') == 'active')
          .toList();

      // Initialize attendance status for all members
      for (final member in _filteredMembers) {
        _attendanceStatus[member['id'] ?? ''] = AttendanceStatus.absent;
      }
    });

    // Load existing attendance if editing existing session
    if (_currentSession != null) {
      _loadExistingAttendance();
    }
  }

  void _loadExistingAttendance() async {
    final attendanceController = Provider.of<AttendanceController>(
      context,
      listen: false,
    );
    await attendanceController.selectSession(_currentSession!);

    // Update attendance status based on existing records
    for (final record in attendanceController.currentSessionRecords) {
      if (_attendanceStatus.containsKey(record.memberId)) {
        setState(() {
          _attendanceStatus[record.memberId] = record.status;
        });
      }
    }
  }

  void _filterMembers(String query) {
    final memberController = Provider.of<MemberController>(
      context,
      listen: false,
    );
    final allMembers = memberController.membersWithUserInfo
        .where((member) => (member['status'] ?? 'active') == 'active')
        .toList();

    setState(() {
      if (query.isEmpty) {
        _filteredMembers = allMembers;
      } else {
        _filteredMembers = allMembers.where((member) {
          final fullName = member['full_name'] ?? '';
          final email = member['email'] ?? '';
          final regNumber = member['registration_number'] ?? '';
          return fullName.toLowerCase().contains(query.toLowerCase()) ||
              email.toLowerCase().contains(query.toLowerCase()) ||
              regNumber.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      if (_showOnlyUnmarked) {
        _filteredMembers = _filteredMembers
            .where(
              (member) =>
                  _attendanceStatus[member['id'] ?? ''] ==
                  AttendanceStatus.absent,
            )
            .toList();
      }
    });
  }

  void _toggleShowOnlyUnmarked() {
    setState(() {
      _showOnlyUnmarked = !_showOnlyUnmarked;
    });
    _filterMembers(_searchController.text);
  }

  void _markAttendance(String memberId, AttendanceStatus status) {
    setState(() {
      _attendanceStatus[memberId] = status;
    });
  }

  void _markAllPresent() {
    setState(() {
      for (final member in _filteredMembers) {
        _attendanceStatus[member['id'] ?? ''] = AttendanceStatus.present;
      }
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (final member in _filteredMembers) {
        _attendanceStatus[member['id'] ?? ''] = AttendanceStatus.absent;
      }
    });
  }

  int get _presentCount => _attendanceStatus.values
      .where((status) => status == AttendanceStatus.present)
      .length;
  int get _lateCount => _attendanceStatus.values
      .where((status) => status == AttendanceStatus.late)
      .length;
  int get _absentCount => _attendanceStatus.values
      .where((status) => status == AttendanceStatus.absent)
      .length;

  Future<void> _saveAttendance() async {
    final attendanceController = Provider.of<AttendanceController>(
      context,
      listen: false,
    );
    final memberController = Provider.of<MemberController>(
      context,
      listen: false,
    );
    final authController = Provider.of<AuthController>(context, listen: false);
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final trAttFailedCreateAttendanceSession = context.tr(
      'attFailedCreateAttendanceSession',
    ); // resolved before awaits
    final trAttFailedSaveAttendancePrefix = context.tr(
      'attFailedSaveAttendancePrefix',
    ); // resolved before awaits
    final trAttFailedSaveRecords = context.tr(
      'attFailedSaveRecords',
    ); // resolved before awaits
    final trAttRecordedSuccessMsg = context.tr(
      'attRecordedSuccessMsg',
    ); // resolved before awaits
    final trAttRecordsSavedSuffix = context.tr(
      'attRecordsSavedSuffix',
    ); // resolved before awaits
    final trAttSuccessTitle = context.tr(
      'attSuccessTitle',
    ); // resolved before awaits
    final trError = context.tr('error'); // resolved before awaits

    if (_sessionTitleController.text.trim().isEmpty) {
      Get.snackbar(
        context.tr('error'),
        context.tr('attEnterSessionTitleError'),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    // Get the actual choir ID from the selected choir
    final selectedChoir = choirController.selectedChoir;
    if (selectedChoir == null) {
      Get.snackbar(
        context.tr('error'),
        context.tr('attNoChoirSelectedError'),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    try {
      String sessionId;
      final choirId = selectedChoir.id;
      Logger.debug(
        'TakeAttendanceScreen - Using choir ID: $choirId for choir: ${selectedChoir.name}',
      );

      // Collect all members with their attendance status (not just filtered members)
      final allMembers = memberController.membersWithUserInfo
          .where((member) => (member['status'] ?? 'active') == 'active')
          .toList();

      if (_isNewSession) {
        // Create new session and get the session ID directly from the service
        final success = await attendanceController.createAttendanceSession(
          choirId: choirId,
          title: _sessionTitleController.text.trim(),
          leaderId: authController.currentUser!.id,
          eventType: _selectedEventType,
          description: _sessionDescriptionController.text.trim(),
          graceMinutes: _graceMinutes,
        );

        if (!success) {
          Get.snackbar(
            trError,
            trAttFailedCreateAttendanceSession,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          return;
        }

        final created = attendanceController.lastCreatedSession;
        if (created == null) return;
        sessionId = created.id;
      } else {
        sessionId = _currentSession!.id;
      }

      // Create attendance records for all active members
      final attendanceRecords = <AttendanceModel>[];
      final now = DateTime.now();

      for (int i = 0; i < allMembers.length; i++) {
        final member = allMembers[i];
        final memberId = member['id'] ?? '';
        final status = _attendanceStatus[memberId] ?? AttendanceStatus.absent;

        final attendanceRecord = AttendanceModel(
          id: '', // assigned a UUID by AttendanceService
          sessionId: sessionId,
          memberId: memberId,
          userId: member['user_id'] ?? '',
          choirId: choirId,
          eventDate: now,
          status: status,
          recordedBy: authController.currentUser!.id,
          recordedAt: now,
          notes: _sessionTitleController.text.trim(),
        );

        attendanceRecords.add(attendanceRecord);
      }

      // Debug: log what we're about to save
      Logger.debug(
        'About to save ${attendanceRecords.length} attendance records for session $sessionId',
      );
      for (final record in attendanceRecords.take(3)) {
        Logger.debug(
          'Record - Member: ${record.memberId}, Status: ${record.status}, Session: ${record.sessionId}',
        );
      }

      // Save all attendance records in batch using the original batch method
      final batchSuccess = await attendanceController.recordAttendanceBatch(
        attendanceRecords,
      );

      if (!batchSuccess) {
        Get.snackbar(
          trError,
          trAttFailedSaveRecords,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      Logger.info('Batch save completed successfully');

      Get.back();
      Get.snackbar(
        trAttSuccessTitle,
        '$trAttRecordedSuccessMsg ${attendanceRecords.length} $trAttRecordsSavedSuffix',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        trError,
        '$trAttFailedSaveAttendancePrefix: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNewSession
              ? context.tr('takeAttendance')
              : context.tr('attEditAttendanceTitle'),
        ),
        actions: [
          TextButton(
            onPressed: _saveAttendance,
            child: Text(
              context.tr('save'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AttendanceController>(
        builder: (context, attendanceController, child) {
          if (attendanceController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Session Details Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('attSessionDetailsHeading'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sessionTitleController,
                        decoration: InputDecoration(
                          labelText: context.tr('attSessionTitleLabel'),
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sessionDescriptionController,
                        decoration: InputDecoration(
                          labelText: context.tr('attDescriptionOptionalLabel'),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<EventType>(
                              initialValue: _selectedEventType,
                              decoration: InputDecoration(
                                labelText: context.tr('attEventTypeLabel'),
                                prefixIcon: const Icon(Icons.event),
                              ),
                              items: EventType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedEventType = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _graceMinutes.toString(),
                              decoration: InputDecoration(
                                labelText: context.tr('attGraceMinutesLabel'),
                                prefixIcon: const Icon(Icons.timer),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final minutes = int.tryParse(value);
                                if (minutes != null && minutes >= 0) {
                                  setState(() {
                                    _graceMinutes = minutes;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Stats
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context.tr('attPresent'),
                        _presentCount,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context.tr('attLate'),
                        _lateCount,
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context.tr('attAbsent'),
                        _absentCount,
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: context.tr('attSearchMembersHint'),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterMembers('');
                                },
                              )
                            : null,
                      ),
                      onChanged: _filterMembers,
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _markAllPresent,
                            icon: const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            label: Text(context.tr('attAllPresent')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _markAllAbsent,
                            icon: const Icon(
                              Icons.cancel,
                              color: AppColors.error,
                            ),
                            label: Text(context.tr('attAllAbsent')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _toggleShowOnlyUnmarked,
                          icon: Icon(
                            _showOnlyUnmarked
                                ? Icons.filter_alt
                                : Icons.filter_alt_outlined,
                            color: _showOnlyUnmarked
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                          tooltip: context.tr('attShowOnlyUnmarked'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Member List
              Expanded(
                child: _filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showOnlyUnmarked
                                  ? context.tr('attAllMembersMarked')
                                  : context.tr('attNoMembersFoundFiltered'),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          final memberId = member['id'] ?? '';
                          final status =
                              _attendanceStatus[memberId] ??
                              AttendanceStatus.absent;
                          final fullName =
                              member['full_name'] ??
                              context.tr('attUnknownMember');
                          final email = member['email'] ?? '';
                          final regNumber = member['registration_number'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 72),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(
                                    status,
                                  ).withAlpha(30),
                                  child: Text(
                                    fullName.isNotEmpty
                                        ? fullName[0].toUpperCase()
                                        : 'M',
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  fullName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (regNumber.isNotEmpty)
                                      Text(
                                        '${context.tr('attIdPrefix')} $regNumber',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    if (email.isNotEmpty)
                                      Text(
                                        email,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<AttendanceStatus>(
                                  onSelected: (newStatus) =>
                                      _markAttendance(memberId, newStatus),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: AttendanceStatus.present,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: AppColors.success,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(context.tr('attPresent')),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: AttendanceStatus.late,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.schedule,
                                            color: AppColors.warning,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(context.tr('attLate')),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: AttendanceStatus.absent,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.cancel,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(context.tr('attAbsent')),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        status,
                                      ).withAlpha(30),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getStatusIcon(status),
                                          size: 16,
                                          color: _getStatusColor(status),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          status.name.toUpperCase(),
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                isThreeLine: regNumber.isNotEmpty,
                              ),
                            ),
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

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color.withAlpha(180)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.absent:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.absent:
        return Icons.cancel;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sessionTitleController.dispose();
    _sessionDescriptionController.dispose();
    super.dispose();
  }
}
