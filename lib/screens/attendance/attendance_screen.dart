import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../utils/logger.dart';
import '../choirs/choir_list_screen.dart';
import 'attendance_export_screen.dart';
import 'session_detail_screen.dart';
import 'take_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  Future<void> _initializeControllers() async {
    Logger.debug('AttendanceScreen - initState called');
    final choirController = Provider.of<ChoirController>(context, listen: false);
    final authController = Provider.of<AuthController>(context, listen: false);
    
    // Initialize choir controller to restore persisted selection
    await choirController.initialize();
    
    // Load choirs for selection if not already loaded
    if (choirController.choirs.isEmpty) {
      await choirController.loadChoirs(userId: authController.currentUser?.id);
    }
    
    // If a choir is selected (either restored or already selected), load attendance data
    if (choirController.selectedChoir != null) {
      Logger.debug('AttendanceScreen - Found selected choir: ${choirController.selectedChoir!.name}');
      _loadAttendanceData();
    } else {
      Logger.debug('AttendanceScreen - No choir selected');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Logger.debug('AttendanceScreen - App resumed, reinitializing');
      // Reinitialize when app comes back to foreground
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeControllers();
      });
    }
  }

  void _loadAttendanceData() async {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    
    if (choirController.selectedChoir != null) {
      Logger.debug('AttendanceScreen - Loading attendance data for choir: ${choirController.selectedChoir!.name}');
      await attendanceController.loadAttendanceSessions(
        choirId: choirController.selectedChoir!.id,
      );
      Logger.debug('AttendanceScreen - Attendance data loading completed');
    } else {
      Logger.debug('AttendanceScreen - No choir selected, skipping attendance data load');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<AttendanceController, ChoirController, AuthController>(
        builder: (context, attendanceController, choirController, authController, child) {
          // Show choir selection if no choir is selected
          if (choirController.selectedChoir == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.people_alt,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Select a Choir',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a choir to view attendance records,\ntake attendance, and manage sessions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Choir Selection Dropdown
                    if (choirController.choirs.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: DropdownButtonFormField<ChoirModel>(
                          decoration: InputDecoration(
                            labelText: 'Select Choir',
                            prefixIcon: const Icon(Icons.group),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          hint: const Text('Choose a choir...'),
                          isExpanded: true,
                          items: choirController.choirs.map((choir) {
                            return DropdownMenuItem<ChoirModel>(
                              value: choir,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    choir.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  if (choir.description.isNotEmpty)
                                    Text(
                                      choir.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (ChoirModel? choir) async {
                            if (choir != null) {
                              await choirController.selectChoir(choir);
                              _loadAttendanceData();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Or',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Browse All Choirs Button
                    OutlinedButton.icon(
                      onPressed: () {
                        Get.to(() => const ChoirListScreen());
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('Browse All Choirs'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    if (choirController.choirs.isEmpty && !choirController.isLoading) ...[
                      const SizedBox(height: 16),
                      Text(
                        'No choirs found. You may need to join or create a choir first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    
                    if (choirController.isLoading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'Loading choirs...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Header
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Tracking',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                attendanceController.sessions.isEmpty 
                                  ? 'No attendance sessions yet for ${choirController.selectedChoir!.name}. Start by taking your first attendance!'
                                  : 'Track and manage attendance for ${choirController.selectedChoir!.name}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        // Quick Choir Switcher
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Refresh button
                            IconButton(
                              onPressed: () {
                                Logger.debug('Manual refresh triggered');
                                _initializeControllers();
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.refresh,
                                  color: AppColors.success,
                                ),
                              ),
                              tooltip: 'Refresh Data',
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Choir Options',
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: AppColors.primary,
                                ),
                              ),
                              itemBuilder: (context) => [
                            // Current choir info
                            PopupMenuItem<String>(
                              enabled: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Choir:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    choirController.selectedChoir!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            
                            // Switch choir option
                            const PopupMenuItem<String>(
                              value: 'switch',
                              child: Row(
                                children: [
                                  Icon(Icons.swap_horiz, size: 20),
                                  SizedBox(width: 8),
                                  Text('Switch Choir'),
                                ],
                              ),
                            ),
                            
                            // Browse all choirs
                            const PopupMenuItem<String>(
                              value: 'browse',
                              child: Row(
                                children: [
                                  Icon(Icons.list, size: 20),
                                  SizedBox(width: 8),
                                  Text('Browse All Choirs'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (String action) {
                            switch (action) {
                              case 'switch':
                                choirController.clearSelection();
                                break;
                              case 'browse':
                                Get.to(() => const ChoirListScreen());
                                break;
                            }
                          },
                        ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Overall Rate',
                            attendanceController.attendanceRecords.isEmpty ? 'No Data' : '${attendanceController.getOverallAttendanceRate().toStringAsFixed(1)}%',
                            Icons.trending_up,
                            attendanceController.attendanceRecords.isEmpty ? Colors.grey : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'This Month',
                            _getThisMonthRate(attendanceController) == 0.0 && attendanceController.attendanceRecords.isEmpty ? 'No Data' : '${_getThisMonthRate(attendanceController).toStringAsFixed(1)}%',
                            Icons.today,
                            _getThisMonthRate(attendanceController) == 0.0 && attendanceController.attendanceRecords.isEmpty ? Colors.grey : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Sessions',
                            attendanceController.sessions.isEmpty ? '0' : '${attendanceController.sessions.length}',
                            Icons.event,
                            attendanceController.sessions.isEmpty ? Colors.grey : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              if (authController.isChoirLeader) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _takeAttendance(context),
                          icon: const Icon(Icons.check_circle),
                          label: const Text(
                            'Take Attendance',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Get.to(() => const AttendanceExportScreen()),
                          icon: const Icon(Icons.file_download),
                          label: const Text(
                            'Export',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Search field
              if (attendanceController.sessions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search sessions...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Attendance Sessions List
              Expanded(
                child: attendanceController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : attendanceController.sessions.isEmpty
                        ? _buildEmptyState(authController.isChoirLeader)
                        : _buildFilteredSessionsList(attendanceController),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLeader) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Attendance Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLeader 
                ? 'Start by taking attendance for your first session'
                : 'Attendance sessions will appear here when available',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (isLeader) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _takeAttendance(context),
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'Take First Attendance',
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilteredSessionsList(AttendanceController controller) {
    final filteredSessions = controller.sessions.where((session) {
      if (_searchController.text.isEmpty) return true;
      
      final query = _searchController.text.toLowerCase();
      return session.title.toLowerCase().contains(query) ||
             session.eventType.toString().split('.').last.toLowerCase().contains(query) ||
             _formatDate(session.date).contains(query);
    }).toList();

    if (filteredSessions.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching sessions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSessions.length,
      itemBuilder: (context, index) {
        final session = filteredSessions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getSessionStatusColor(session.isActive).withAlpha(30),
              child: Icon(
                session.isActive ? Icons.radio_button_checked : Icons.event,
                color: _getSessionStatusColor(session.isActive),
              ),
            ),
            title: Text(session.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_formatDate(session.date)} at ${_formatTime(session.startTime)}'),
                Text('${session.eventType.name} session'),
              ],
            ),
            trailing: session.isActive
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) => _handleSessionAction(session, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Text('View Details')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
            isThreeLine: true,
            onTap: () => _viewSessionDetails(session),
          ),
        );
      },
    );
  }

  Color _getSessionStatusColor(bool isActive) {
    return isActive ? AppColors.success : AppColors.primary;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _takeAttendance(BuildContext context) {
    Get.to(() => const TakeAttendanceScreen());
  }

  void _viewSessionDetails(session) {
    Get.to(() => SessionDetailScreen(session: session));
  }

  void _handleSessionAction(session, String action) {
    switch (action) {
      case 'view':
        _viewSessionDetails(session);
        break;
      case 'edit':
        Get.to(() => TakeAttendanceScreen(
          existingSession: session,
        ));
        break;
      case 'delete':
        _showDeleteConfirmation(session);
        break;
    }
  }

  void _showDeleteConfirmation(session) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete the attendance session for ${session.title}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _deleteSession(session);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteSession(session) async {
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    if (choirController.selectedChoir == null) return;
    
    final success = await attendanceController.deleteAttendanceSession(
      session.id, 
      choirController.selectedChoir!.id
    );
    
    if (success) {
      Get.snackbar(
        'Session Deleted',
        'Attendance session has been deleted',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to delete session',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  double _getThisMonthRate(AttendanceController controller) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    final thisMonthRecords = controller.getAttendanceByDateRange(
      startOfMonth,
      endOfMonth,
    );
    
    if (thisMonthRecords.isEmpty) return 0.0;
    
    final presentCount = thisMonthRecords.where(
      (record) => record.status == AttendanceStatus.present || record.status == AttendanceStatus.late
    ).length;
    
    return (presentCount / thisMonthRecords.length) * 100;
  }
}