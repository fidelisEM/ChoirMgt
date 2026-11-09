import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../models/models.dart';
import '../../theme/music_library_theme.dart';
import '../../utils/app_translations.dart';
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

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
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
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final authController = Provider.of<AuthController>(context, listen: false);

    // Initialize choir controller to restore persisted selection
    await choirController.initialize();

    // Load choirs for selection if not already loaded
    if (choirController.choirs.isEmpty) {
      await choirController.loadChoirs(userId: authController.currentUser?.id);
    }

    // If a choir is selected (either restored or already selected), load attendance data
    if (choirController.selectedChoir != null) {
      Logger.debug(
        'AttendanceScreen - Found selected choir: ${choirController.selectedChoir!.name}',
      );
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
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final attendanceController = Provider.of<AttendanceController>(
      context,
      listen: false,
    );

    if (choirController.selectedChoir != null) {
      Logger.debug(
        'AttendanceScreen - Loading attendance data for choir: ${choirController.selectedChoir!.name}',
      );
      await attendanceController.loadAttendanceSessions(
        choirId: choirController.selectedChoir!.id,
      );
      Logger.debug('AttendanceScreen - Attendance data loading completed');
    } else {
      Logger.debug(
        'AttendanceScreen - No choir selected, skipping attendance data load',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MusicLibraryColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: MusicLibraryColors.backgroundGradient,
        ),
        child: Consumer3<AttendanceController, ChoirController, AuthController>(
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
                          color: MusicLibraryColors.primary.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.people_alt,
                          size: 56,
                          color: MusicLibraryColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.tr('attSelectChoir'),
                        style: mlText(size: 22, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('attSelectChoirSubtitle'),
                        textAlign: TextAlign.center,
                        style: mlText(
                          size: 14,
                          color: MusicLibraryColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Choir Selection Dropdown
                      if (choirController.choirs.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: DropdownButtonFormField<ChoirModel>(
                            style: mlText(size: 14),
                            decoration: InputDecoration(
                              labelText: context.tr('attSelectChoirLabel'),
                              labelStyle: mlText(
                                size: 13,
                                color: MusicLibraryColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.group,
                                color: MusicLibraryColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: MusicLibraryColors.card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: MusicLibraryColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: MusicLibraryColors.border,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            hint: Text(context.tr('attChooseChoirHint')),
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
                                      style: mlText(
                                        size: 14,
                                        weight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    if (choir.description.isNotEmpty)
                                      Text(
                                        choir.description,
                                        style: mlText(
                                          size: 12,
                                          color:
                                              MusicLibraryColors.textSecondary,
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
                          context.tr('or'),
                          style: mlText(
                            size: 13,
                            color: MusicLibraryColors.textSecondary,
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
                        label: Text(context.tr('attBrowseAllChoirs')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MusicLibraryColors.primary,
                          side: const BorderSide(
                            color: MusicLibraryColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      if (choirController.choirs.isEmpty &&
                          !choirController.isLoading) ...[
                        const SizedBox(height: 16),
                        Text(
                          context.tr('attNoChoirsFound'),
                          textAlign: TextAlign.center,
                          style: mlText(
                            size: 13,
                            color: MusicLibraryColors.textSecondary,
                          ),
                        ),
                      ],

                      if (choirController.isLoading) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(
                          color: MusicLibraryColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('attLoadingChoirs'),
                          style: mlText(
                            size: 13,
                            color: MusicLibraryColors.textSecondary,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: MusicLibraryColors.card,
                    border: Border(
                      bottom: BorderSide(color: MusicLibraryColors.border),
                    ),
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
                                  context.tr('attTrackingTitle'),
                                  style: mlText(
                                    size: 20,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  attendanceController.sessions.isEmpty
                                      ? '${context.tr('attNoSessionsYetFor')} ${choirController.selectedChoir!.name}. ${context.tr('attStartFirstAttendance')}'
                                      : '${context.tr('attTrackManageFor')} ${choirController.selectedChoir!.name}',
                                  style: mlText(
                                    size: 13,
                                    color: MusicLibraryColors.textSecondary,
                                  ),
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
                                    color: MusicLibraryColors.success
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.refresh,
                                    color: MusicLibraryColors.success,
                                    size: 20,
                                  ),
                                ),
                                tooltip: context.tr('attRefreshData'),
                              ),
                              PopupMenuButton<String>(
                                tooltip: context.tr('attChoirOptions'),
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: MusicLibraryColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: MusicLibraryColors.primary,
                                    size: 20,
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  // Current choir info
                                  PopupMenuItem<String>(
                                    enabled: false,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr('attCurrentChoirLabel'),
                                          style: mlText(
                                            size: 12,
                                            color: MusicLibraryColors
                                                .textSecondary,
                                          ),
                                        ),
                                        Text(
                                          choirController.selectedChoir!.name,
                                          style: mlText(
                                            size: 14,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),

                                  // Switch choir option
                                  PopupMenuItem<String>(
                                    value: 'switch',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.swap_horiz, size: 20),
                                        const SizedBox(width: 8),
                                        Text(context.tr('attSwitchChoir')),
                                      ],
                                    ),
                                  ),

                                  // Browse all choirs
                                  PopupMenuItem<String>(
                                    value: 'browse',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.list, size: 20),
                                        const SizedBox(width: 8),
                                        Text(context.tr('attBrowseAllChoirs')),
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
                              context.tr('attOverallRate'),
                              attendanceController.attendanceRecords.isEmpty
                                  ? context.tr('attNoData')
                                  : '${attendanceController.getOverallAttendanceRate().toStringAsFixed(1)}%',
                              Icons.trending_up,
                              attendanceController.attendanceRecords.isEmpty
                                  ? MusicLibraryColors.textSecondary
                                  : MusicLibraryColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context.tr('thisMonth'),
                              _getThisMonthRate(attendanceController) == 0.0 &&
                                      attendanceController
                                          .attendanceRecords
                                          .isEmpty
                                  ? context.tr('attNoData')
                                  : '${_getThisMonthRate(attendanceController).toStringAsFixed(1)}%',
                              Icons.today,
                              _getThisMonthRate(attendanceController) == 0.0 &&
                                      attendanceController
                                          .attendanceRecords
                                          .isEmpty
                                  ? MusicLibraryColors.textSecondary
                                  : MusicLibraryColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context.tr('attSessionsLabel'),
                              attendanceController.sessions.isEmpty
                                  ? '0'
                                  : '${attendanceController.sessions.length}',
                              Icons.event,
                              attendanceController.sessions.isEmpty
                                  ? MusicLibraryColors.textSecondary
                                  : MusicLibraryColors.warning,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _takeAttendance(context),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: Text(
                              context.tr('takeAttendance'),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MusicLibraryColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                Get.to(() => const AttendanceExportScreen()),
                            icon: const Icon(Icons.file_download, size: 18),
                            label: Text(
                              context.tr('attExport'),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: MusicLibraryColors.textPrimary,
                              side: const BorderSide(
                                color: MusicLibraryColors.border,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: MusicLibraryColors.card,
                        border: Border.all(color: MusicLibraryColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 18,
                            color: MusicLibraryColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: mlText(size: 14),
                              decoration: InputDecoration(
                                hintText: context.tr('attSearchSessionsHint'),
                                hintStyle: mlText(
                                  size: 14,
                                  color: MusicLibraryColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Attendance Sessions List
                Expanded(
                  child: attendanceController.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: MusicLibraryColors.primary,
                          ),
                        )
                      : attendanceController.sessions.isEmpty
                      ? _buildEmptyState(authController.isChoirLeader)
                      : _buildFilteredSessionsList(attendanceController),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: mlText(size: 14, weight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            title,
            style: mlText(size: 10, color: MusicLibraryColors.textSecondary),
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
          const Icon(
            Icons.event_note,
            size: 56,
            color: MusicLibraryColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('attNoSessionsTitle'),
            style: mlText(size: 16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isLeader
                ? context.tr('attNoSessionsLeaderMsg')
                : context.tr('attNoSessionsMemberMsg'),
            style: mlText(size: 13, color: MusicLibraryColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (isLeader) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _takeAttendance(context),
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text(
                context.tr('attTakeFirstAttendance'),
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MusicLibraryColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
          session.eventType
              .toString()
              .split('.')
              .last
              .toLowerCase()
              .contains(query) ||
          _formatDate(session.date).contains(query);
    }).toList();

    if (filteredSessions.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 56,
              color: MusicLibraryColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('attNoMatchingSessions'),
              style: mlText(size: 16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('attTryAdjustingSearch'),
              style: mlText(size: 13, color: MusicLibraryColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      itemCount: filteredSessions.length,
      itemBuilder: (context, index) {
        final session = filteredSessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: MusicLibraryColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: MusicLibraryColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getSessionStatusColor(
                    session.isActive,
                  ).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.isActive ? Icons.radio_button_checked : Icons.event,
                  color: _getSessionStatusColor(session.isActive),
                  size: 20,
                ),
              ),
              title: Text(
                session.title,
                style: mlText(size: 14, weight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatDate(session.date)} at ${_formatTime(session.startTime)}',
                    style: mlText(
                      size: 12,
                      color: MusicLibraryColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${session.eventType.name} ${context.tr('attSessionSuffix')}',
                    style: mlText(
                      size: 12,
                      color: MusicLibraryColors.textSecondary,
                    ),
                  ),
                ],
              ),
              trailing: session.isActive
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MusicLibraryColors.success.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr('active').toUpperCase(),
                        style: mlText(
                          size: 10,
                          weight: FontWeight.bold,
                          color: MusicLibraryColors.success,
                        ),
                      ),
                    )
                  : PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: MusicLibraryColors.textSecondary,
                      ),
                      onSelected: (value) =>
                          _handleSessionAction(session, value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Text(context.tr('attViewDetails')),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(context.tr('edit')),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(context.tr('delete')),
                        ),
                      ],
                    ),
              isThreeLine: true,
              onTap: () => _viewSessionDetails(session),
            ),
          ),
        );
      },
    );
  }

  Color _getSessionStatusColor(bool isActive) {
    return isActive ? MusicLibraryColors.success : MusicLibraryColors.primary;
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
        Get.to(() => TakeAttendanceScreen(existingSession: session));
        break;
      case 'delete':
        _showDeleteConfirmation(session);
        break;
    }
  }

  void _showDeleteConfirmation(session) {
    Get.dialog(
      AlertDialog(
        backgroundColor: MusicLibraryColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          context.tr('attDeleteSessionTitle'),
          style: mlText(size: 17, weight: FontWeight.w700),
        ),
        content: Text(
          '${context.tr('attDeleteSessionConfirmPrefix')} ${session.title}?',
          style: mlText(size: 14),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: MusicLibraryColors.textSecondary,
            ),
            onPressed: () => Get.back(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _deleteSession(session);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MusicLibraryColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              context.tr('delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSession(session) async {
    final attendanceController = Provider.of<AttendanceController>(
      context,
      listen: false,
    );
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );

    if (choirController.selectedChoir == null) return;

    final success = await attendanceController.deleteAttendanceSession(
      session.id,
      choirController.selectedChoir!.id,
    );

    if (!mounted) return;
    if (success) {
      Get.snackbar(
        context.tr('attSessionDeletedTitle'),
        context.tr('attSessionDeletedMsg'),
        backgroundColor: MusicLibraryColors.success,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        context.tr('error'),
        context.tr('attFailedDeleteSession'),
        backgroundColor: MusicLibraryColors.danger,
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

    final presentCount = thisMonthRecords
        .where(
          (record) =>
              record.status == AttendanceStatus.present ||
              record.status == AttendanceStatus.late,
        )
        .length;

    return (presentCount / thisMonthRecords.length) * 100;
  }
}
