import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/choir_controller.dart';
import '../../models/models.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_widgets.dart';

class AttendanceManagementScreen extends StatefulWidget {
  
  const AttendanceManagementScreen({
    super.key,
    required this.choir,
  });
  final ChoirModel choir;

  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<ChoirMemberModel> _members = [];
  List<AttendanceModel> _attendanceRecords = [];
  DateTime _selectedDate = DateTime.now();
  String _selectedEvent = 'Sunday Service';
  final Map<String, bool> _attendance = {};
  bool _isLoading = false;

  final List<String> _eventTypes = [
    'Sunday Service',
    'Practice Session',
    'Special Event',
    'Wedding',
    'Funeral',
    'Conference',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final choirController = Provider.of<ChoirController>(context, listen: false);
    await choirController.selectChoir(widget.choir);
    
    _members = choirController.choirMembers;
    _attendanceRecords = await _attendanceService.getChoirAttendance(widget.choir.id);
    
    // Initialize attendance map
    for (var member in _members) {
      _attendance[member.id] = false;
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.choir.name} - Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showAttendanceHistory(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildEventDetails(),
                _buildQuickStats(),
                Expanded(child: _buildMembersList()),
                _buildActionButtons(),
              ],
            ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return GlassCard(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.event, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Event Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedEvent,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.event_note, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _eventTypes.map((event) => 
                      DropdownMenuItem(value: event, child: Text(event))
                    ).toList(),
                    onChanged: (value) {
                      setState(() => _selectedEvent = value ?? 'Sunday Service');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final present = _attendance.values.where((present) => present).length;
    final total = _members.length;
    final percentage = total > 0 ? ((present / total) * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      present.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const Text('Present', style: TextStyle(color: AppColors.gray600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      (total - present).toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const Text('Absent', style: TextStyle(color: AppColors.gray600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getPercentageColor(percentage),
                      ),
                    ),
                    const Text('Rate', style: TextStyle(color: AppColors.gray600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Mark Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _markAllPresent,
                child: const Text('Mark All Present'),
              ),
              TextButton(
                onPressed: _markAllAbsent,
                child: const Text('Mark All Absent'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                return _buildMemberAttendanceCard(_members[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAttendanceCard(ChoirMemberModel member) {
    final isPresent = _attendance[member.id] ?? false;
    
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPresent ? AppColors.success : AppColors.gray400,
          child: Text(
            member.registrationNumber.length > 3 
                ? member.registrationNumber.substring(member.registrationNumber.length - 2)
                : member.registrationNumber,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(member.userId),
        subtitle: Text('Reg: ${member.registrationNumber}'),
        trailing: Switch(
          value: isPresent,
          onChanged: (value) {
            setState(() {
              _attendance[member.id] = value;
            });
          },
          activeThumbColor: AppColors.success,
        ),
        onTap: () {
          setState(() {
            _attendance[member.id] = !isPresent;
          });
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Save Attendance',
                  onPressed: _saveAttendance,
                  height: 48,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetAttendance,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _markAllPresent() {
    setState(() {
      for (var member in _members) {
        _attendance[member.id] = true;
      }
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var member in _members) {
        _attendance[member.id] = false;
      }
    });
  }

  void _resetAttendance() {
    setState(() {
      for (var member in _members) {
        _attendance[member.id] = false;
      }
    });
  }

  Future<void> _saveAttendance() async {
    try {
      setState(() => _isLoading = true);
      
      final attendanceList = _attendance.entries
          .map((entry) => AttendanceModel(
                id: '',
                sessionId: '',
                memberId: entry.key,
                userId: entry.key,
                choirId: widget.choir.id,
                eventDate: _selectedDate,
                status: entry.value ? AttendanceStatus.present : AttendanceStatus.absent,
                recordedBy: 'admin',
                recordedAt: DateTime.now(),
                notes: _selectedEvent,
              ))
          .toList();
      
      await _attendanceService.recordAttendance(attendanceList);
      
      Get.snackbar(
        'Success',
        'Attendance saved successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
      
      if (mounted) Navigator.of(context).pop();
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save attendance: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAttendanceHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Attendance History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _attendanceRecords.length,
                itemBuilder: (context, index) {
                  return _buildHistoryCard(_attendanceRecords[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(AttendanceModel record) {
    // For now, just show the record info without detailed breakdown
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.event,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.notes ?? 'Event',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${record.eventDate.day}/${record.eventDate.month}/${record.eventDate.year}',
                    style: const TextStyle(color: AppColors.gray500),
                  ),
                  Text(
                    '${record.status.toString().split('.').last} - ${record.recordedBy}',
                    style: const TextStyle(color: AppColors.gray600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: record.status == AttendanceStatus.present 
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record.status.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: record.status == AttendanceStatus.present 
                      ? AppColors.success 
                      : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}