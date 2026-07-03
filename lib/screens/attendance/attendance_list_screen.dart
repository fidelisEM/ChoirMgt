import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../models/models.dart';
import 'create_session_screen.dart';
import 'session_detail_screen.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceSessions();
    });
  }

  void _loadAttendanceSessions() {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    if (choirController.selectedChoir != null) {
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      attendanceController.loadAttendanceSessions(choirId: choirController.selectedChoir!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(),
          ),
        ],
      ),
      body: Consumer3<AttendanceController, AuthController, ChoirController>(
        builder: (context, attendanceController, authController, choirController, child) {
          final selectedChoir = choirController.selectedChoir;
          
          if (selectedChoir == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No Choir Selected'),
                  Text('Please select a choir from the Choirs tab first'),
                ],
              ),
            );
          }

          if (attendanceController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (attendanceController.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading attendance',
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
                    onPressed: () {
                      attendanceController.clearError();
                      _loadAttendanceSessions();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final sessions = attendanceController.sessions;
          final stats = attendanceController.attendanceStats;

          return Column(
            children: [
              // Statistics Bar
              if (stats.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Sessions', stats['total_sessions']?.toString() ?? '0', Colors.blue),
                      _buildStatItem('Present', stats['present_count']?.toString() ?? '0', Colors.green),
                      _buildStatItem('Absent', stats['absent_count']?.toString() ?? '0', Colors.red),
                      _buildStatItem(
                        'Rate', 
                        '${(stats['attendance_rate'] ?? 0.0).toStringAsFixed(1)}%', 
                        Colors.orange
                      ),
                    ],
                  ),
                ),

              // Sessions List
              Expanded(
                child: sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance sessions',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create your first attendance session',
                              style: TextStyle(color: Colors.grey),
                            ),
                            if (authController.isChoirLeader) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _createAttendanceSession(selectedChoir.id),
                                icon: const Icon(Icons.add),
                                label: const Text('Create Session'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadAttendanceSessions(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            return _buildSessionCard(session, authController);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer2<AuthController, ChoirController>(
        builder: (context, authController, choirController, child) {
          final selectedChoir = choirController.selectedChoir;
          if (selectedChoir == null || !authController.isChoirLeader) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: () => _createAttendanceSession(selectedChoir.id),
            tooltip: 'Create Attendance Session',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(AttendanceSessionModel session, AuthController authController) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openSessionDetails(session),
        borderRadius: BorderRadius.circular(12),
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
                      color: _getEventTypeColor(session.eventType).withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEventTypeIcon(session.eventType),
                      color: _getEventTypeColor(session.eventType),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatSessionDateTime(session),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (session.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (session.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(
                  session.description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.event,
                    label: session.eventType.toString().split('.').last.toUpperCase(),
                    color: _getEventTypeColor(session.eventType),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: '${session.graceMinutes}min grace',
                    color: Colors.blue,
                  ),
                  const Spacer(),
                  if (authController.isChoirLeader && session.isActive)
                    TextButton.icon(
                      onPressed: () => _endSession(session),
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('End'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
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

  String _formatSessionDateTime(AttendanceSessionModel session) {
    return '${_formatDate(session.date)} at ${_formatTime(session.startTime)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _createAttendanceSession(String choirId) {
    Get.to(() => CreateSessionScreen(choirId: choirId))?.then((_) {
      _loadAttendanceSessions();
    });
  }

  void _openSessionDetails(AttendanceSessionModel session) {
    Get.to(() => SessionDetailScreen(session: session))?.then((_) {
      _loadAttendanceSessions();
    });
  }

  void _endSession(AttendanceSessionModel session) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('End Session'),
        content: Text('Are you sure you want to end "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      final success = await attendanceController.endAttendanceSession(session.id);
      
      if (success) {
        Get.snackbar(
          'Success',
          'Session ended successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          attendanceController.errorMessage ?? 'Failed to end session',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _showStatistics() {
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    final stats = attendanceController.attendanceStats;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStatsRow('Total Sessions', stats['total_sessions']?.toString() ?? '0'),
            _buildStatsRow('Total Records', stats['total_records']?.toString() ?? '0'),
            _buildStatsRow('Present Count', stats['present_count']?.toString() ?? '0'),
            _buildStatsRow('Late Count', stats['late_count']?.toString() ?? '0'),
            _buildStatsRow('Absent Count', stats['absent_count']?.toString() ?? '0'),
            _buildStatsRow(
              'Attendance Rate',
              '${(stats['attendance_rate'] ?? 0.0).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}