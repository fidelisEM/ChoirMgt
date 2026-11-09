import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/report_controller.dart';
import '../../models/models.dart';
import '../../services/activity_service.dart';
import '../../services/export_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/music_library_theme.dart';
import '../../utils/app_translations.dart';
import '../../utils/logger.dart';
import '../../utils/responsive_utils.dart';
import '../members/edit_member_screen.dart';
import '../members/member_detail_screen.dart';
import '../messaging/message_screen.dart';
import '../reports/report_detail_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/choir_settings_screen.dart';
import 'edit_choir_screen.dart';

class ChoirDetailScreen extends StatefulWidget {
  const ChoirDetailScreen({super.key, required this.choir});
  final ChoirModel choir;

  @override
  State<ChoirDetailScreen> createState() => _ChoirDetailScreenState();
}

class _ChoirDetailScreenState extends State<ChoirDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();
  final Map<String, UserModel> _userCache = {};
  List<ActivityModel> _recentActivities = [];
  double _attendanceRate = 0.0;
  int _totalSessions = 0;

  // Members tab state
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final choirController = Provider.of<ChoirController>(
        context,
        listen: false,
      );
      choirController.selectChoir(widget.choir);
      _loadMemberUserData();
      _loadStatistics();
      _loadRecentActivities();
    });
  }

  Future<void> _loadMemberUserData() async {
    try {
      final choirController = Provider.of<ChoirController>(
        context,
        listen: false,
      );
      final members = choirController.choirMembers;

      for (var member in members) {
        if (member.userId.isNotEmpty &&
            !_userCache.containsKey(member.userId)) {
          // Try to get user from service
          final user = await _userService.getUserById(member.userId);
          if (user != null) {
            _userCache[member.userId] = user;
          } else {
            // Create sample user data if service fails (for local demo)
            _userCache[member.userId] = _createSampleUser(
              member.userId,
              member.registrationNumber,
            );
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently handle errors to avoid flooding console
      if (!mounted) return;
      final choirController = Provider.of<ChoirController>(
        context,
        listen: false,
      );
      final members = choirController.choirMembers;

      // Fallback: create sample users for all members
      for (var member in members) {
        if (member.userId.isNotEmpty &&
            !_userCache.containsKey(member.userId)) {
          _userCache[member.userId] = _createSampleUser(
            member.userId,
            member.registrationNumber,
          );
        }
      }
    }
  }

  UserModel _createSampleUser(String userId, String registrationNumber) {
    // The profile could not be loaded. Show a neutral placeholder instead of
    // inventing a person.
    return UserModel(
      id: userId,
      email: '',
      fullName: 'Member $registrationNumber',
      phoneNumber: '',
      role: UserRole.choirMember,
      createdAt: DateTime.now(),
      isActive: true,
      suggestedChoir: '',
    );
  }

  Future<void> _loadStatistics() async {
    // Load attendance data first
    final attendanceController = Provider.of<AttendanceController>(
      context,
      listen: false,
    );
    await attendanceController.loadAttendanceSessions(choirId: widget.choir.id);
    await attendanceController.loadChoirAttendance(widget.choir.id);

    // Then calculate rates with loaded data
    final attendanceRate = await _calculateAttendanceRate();
    final totalSessions = await _calculateTotalSessions();

    if (mounted) {
      setState(() {
        _attendanceRate = attendanceRate;
        _totalSessions = totalSessions;
      });
    }
  }

  Future<void> _loadRecentActivities() async {
    final activities = await _activityService.getChoirActivities(
      widget.choir.id,
      limit: 5,
    );

    if (mounted) {
      setState(() {
        _recentActivities = activities;
      });
    }
  }

  // Calculate real attendance rate
  Future<double> _calculateAttendanceRate() async {
    try {
      final attendanceController = Provider.of<AttendanceController>(
        context,
        listen: false,
      );

      // Get attendance records for this choir
      final attendanceRecords = attendanceController.attendanceRecords
          .where((record) => record.choirId == widget.choir.id)
          .toList();

      Logger.debug('Calculating attendance rate for choir ${widget.choir.id}');
      Logger.debug('Found ${attendanceRecords.length} attendance records');
      Logger.debug(
        'All records: ${attendanceController.attendanceRecords.length}',
      );

      if (attendanceRecords.isEmpty) {
        Logger.debug('No attendance records found for this choir');
        // Return -1 to indicate no data (we'll handle this in the UI)
        return -1.0;
      }

      // Calculate attendance rate from actual records
      final presentCount = attendanceRecords
          .where(
            (r) =>
                r.status == AttendanceStatus.present ||
                r.status == AttendanceStatus.late,
          )
          .length;
      final totalRecords = attendanceRecords.length;

      final rate = totalRecords > 0
          ? (presentCount / totalRecords) * 100.0
          : 0.0;

      Logger.debug(
        'Present/Late: $presentCount, Total: $totalRecords, Rate: $rate%',
      );

      return rate;
    } catch (e) {
      Logger.error('Error calculating attendance rate', e);
      return -1.0; // Return -1 to indicate error/no data
    }
  }

  // Calculate total sessions/events count
  Future<int> _calculateTotalSessions() async {
    try {
      final attendanceController = Provider.of<AttendanceController>(
        context,
        listen: false,
      );

      // Get actual sessions for this choir
      final sessions = attendanceController.sessions
          .where((session) => session.choirId == widget.choir.id)
          .toList();

      return sessions.length;
    } catch (e) {
      return 0; // Return 0 if no data
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MusicLibraryColors.background,
      appBar: AppBar(
        backgroundColor: MusicLibraryColors.card,
        foregroundColor: MusicLibraryColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.choir.name,
          style: mlText(size: 17, weight: FontWeight.w700),
        ),
        actions: [
          Consumer<AuthController>(
            builder: (context, authController, child) {
              final canEdit =
                  authController.isAdmin ||
                  widget.choir.leaderId == authController.currentUser?.id ||
                  widget.choir.adminId == authController.currentUser?.id;

              if (!canEdit) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                onSelected: _handleAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit),
                        const SizedBox(width: 8),
                        Text(context.tr('choirEditAction')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 8),
                        Text(context.tr('settings')),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MusicLibraryColors.primary,
          labelColor: MusicLibraryColors.primary,
          unselectedLabelColor: MusicLibraryColors.textSecondary,
          labelStyle: mlText(size: 14, weight: FontWeight.w600),
          unselectedLabelStyle: mlText(size: 14, weight: FontWeight.w500),
          tabs: [
            Tab(text: context.tr('overview')),
            Tab(text: context.tr('members')),
            Tab(text: context.tr('attendance')),
            Tab(text: context.tr('reports')),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: MusicLibraryColors.backgroundGradient,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildMembersTab(),
            _buildAttendanceTab(),
            _buildReportsTab(),
          ],
        ),
      ),
      floatingActionButton: Consumer<AuthController>(
        builder: (context, authController, child) {
          final canManage =
              authController.isAdmin ||
              widget.choir.leaderId == authController.currentUser?.id ||
              widget.choir.adminId == authController.currentUser?.id;

          if (!canManage) return const SizedBox.shrink();

          return FloatingActionButton(
            backgroundColor: MusicLibraryColors.primary,
            onPressed: _showAddMemberDialog,
            tooltip: context.tr('choirAddMemberTooltip'),
            child: const Icon(Icons.person_add, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChoirInfoCard(),
          const SizedBox(height: 16),
          _buildStatisticsCard(),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildChoirInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MusicLibraryColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MusicLibraryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: MusicLibraryColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.choir.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.choir.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.music_note,
                              color: MusicLibraryColors.primary,
                              size: 28,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.music_note,
                        color: MusicLibraryColors.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.choir.name,
                      style: mlText(size: 18, weight: FontWeight.w700),
                    ),
                    if (widget.choir.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.choir.description,
                        style: mlText(
                          size: 13,
                          color: MusicLibraryColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: MusicLibraryColors.border),
          const SizedBox(height: 16),
          _buildInfoRow(
            context.tr('choirCreatedLabel'),
            _formatDate(widget.choir.createdAt),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context.tr('status'),
            widget.choir.isActive
                ? context.tr('active')
                : context.tr('inactive'),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context.tr('members'),
            widget.choir.memberCount.toString(),
          ),
          if (widget.choir.location != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context.tr('choirLocationLabel'),
              widget.choir.location!,
            ),
          ],
          if (widget.choir.schedule != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context.tr('choirScheduleLabel'),
              widget.choir.schedule!,
            ),
          ],
          // Location section
          if (_getCurrentChoir().country != null &&
                  _getCurrentChoir().country!.isNotEmpty ||
              _getCurrentChoir().diocese != null &&
                  _getCurrentChoir().diocese!.isNotEmpty ||
              _getCurrentChoir().parish != null &&
                  _getCurrentChoir().parish!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: MusicLibraryColors.border),
            const SizedBox(height: 16),
            Text(
              context.tr('choirLocationLabel'),
              style: mlText(size: 15, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
          ],
          if (_getCurrentChoir().country != null &&
              _getCurrentChoir().country!.isNotEmpty) ...[
            _buildLocationRow(
              context.tr('choirCountryLabel'),
              _getCurrentChoir().country!,
              _getCountryFlag(_getCurrentChoir().country!),
            ),
            const SizedBox(height: 8),
          ],
          if (_getCurrentChoir().diocese != null &&
              _getCurrentChoir().diocese!.isNotEmpty) ...[
            _buildLocationRow(
              context.tr('choirDioceseLabel'),
              _getCurrentChoir().diocese!,
              '⛪',
            ),
            const SizedBox(height: 8),
          ],
          if (_getCurrentChoir().parish != null &&
              _getCurrentChoir().parish!.isNotEmpty) ...[
            _buildLocationRow(
              context.tr('choirParishLabel'),
              _getCurrentChoir().parish!,
              '🏛️',
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final activeMembers = Provider.of<ChoirController>(
      context,
    ).choirMembers.where((m) => m.isActive).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MusicLibraryColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MusicLibraryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('choirStatisticsLabel'),
            style: mlText(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatisticItem(
                  title: context.tr('choirTotalMembersLabel'),
                  value: widget.choir.memberCount.toString(),
                  icon: Icons.people,
                  color: MusicLibraryColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatisticItem(
                  title: context.tr('active'),
                  value: '$activeMembers',
                  icon: Icons.check_circle,
                  color: MusicLibraryColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatisticItem(
                  title: context.tr('choirAttendanceRateLabel'),
                  value: _attendanceRate < 0
                      ? context.tr('choirNoDataLabel')
                      : '${_attendanceRate.round()}%',
                  icon: Icons.trending_up,
                  color: MusicLibraryColors.warning,
                ),
              ),
              Expanded(
                child: _buildStatisticItem(
                  title: context.tr('choirEventsLabel'),
                  value: '$_totalSessions',
                  icon: Icons.event,
                  color: MusicLibraryColors.midiAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: mlText(size: 18, weight: FontWeight.w700, color: color),
          ),
          Text(
            title,
            style: mlText(size: 12, color: MusicLibraryColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MusicLibraryColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MusicLibraryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('recentActivity'),
                style: mlText(size: 15, weight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _showAllActivitiesDialog();
                },
                child: Text(context.tr('choirViewAllAction')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.tr('noRecentActivity'),
                style: mlText(
                  size: 13,
                  color: MusicLibraryColors.textSecondary,
                ),
              ),
            )
          else
            ..._recentActivities.map(
              (activity) => _buildActivityItem(
                icon: activity.icon,
                title: activity.title,
                subtitle: activity.description,
                time: activity.timeAgo,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: MusicLibraryColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: MusicLibraryColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: mlText(size: 14, weight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: mlText(
                    size: 12,
                    color: MusicLibraryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: mlText(size: 12, color: MusicLibraryColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return Consumer<ChoirController>(
      builder: (context, choirController, child) {
        if (choirController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allMembers = choirController.choirMembers;

        // Filter members based on search and status
        final filteredMembers = _filterMembers(allMembers);

        return Column(
          children: [
            _buildMembersHeader(allMembers),
            if (allMembers.isNotEmpty) _buildMembersFilters(),
            Expanded(
              child: allMembers.isEmpty
                  ? _buildEmptyMembersState()
                  : filteredMembers.isEmpty
                  ? _buildNoResultsState()
                  : _buildMembersList(filteredMembers),
            ),
          ],
        );
      },
    );
  }

  String _getMemberDisplayName(ChoirMemberModel member) {
    final user = _userCache[member.userId];
    if (user != null) {
      return user.fullName;
    }

    // Fallback to registration number if user data is not available
    return '${context.tr('choirMemberFallbackPrefix')} ${member.registrationNumber}';
  }

  // Enhanced Members Tab Helper Methods
  Widget _buildMembersHeader(List<ChoirMemberModel> allMembers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${allMembers.length} ${context.tr('members')}',
                  style: mlText(size: 18, weight: FontWeight.w700),
                ),
                if (allMembers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getMembersStatusSummary(allMembers),
                    style: mlText(
                      size: 13,
                      color: MusicLibraryColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (allMembers.length > 3) // Show search if more than 3 members
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearchActive = !_isSearchActive;
                  if (!_isSearchActive) {
                    _searchController.clear();
                  }
                });
              },
              icon: Icon(
                _isSearchActive ? Icons.search_off : Icons.search,
                color: MusicLibraryColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String _getMembersStatusSummary(List<ChoirMemberModel> members) {
    final active = members.where((m) => m.status == MemberStatus.active).length;
    final inactive = members
        .where((m) => m.status == MemberStatus.inactive)
        .length;
    final suspended = members
        .where((m) => m.status == MemberStatus.suspended)
        .length;

    final List<String> parts = [];
    if (active > 0) parts.add('$active ${context.tr('active').toLowerCase()}');
    if (inactive > 0)
      parts.add('$inactive ${context.tr('inactive').toLowerCase()}');
    if (suspended > 0)
      parts.add(
        '$suspended ${context.tr('choirSuspendedLabel').toLowerCase()}',
      );

    return parts.join(' • ');
  }

  Widget _buildMembersFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          if (_isSearchActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: MusicLibraryColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MusicLibraryColors.border),
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
                          hintText: context.tr('choirSearchMembersHint'),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: context.tr('choirAllStatusLabel'),
                  isSelected: _selectedStatusFilter == 'all',
                  onSelected: () =>
                      setState(() => _selectedStatusFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: context.tr('active'),
                  isSelected: _selectedStatusFilter == 'active',
                  onSelected: () =>
                      setState(() => _selectedStatusFilter = 'active'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: context.tr('inactive'),
                  isSelected: _selectedStatusFilter == 'inactive',
                  onSelected: () =>
                      setState(() => _selectedStatusFilter = 'inactive'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: context.tr('choirSuspendedLabel'),
                  isSelected: _selectedStatusFilter == 'suspended',
                  onSelected: () =>
                      setState(() => _selectedStatusFilter = 'suspended'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: mlText(
          size: 12,
          weight: FontWeight.w600,
          color: isSelected
              ? MusicLibraryColors.primary
              : MusicLibraryColors.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: MusicLibraryColors.card,
      selectedColor: MusicLibraryColors.primary.withValues(alpha: 0.08),
      checkmarkColor: MusicLibraryColors.primary,
      side: BorderSide(
        color: isSelected
            ? MusicLibraryColors.primary
            : MusicLibraryColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  List<ChoirMemberModel> _filterMembers(List<ChoirMemberModel> members) {
    final filtered = members.where((member) {
      // Status filter
      if (_selectedStatusFilter != 'all') {
        final statusMatch =
            member.status.toString().split('.').last == _selectedStatusFilter;
        if (!statusMatch) return false;
      }

      // Search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        final memberName = _getMemberDisplayName(member).toLowerCase();
        final regNumber = member.registrationNumber.toLowerCase();
        final email = _userCache[member.userId]?.email.toLowerCase() ?? '';

        if (!memberName.contains(searchTerm) &&
            !regNumber.contains(searchTerm) &&
            !email.contains(searchTerm)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort filtered members
    filtered.sort((a, b) {
      // First by status (active first)
      if (a.status != b.status) {
        if (a.status == MemberStatus.active) return -1;
        if (b.status == MemberStatus.active) return 1;
        if (a.status == MemberStatus.inactive &&
            b.status == MemberStatus.suspended) {
          return -1;
        }
        if (a.status == MemberStatus.suspended &&
            b.status == MemberStatus.inactive) {
          return 1;
        }
      }

      // Then by name
      return _getMemberDisplayName(a).compareTo(_getMemberDisplayName(b));
    });

    return filtered;
  }

  Widget _buildEmptyMembersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 56,
            color: MusicLibraryColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('choirNoMembersYet'),
            style: mlText(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('choirAddFirstMemberPrompt'),
            style: mlText(size: 13, color: MusicLibraryColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
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
            context.tr('choirNoMembersFound'),
            style: mlText(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('choirAdjustSearchFilters'),
            style: mlText(size: 13, color: MusicLibraryColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: MusicLibraryColors.primary,
            ),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedStatusFilter = 'all';
              });
            },
            child: Text(context.tr('choirClearFiltersAction')),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<ChoirMemberModel> members) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildEnhancedMemberCard(member);
      },
    );
  }

  Widget _buildEnhancedMemberCard(ChoirMemberModel member) {
    final user = _userCache[member.userId];
    final memberName = _getMemberDisplayName(member);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MusicLibraryColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MusicLibraryColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _handleMemberAction(member, 'view'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getStatusColor(member.status),
                      radius: 24,
                      child: Text(
                        _getInitials(memberName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName,
                            style: mlText(size: 15, weight: FontWeight.w700),
                          ),
                          if (user?.email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.email,
                              style: mlText(
                                size: 12,
                                color: MusicLibraryColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildStatusChip(member.status),
                              const SizedBox(width: 8),
                              _buildRoleChip(member.role),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMemberAction(member, value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              const Icon(Icons.visibility, size: 16),
                              const SizedBox(width: 8),
                              Text(context.tr('choirViewDetailsAction')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'message',
                          child: Row(
                            children: [
                              const Icon(Icons.message, size: 16),
                              const SizedBox(width: 8),
                              Text(context.tr('choirSendMessageAction')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 16),
                              const SizedBox(width: 8),
                              Text(context.tr('edit')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.remove_circle,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('remove'),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: MusicLibraryColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoItem(
                      icon: Icons.badge_outlined,
                      label: context.tr('choirRegNumberLabel'),
                      value: member.registrationNumber,
                    ),
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: context.tr('choirJoinedLabel'),
                      value: _formatDate(member.joinDate),
                    ),
                    if (member.outstandingFees > 0) ...[
                      const SizedBox(width: 24),
                      _buildInfoItem(
                        icon: Icons.warning,
                        label: context.tr('choirFeesLabel'),
                        value: '\$${member.outstandingFees.toStringAsFixed(2)}',
                        color: MusicLibraryColors.warning,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first
          .substring(0, parts.first.length > 2 ? 2 : parts.first.length)
          .toUpperCase();
    }
    return 'M';
  }

  Widget _buildStatusChip(MemberStatus status) {
    final color = _getStatusColor(status);
    final statusText = status.toString().split('.').last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: mlText(size: 10, weight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildRoleChip(MemberRole role) {
    final color = _getRoleColor(role);
    final roleText = role.toString().split('.').last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        roleText.toUpperCase(),
        style: mlText(size: 10, weight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final itemColor = color ?? MusicLibraryColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: itemColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: mlText(
                size: 10,
                weight: FontWeight.w500,
                color: itemColor,
              ),
            ),
            Text(
              value,
              style: mlText(
                size: 12,
                weight: FontWeight.w600,
                color: itemColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return Colors.green;
      case MemberStatus.inactive:
        return Colors.orange;
      case MemberStatus.suspended:
        return Colors.red;
    }
  }

  Color _getRoleColor(MemberRole role) {
    switch (role) {
      case MemberRole.leader:
        return Colors.amber;
      case MemberRole.committee:
        return Colors.blue;
      case MemberRole.board:
        return Colors.purple;
      case MemberRole.choir:
        return Colors.green;
      case MemberRole.patron:
        return Colors.red;
      case MemberRole.trainer:
        return Colors.orange;
    }
  }

  Widget _buildAttendanceTab() {
    return Consumer<AttendanceController>(
      builder: (context, attendanceController, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats with overflow protection
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MusicLibraryColors.success.withValues(
                          alpha: 0.06,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: MusicLibraryColors.success.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: MusicLibraryColors.success,
                            size: 22,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _attendanceRate < 0
                                ? context.tr('choirNoDataLabel')
                                : '${_attendanceRate.round()}%',
                            style: mlText(
                              size: 18,
                              weight: FontWeight.w700,
                              color: MusicLibraryColors.success,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            context.tr('attendance'),
                            style: mlText(
                              size: 10,
                              color: MusicLibraryColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MusicLibraryColors.primary.withValues(
                          alpha: 0.06,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: MusicLibraryColors.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event,
                            color: MusicLibraryColors.primary,
                            size: 22,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${attendanceController.sessions.length}',
                            style: mlText(
                              size: 18,
                              weight: FontWeight.w700,
                              color: MusicLibraryColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            context.tr('choirSessionsLabel'),
                            style: mlText(
                              size: 10,
                              color: MusicLibraryColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons with overflow protection
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _takeAttendance(),
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            context.tr('takeAttendance'),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MusicLibraryColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewAttendanceHistory(),
                          icon: const Icon(Icons.history, size: 16),
                          label: Text(
                            context.tr('choirViewHistoryAction'),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MusicLibraryColors.textPrimary,
                            side: const BorderSide(
                              color: MusicLibraryColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _messageAllMembers(),
                          icon: const Icon(
                            Icons.message,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            context.tr('choirMessageAllAction'),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MusicLibraryColors.midiAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewReports(),
                          icon: const Icon(Icons.analytics, size: 16),
                          label: Text(
                            context.tr('viewReports'),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MusicLibraryColors.textPrimary,
                            side: const BorderSide(
                              color: MusicLibraryColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Recent Sessions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('choirRecentSessionsLabel'),
                    style: mlText(size: 16, weight: FontWeight.w700),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: MusicLibraryColors.primary,
                    ),
                    onPressed: () => _viewAttendanceHistory(),
                    child: Text(
                      context.tr('choirViewAllAction'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Sessions List
              Expanded(
                child: attendanceController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : attendanceController.sessions.isEmpty
                    ? _buildEmptySessionsView()
                    : ListView.builder(
                        itemCount: attendanceController.sessions.length.clamp(
                          0,
                          5,
                        ),
                        itemBuilder: (context, index) {
                          final session = attendanceController.sessions[index];
                          return _buildSessionCard(session);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 80) return MusicLibraryColors.success;
    if (percentage >= 60) return MusicLibraryColors.warning;
    return MusicLibraryColors.danger;
  }

  Widget _buildEmptySessionsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy,
            size: 48,
            color: MusicLibraryColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('choirNoSessionsYet'),
            style: mlText(size: 15, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('choirTakeAttendancePrompt'),
            style: mlText(size: 13, color: MusicLibraryColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getSessionAttendanceDataSync(String sessionId) {
    final attendanceController = Provider.of<AttendanceController>(
      context,
      listen: false,
    );

    // Use already loaded data only - don't trigger async operations during build
    final sessionRecords = attendanceController.attendanceRecords
        .where((r) => r.sessionId == sessionId)
        .toList();

    Logger.debug('Getting attendance for session $sessionId');
    Logger.debug('Found ${sessionRecords.length} records for this session');
    Logger.debug(
      'Total attendance records: ${attendanceController.attendanceRecords.length}',
    );

    // Debug: Show all unique session IDs in attendance records
    final allSessionIds = attendanceController.attendanceRecords
        .map((r) => r.sessionId)
        .toSet();
    Logger.debug('All session IDs in attendance records: $allSessionIds');

    final presentCount = sessionRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final lateCount = sessionRecords
        .where((r) => r.status == AttendanceStatus.late)
        .length;
    final totalCount = sessionRecords.length;

    final attendanceRate = totalCount > 0
        ? ((presentCount + lateCount) / totalCount * 100).round()
        : 0;

    return {
      'rate': attendanceRate,
      'present': presentCount,
      'late': lateCount,
      'total': totalCount,
    };
  }

  Widget _buildSessionCard(AttendanceSessionModel session) {
    Logger.debug(
      'Building session card for session ${session.id} - ${session.title}',
    );
    final attendanceData = _getSessionAttendanceDataSync(session.id);
    final attendanceRate = attendanceData['rate'] as int;
    final presentCount = attendanceData['present'] as int;
    final lateCount = attendanceData['late'] as int;
    final totalCount = attendanceData['total'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: MusicLibraryColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MusicLibraryColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          // The subtitle has two lines when there are records; a two-line
          // tile is a hair too short for that.
          isThreeLine: totalCount > 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getPercentageColor(attendanceRate).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEventTypeIcon(session.eventType),
              color: _getPercentageColor(attendanceRate),
              size: 18,
            ),
          ),
          title: Text(
            session.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: mlText(size: 14, weight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${session.date.day}/${session.date.month}/${session.date.year}',
                style: mlText(
                  size: 12,
                  color: MusicLibraryColors.textSecondary,
                ),
              ),
              if (totalCount > 0)
                Text(
                  '$presentCount ${context.tr('choirPresentLabel').toLowerCase()}, $lateCount ${context.tr('choirLateLabel').toLowerCase()} ${context.tr('choirOfLabel')} $totalCount',
                  style: mlText(
                    size: 10,
                    color: MusicLibraryColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            constraints: const BoxConstraints(minWidth: 40),
            decoration: BoxDecoration(
              color: _getPercentageColor(attendanceRate).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$attendanceRate%',
              style: mlText(
                size: 11,
                weight: FontWeight.bold,
                color: _getPercentageColor(attendanceRate),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          onTap: () => _viewSessionDetails(session),
        ),
      ),
    );
  }

  IconData _getEventTypeIcon(EventType eventType) {
    switch (eventType) {
      case EventType.service:
        return Icons.church;
      case EventType.rehearsal:
        return Icons.music_note;
      case EventType.meeting:
        return Icons.meeting_room;
      case EventType.other:
        return Icons.event;
    }
  }

  void _viewSessionDetails(AttendanceSessionModel session) {
    final attendanceController = Provider.of<AttendanceController>(
      context,
      listen: false,
    );
    attendanceController.selectSession(session);

    // Get attendance data for this session
    final attendanceData = _getSessionAttendanceDataSync(session.id);
    final attendanceRecords = attendanceController.attendanceRecords
        .where((record) => record.sessionId == session.id)
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: MusicLibraryColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getEventTypeIcon(session.eventType),
                    size: 22,
                    color: MusicLibraryColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.title,
                      style: mlText(size: 17, weight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: MusicLibraryColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${context.tr('choirDateLabelPrefix')} ${session.date.day}/${session.date.month}/${session.date.year}',
                style: mlText(
                  size: 13,
                  color: MusicLibraryColors.textSecondary,
                ),
              ),
              if (session.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  '${context.tr('choirDescriptionLabelPrefix')} ${session.description}',
                  style: mlText(
                    size: 13,
                    color: MusicLibraryColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MusicLibraryColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MusicLibraryColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSessionStat(
                      '${attendanceData['present']}',
                      context.tr('choirPresentLabel'),
                      MusicLibraryColors.success,
                    ),
                    _buildSessionStat(
                      '${attendanceData['late']}',
                      context.tr('choirLateLabel'),
                      MusicLibraryColors.warning,
                    ),
                    _buildSessionStat(
                      '${attendanceData['total'] - attendanceData['present'] - attendanceData['late']}',
                      context.tr('choirAbsentLabel'),
                      MusicLibraryColors.textSecondary,
                    ),
                    _buildSessionStat(
                      '${attendanceData['rate']}%',
                      context.tr('choirRateLabel'),
                      _getPercentageColor(attendanceData['rate']),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('choirAttendanceRecordsLabel'),
                style: mlText(size: 14, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: attendanceRecords.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('choirNoAttendanceRecordsFound'),
                          style: mlText(
                            size: 13,
                            color: MusicLibraryColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record = attendanceRecords[index];
                          final memberInfo = _getMemberDisplayInfo(record);
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              color: MusicLibraryColors.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: MusicLibraryColors.border,
                              ),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: _getAttendanceColor(
                                  record.status,
                                ),
                                radius: 16,
                                child: Text(
                                  _getStatusText(record.status)[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                memberInfo['name'] ??
                                    context.tr('choirUnknownMember'),
                                style: mlText(
                                  size: 14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${context.tr('choirIdLabelPrefix')} ${memberInfo['registrationId']}',
                                    style: mlText(
                                      size: 12,
                                      weight: FontWeight.w500,
                                      color: MusicLibraryColors.textSecondary,
                                    ),
                                  ),
                                  if (record.notes?.isNotEmpty == true)
                                    Text(
                                      record.notes!,
                                      style: mlText(
                                        size: 12,
                                        color: MusicLibraryColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getAttendanceColor(record.status),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getStatusText(record.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MusicLibraryColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: mlText(size: 20, weight: FontWeight.w700, color: color),
        ),
        Text(
          label,
          style: mlText(size: 12, color: MusicLibraryColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuickReportsSection(),
          const SizedBox(height: 16),
          _buildDetailedReportsSection(),
        ],
      ),
    );
  }

  Widget _buildQuickReportsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MusicLibraryColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MusicLibraryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('choirQuickReportsLabel'),
            style: mlText(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // A fixed height, not an aspect ratio: with a ratio the tile
            // shrinks with the screen width while its text does not.
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.isMobile(context) ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 124,
            ),
            children: [
              _buildReportCard(
                title: context.tr('choirMembershipLabel'),
                subtitle: context.tr('choirMemberAnalyticsLabel'),
                icon: Icons.people,
                color: MusicLibraryColors.primary,
                onTap: () => _navigateToReport('membership'),
              ),
              _buildReportCard(
                title: context.tr('attendance'),
                subtitle: context.tr('choirAttendanceReportsLabel'),
                icon: Icons.fact_check,
                color: MusicLibraryColors.success,
                onTap: () => _navigateToReport('attendance'),
              ),
              _buildReportCard(
                title: context.tr('payments'),
                subtitle: context.tr('choirFinancialReportsLabel'),
                icon: Icons.payment,
                color: MusicLibraryColors.midiAccent,
                onTap: () => _navigateToReport('payments'),
              ),
              _buildReportCard(
                title: context.tr('choirActivitiesLabel'),
                subtitle: context.tr('choirActivitySummaryLabel'),
                icon: Icons.event,
                color: MusicLibraryColors.warning,
                onTap: () => _navigateToReport('activities'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReportsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MusicLibraryColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MusicLibraryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('choirDetailedReportsLabel'),
            style: mlText(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildDetailedReportTile(
            icon: Icons.analytics,
            title: context.tr('choirComprehensiveAnalyticsLabel'),
            subtitle: context.tr('choirFullPerformanceReportLabel'),
            onTap: () => _navigateToReport('comprehensive'),
          ),
          const Divider(color: MusicLibraryColors.border),
          _buildDetailedReportTile(
            icon: Icons.trending_up,
            title: context.tr('choirGrowthTrendsLabel'),
            subtitle: context.tr('choirMemberActivityGrowthLabel'),
            onTap: () => _navigateToReport('trends'),
          ),
          const Divider(color: MusicLibraryColors.border),
          _buildDetailedReportTile(
            icon: Icons.download,
            title: context.tr('choirExportDataLabel'),
            subtitle: context.tr('choirExportDataSubtitle'),
            onTap: () => _showDirectExportOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: MusicLibraryColors.primary),
        title: Text(title, style: mlText(size: 14, weight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: mlText(size: 12, color: MusicLibraryColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: MusicLibraryColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                title,
                style: mlText(size: 13, weight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: mlText(
                  size: 11,
                  color: MusicLibraryColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReport(String reportType) async {
    final reportController = Provider.of<ReportController>(
      context,
      listen: false,
    );

    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Map report types to the correct service methods
      final String actualReportType = _mapReportType(reportType);

      switch (actualReportType) {
        case 'membership':
          await reportController.generateMembershipReport(
            choirId: widget.choir.id,
            fromDate: DateTime.now().subtract(const Duration(days: 180)),
            toDate: DateTime.now(),
            membershipFilter: 'all',
          );
          break;
        case 'attendance':
          await reportController.generateAttendanceReport(
            choirId: widget.choir.id,
            fromDate: DateTime.now().subtract(const Duration(days: 180)),
            toDate: DateTime.now(),
          );
          break;
        case 'financial':
          await reportController.generateFinancialReport(
            choirId: widget.choir.id,
            fromDate: DateTime.now().subtract(const Duration(days: 180)),
            toDate: DateTime.now(),
          );
          break;
        case 'overview':
        case 'comprehensive':
          await reportController.generateChoirOverviewReport(
            choirId: widget.choir.id,
            fromDate: DateTime.now().subtract(const Duration(days: 180)),
            toDate: DateTime.now(),
          );
          break;
        case 'trends':
          await reportController.generateMembershipReport(
            choirId: widget.choir.id,
            fromDate: DateTime.now().subtract(const Duration(days: 365)),
            toDate: DateTime.now(),
            membershipFilter: 'all',
          );
          break;
        case 'export':
          await reportController.generateChoirOverviewReport(
            choirId: widget.choir.id,
            fromDate: DateTime.now().subtract(const Duration(days: 180)),
            toDate: DateTime.now(),
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
          // Navigate directly to report details screen - only one navigation level
          Get.to(
            () => ReportDetailScreen(
              reportType: actualReportType,
              reportData: reportController.currentReport,
            ),
          );
        }
      } else {
        Get.snackbar(
          context.tr('choirNoDataTitle'),
          context.tr('choirNoDataForReportMessage'),
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        context.tr('error'),
        '${context.tr('choirFailedToGenerateReportPrefix')} $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _showDirectExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MusicLibraryColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${context.tr('choirExportPrefix')} ${widget.choir.name} ${context.tr('choirExportDataSuffix')}',
              style: mlText(size: 17, weight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _buildExportTile(
              icon: Icons.picture_as_pdf,
              color: MusicLibraryColors.danger,
              title: context.tr('choirExportAsPdfLabel'),
              subtitle: context.tr('choirComprehensiveOverviewLabel'),
              onTap: () {
                Navigator.pop(context);
                _directExport('pdf');
              },
            ),
            _buildExportTile(
              icon: Icons.table_chart,
              color: MusicLibraryColors.success,
              title: context.tr('choirExportAsExcelLabel'),
              subtitle: context.tr('choirDetailedSpreadsheetLabel'),
              onTap: () {
                Navigator.pop(context);
                _directExport('excel');
              },
            ),
            _buildExportTile(
              icon: Icons.text_snippet,
              color: MusicLibraryColors.primary,
              title: context.tr('choirExportAsCsvLabel'),
              subtitle: context.tr('choirCommaSeparatedValuesLabel'),
              onTap: () {
                Navigator.pop(context);
                _directExport('csv');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: mlText(size: 14, weight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: mlText(size: 12, color: MusicLibraryColors.textSecondary),
        ),
        onTap: onTap,
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
            Text(
              '${context.tr('choirExportPrefix')} ${widget.choir.name} ${context.tr('choirExportDataSuffix')}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(context.tr('choirExportAsPdfLabel')),
              subtitle: Text(context.tr('choirGeneratePdfReportLabel')),
              onTap: () {
                Navigator.pop(context);
                _exportReport('pdf', reportController);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text(context.tr('choirExportAsExcelLabel')),
              subtitle: Text(context.tr('choirGenerateExcelSpreadsheetLabel')),
              onTap: () {
                Navigator.pop(context);
                _exportReport('excel', reportController);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: Text(context.tr('choirExportAsCsvLabel')),
              subtitle: Text(context.tr('choirGenerateCsvFileLabel')),
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

  void _directExport(String format) async {
    final reportController = Provider.of<ReportController>(
      context,
      listen: false,
    );

    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Generate overview report for export
      await reportController.generateChoirOverviewReport(
        choirId: widget.choir.id,
        fromDate: DateTime.now().subtract(const Duration(days: 180)),
        toDate: DateTime.now(),
      );

      // Hide loading
      Get.back();

      if (reportController.hasReportData) {
        // Export directly without showing report screen
        _exportReport(format, reportController);
      } else {
        Get.snackbar(
          context.tr('choirNoDataTitle'),
          context.tr('choirNoDataForExportMessage'),
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        context.tr('choirExportErrorTitle'),
        '${context.tr('choirFailedToPrepareExportPrefix')} $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _exportReport(String format, ReportController reportController) async {
    try {
      final exportService = ExportService();
      String? filePath;

      switch (format) {
        case 'csv':
          final reportData = reportController.currentReport;
          final reportType = reportData['report_type'] ?? 'overview';
          filePath = await exportService.exportReportToCSV(
            reportData,
            reportType,
          );

          if (filePath != null) {
            Get.snackbar(
              context.tr('choirExportSuccessTitle'),
              '${context.tr('choirCsvSavedToPrefix')} $filePath',
              backgroundColor: AppColors.success,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              context.tr('choirExportFailedTitle'),
              context.tr('choirFailedToSaveCsvMessage'),
              backgroundColor: AppColors.error,
              colorText: Colors.white,
            );
          }
          break;

        case 'pdf':
          final reportData = reportController.currentReport;
          final reportType = reportData['report_type'] ?? 'overview';

          switch (reportType) {
            case 'membership':
              filePath = await exportService.exportMembershipToPDF(reportData);
              break;
            case 'attendance':
              filePath = await exportService.exportAttendanceToPDF(reportData);
              break;
            case 'financial':
              filePath = await exportService.exportFinancialToPDF(reportData);
              break;
            case 'overview':
            case 'comprehensive':
            case 'choir_overview':
              // For overview reports, export as membership report with full data
              filePath = await exportService.exportMembershipToPDF(reportData);
              break;
            default:
              Get.snackbar(
                context.tr('choirComingSoonTitle'),
                'PDF ${context.tr('choirExportForReportTypePrefix')} $reportType ${context.tr('choirFutureUpdateSuffix')}',
                backgroundColor: AppColors.info,
                colorText: Colors.white,
              );
              return;
          }

          if (filePath != null) {
            Get.snackbar(
              context.tr('choirExportSuccessTitle'),
              '${context.tr('choirPdfSavedToPrefix')} $filePath',
              backgroundColor: AppColors.success,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              context.tr('choirExportFailedTitle'),
              context.tr('choirFailedToSavePdfMessage'),
              backgroundColor: AppColors.error,
              colorText: Colors.white,
            );
          }
          break;

        case 'excel':
          final reportData = reportController.currentReport;
          final reportType = reportData['report_type'] ?? 'overview';

          switch (reportType) {
            case 'membership':
              filePath = await exportService.exportMembershipToExcel(
                reportData,
              );
              break;
            case 'attendance':
              filePath = await exportService.exportAttendanceToExcel(
                reportData,
              );
              break;
            case 'financial':
              filePath = await exportService.exportFinancialToExcel(reportData);
              break;
            case 'overview':
            case 'comprehensive':
            case 'choir_overview':
              // For overview reports, export as membership report with full data
              filePath = await exportService.exportMembershipToExcel(
                reportData,
              );
              break;
            default:
              Get.snackbar(
                context.tr('choirComingSoonTitle'),
                'Excel ${context.tr('choirExportForReportTypePrefix')} $reportType ${context.tr('choirFutureUpdateSuffix')}',
                backgroundColor: AppColors.info,
                colorText: Colors.white,
              );
              return;
          }

          if (filePath != null) {
            Get.snackbar(
              context.tr('choirExportSuccessTitle'),
              '${context.tr('choirExcelSavedToPrefix')} $filePath',
              backgroundColor: AppColors.success,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              context.tr('choirExportFailedTitle'),
              context.tr('choirFailedToSaveExcelMessage'),
              backgroundColor: AppColors.error,
              colorText: Colors.white,
            );
          }
          break;
      }
    } catch (e) {
      Get.snackbar(
        context.tr('choirExportErrorTitle'),
        '${context.tr('choirExportFailedPrefix')} $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  String _mapReportType(String reportType) {
    switch (reportType) {
      case 'payments':
        return 'financial';
      case 'activities':
        return 'overview';
      default:
        return reportType; // membership, attendance, comprehensive, trends remain the same
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: mlText(size: 13, color: MusicLibraryColors.textSecondary),
        ),
        Text(value, style: mlText(size: 13, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLocationRow(String label, String value, String icon) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: mlText(size: 13, color: MusicLibraryColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: mlText(size: 13, weight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _getCountryFlag(String country) {
    // Map common country names to flag emojis
    const countryFlags = {
      'Tanzania': '🇹🇿',
      'Kenya': '🇰🇪',
      'Uganda': '🇺🇬',
      'Rwanda': '🇷🇼',
      'Burundi': '🇧🇮',
      'Ethiopia': '🇪🇹',
      'Ghana': '🇬🇭',
      'Nigeria': '🇳🇬',
      'South Africa': '🇿🇦',
      'United States': '🇺🇸',
      'United Kingdom': '🇬🇧',
      'Canada': '🇨🇦',
      'Australia': '🇦🇺',
      'Germany': '🇩🇪',
      'France': '🇫🇷',
      'Italy': '🇮🇹',
      'Spain': '🇪🇸',
      'Brazil': '🇧🇷',
      'Argentina': '🇦🇷',
      'Mexico': '🇲🇽',
      'India': '🇮🇳',
      'China': '🇨🇳',
      'Japan': '🇯🇵',
      'Philippines': '🇵🇭',
    };

    return countryFlags[country] ??
        '🌍'; // Default globe emoji if country not found
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get the current choir - uses the selected choir from controller if available,
  /// otherwise falls back to the original widget choir
  ChoirModel _getCurrentChoir() {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    return choirController.selectedChoir ?? widget.choir;
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'edit':
        final result = await Get.to(() => EditChoirScreen(choir: widget.choir));
        if (!mounted) return;
        if (result == true) {
          // Refresh the current screen or reload choir data
          final choirController = Provider.of<ChoirController>(
            context,
            listen: false,
          );
          await choirController.loadChoirs();
          if (!mounted) return;

          // Find and select the updated choir from the loaded choirs
          final updatedChoir = choirController.choirs.firstWhere(
            (choir) => choir.id == widget.choir.id,
            orElse: () => widget.choir,
          );
          choirController.selectChoir(updatedChoir);

          setState(() {}); // Trigger rebuild to show updated data
        }
        break;
      case 'settings':
        Get.to(() => ChoirSettingsScreen(choir: widget.choir));
        break;
    }
  }

  void _handleMemberAction(ChoirMemberModel member, String action) {
    switch (action) {
      case 'message':
        Get.to(() => MessageScreen(member: member, choir: widget.choir));
        break;
      case 'view':
        // Convert ChoirMemberModel to the format expected by MemberDetailScreen
        final memberData = {
          'id': member.id,
          'choir_id': member.choirId,
          'user_id': member.userId,
          'registration_number': member.registrationNumber,
          'join_date': member.joinDate.toIso8601String(),
          'status': member.status.toString().split('.').last,
          'role': 'member', // Default role
          'outstanding_fees': member.outstandingFees,
          'total_paid': member.totalPaid,
          'qr_code': member.qrCode,
          'metadata': member.metadata,
          'users': {
            'id': member.userId,
            'full_name': _getMemberDisplayName(member),
            'email': _userCache[member.userId]?.email ?? '',
          },
        };
        Get.to(() => MemberDetailScreen(member: memberData));
        break;
      case 'edit':
        // Convert to format expected by EditMemberScreen
        final memberData = {
          'id': member.id,
          'choir_id': member.choirId,
          'user_id': member.userId,
          'registration_number': member.registrationNumber,
          'join_date': member.joinDate.toIso8601String(),
          'status': member.status.toString().split('.').last,
          'role': 'member', // Default role
          'outstanding_fees': member.outstandingFees,
          'total_paid': member.totalPaid,
          'qr_code': member.qrCode,
          'metadata': member.metadata,
        };
        Get.to(() => EditMemberScreen(member: memberData));
        break;
      case 'remove':
        _showRemoveMemberDialog(member);
        break;
    }
  }

  void _showAddMemberDialog() {
    final TextEditingController userIdController = TextEditingController();
    final TextEditingController regNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MusicLibraryColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          context.tr('choirAddMemberTitle'),
          style: mlText(size: 17, weight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              style: mlText(size: 14),
              decoration: InputDecoration(
                labelText: context.tr('choirMemberNameIdLabel'),
                hintText: context.tr('choirEnterMemberNameIdHint'),
                prefixIcon: const Icon(
                  Icons.person,
                  color: MusicLibraryColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: regNumberController,
              style: mlText(size: 14),
              decoration: InputDecoration(
                labelText: context.tr('choirRegistrationNumberLabel'),
                hintText: context.tr('choirRegistrationNumberHint'),
                prefixIcon: const Icon(
                  Icons.numbers,
                  color: MusicLibraryColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: MusicLibraryColors.textSecondary,
            ),
            onPressed: () {
              userIdController.dispose();
              regNumberController.dispose();
              Navigator.of(context).pop();
            },
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MusicLibraryColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (userIdController.text.isNotEmpty &&
                  regNumberController.text.isNotEmpty) {
                Navigator.of(context).pop();
                _addMember(userIdController.text, regNumberController.text);
              }
              userIdController.dispose();
              regNumberController.dispose();
            },
            child: Text(context.tr('add')),
          ),
        ],
      ),
    );
  }

  void _addMember(String userId, String registrationNumber) async {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );

    final success = await choirController.addMemberToChoir(
      userId: userId,
      choirId: widget.choir.id,
      registrationNumber: registrationNumber,
    );

    if (success) {
      Get.snackbar(
        context.tr('choirSuccessTitle'),
        context.tr('choirMemberAddedMessage'),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        context.tr('error'),
        choirController.errorMessage ??
            context.tr('choirAddMemberFailedMessage'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _removeMember(ChoirMemberModel member) async {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );

    final success = await choirController.removeMemberFromChoir(
      memberId: member.id,
      choirId: widget.choir.id,
    );

    if (success) {
      Get.snackbar(
        context.tr('choirSuccessTitle'),
        context.tr('choirMemberRemovedMessage'),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        context.tr('error'),
        choirController.errorMessage ??
            context.tr('choirRemoveMemberFailedMessage'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showRemoveMemberDialog(ChoirMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('choirRemoveMemberTitle')),
        content: Text(context.tr('choirRemoveMemberConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMember(member);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              context.tr('remove'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _takeAttendance() async {
    // Ensure user data is loaded before showing the dialog
    await _loadMemberUserData();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AttendanceDialog(
        choir: widget.choir,
        userCache: _userCache,
        onAttendanceSaved: () async {
          // Refresh statistics when attendance is saved
          Logger.debug('Attendance saved callback triggered');

          // Force reload attendance data from storage
          final attendanceController = Provider.of<AttendanceController>(
            context,
            listen: false,
          );

          // Wait a bit to ensure data is saved to SharedPreferences
          await Future.delayed(const Duration(milliseconds: 100));

          await attendanceController.loadChoirAttendance(widget.choir.id);
          await attendanceController.loadAttendanceSessions(
            choirId: widget.choir.id,
          );

          // Then recalculate statistics
          await _loadStatistics();

          Logger.debug('Statistics refreshed after attendance save');
          Logger.debug(
            'Loaded ${attendanceController.sessions.length} sessions',
          );
        },
      ),
    );
  }

  void _viewAttendanceHistory() {
    // Navigate to a comprehensive attendance history screen
    _showAttendanceHistory();
  }

  void _messageAllMembers() {
    Get.to(() => MessageScreen(choir: widget.choir));
  }

  void _viewReports() {
    // Navigate to reports screen
    Get.to(() => const ReportsScreen());
  }

  void _showAttendanceHistory() {
    final attendanceController = Provider.of<AttendanceController>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.choir.name} Attendance History',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: attendanceController.sessions.length,
                  itemBuilder: (context, index) {
                    final session = attendanceController.sessions[index];
                    return _buildSessionCard(session);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for attendance status
  Color _getAttendanceColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.grey;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return context.tr('choirPresentLabel');
      case AttendanceStatus.late:
        return context.tr('choirLateLabel');
      case AttendanceStatus.absent:
        return context.tr('choirAbsentLabel');
    }
  }

  // Helper method to get member display info
  Map<String, String> _getMemberDisplayInfo(AttendanceModel record) {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );

    // Find the member by member ID
    final member = choirController.choirMembers.firstWhere(
      (m) => m.id == record.memberId,
      orElse: () => ChoirMemberModel(
        id: record.memberId,
        userId: record.userId,
        choirId: record.choirId,
        registrationNumber: 'Unknown',
        joinDate: DateTime.now(),
      ),
    );

    // Get user name from cache
    final user = _userCache[record.userId];
    final displayName = user?.fullName ?? context.tr('choirUnknownMember');
    final registrationId = member.registrationNumber;

    return {'name': displayName, 'registrationId': registrationId};
  }

  void _showAllActivitiesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: MusicLibraryColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('choirAllActivitiesTitle'),
                      style: mlText(size: 18, weight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: MusicLibraryColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Divider(color: MusicLibraryColors.border),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<ActivityModel>>(
                    future: _activityService.getChoirActivities(
                      widget.choir.id,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: MusicLibraryColors.primary,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            '${context.tr('choirErrorLoadingActivitiesPrefix')} ${snapshot.error}',
                            style: mlText(
                              size: 13,
                              color: MusicLibraryColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      final activities = snapshot.data ?? [];

                      if (activities.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history,
                                size: 56,
                                color: MusicLibraryColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.tr('choirNoActivitiesFound'),
                                style: mlText(
                                  size: 15,
                                  color: MusicLibraryColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: MusicLibraryColors.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: MusicLibraryColors.border,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: MusicLibraryColors.primary
                                        .withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    activity.icon,
                                    color: MusicLibraryColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  activity.title,
                                  style: mlText(
                                    size: 14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.description,
                                      style: mlText(
                                        size: 12,
                                        color: MusicLibraryColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      activity.timeAgo,
                                      style: mlText(
                                        size: 11,
                                        color: MusicLibraryColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Attendance Dialog Widget
class AttendanceDialog extends StatefulWidget {
  const AttendanceDialog({
    super.key,
    required this.choir,
    this.onAttendanceSaved,
    required this.userCache,
  });
  final ChoirModel choir;
  final VoidCallback? onAttendanceSaved;
  final Map<String, UserModel> userCache;

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog>
    with TickerProviderStateMixin {
  final Map<String, AttendanceStatus> _attendance = {};
  final Map<String, String> _notes = {};
  final Set<String> _selectedMembers = {};
  String _selectedEvent = 'Sunday Service';
  DateTime _selectedDate = DateTime.now();
  final DateTime _selectedTime = DateTime.now();
  String _sessionTitle = '';
  final String _sessionDescription = '';
  final int _graceMinutes = 15;
  bool _isLoading = false;
  AttendanceSessionModel? _currentSession;

  // Search and filter
  String _searchQuery = '';
  AttendanceStatus? _statusFilter;
  bool _isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();

  // Animation controllers
  late AnimationController _saveAnimationController;
  late AnimationController _searchAnimationController;

  final List<String> _eventTypes = [
    'Sunday Service',
    'Practice Session',
    'Special Event',
    'Wedding',
    'Funeral',
    'Conference',
  ];

  final Map<String, EventType> _eventTypeMap = {
    'Sunday Service': EventType.service,
    'Practice Session': EventType.rehearsal,
    'Special Event': EventType.other,
    'Wedding': EventType.other,
    'Funeral': EventType.other,
    'Conference': EventType.meeting,
  };

  @override
  void initState() {
    super.initState();
    _sessionTitle = _selectedEvent;
    _loadMembers();
    _initializeAnimations();
    _searchController.addListener(_onSearchChanged);
    // Don't create session immediately - wait until save
  }

  @override
  void dispose() {
    _saveAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _loadMembers() {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final members = choirController.choirMembers;

    for (var member in members) {
      _attendance[member.id] = AttendanceStatus.absent;
    }
  }

  Future<void> _updateSessionDetails() async {
    if (_currentSession != null) {
      final attendanceController = Provider.of<AttendanceController>(
        context,
        listen: false,
      );

      try {
        // Update the session with new details
        final updatedSession = AttendanceSessionModel(
          id: _currentSession!.id,
          choirId: _currentSession!.choirId,
          title: _sessionTitle, // Use updated title
          eventType:
              _eventTypeMap[_selectedEvent] ??
              EventType.other, // Use updated event type
          leaderId: _currentSession!.leaderId,
          date: _selectedDate,
          startTime: _selectedTime,
          endTime: _currentSession!.endTime,
          description: _sessionDescription,
          graceMinutes: _graceMinutes,
          isActive: _currentSession!.isActive,
          createdAt: _currentSession!.createdAt,
        );

        // Update the session in the controller's list
        final sessionIndex = attendanceController.sessions.indexWhere(
          (s) => s.id == _currentSession!.id,
        );
        if (sessionIndex != -1) {
          attendanceController.sessions[sessionIndex] = updatedSession;
          _currentSession = updatedSession;
        }

        // Successfully updated session
      } catch (e) {
        // Error updating session details
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isWideScreen ? screenWidth * 0.85 : screenWidth * 0.95,
        height: screenHeight * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.primary.withAlpha(10)],
          ),
        ),
        child: Column(
          children: [
            // Enhanced Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.how_to_reg,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('takeAttendance'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.choir.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(40),
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Event and Date Selection with improved design
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('choirSessionDetailsLabel'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedEvent,
                                  decoration: InputDecoration(
                                    labelText: context.tr(
                                      'choirEventTypeLabel',
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.event,
                                      color: AppColors.primary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: _eventTypes
                                      .map(
                                        (event) => DropdownMenuItem(
                                          value: event,
                                          child: Text(
                                            event,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedEvent =
                                          value ?? 'Sunday Service';
                                      _sessionTitle = _selectedEvent;
                                    });
                                    _updateSessionDetails();
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: _selectDate,
                                  child: Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.grey.withAlpha(120),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                context.tr('date'),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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

                    const SizedBox(height: 16),

                    // Enhanced Search and Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('choirSearchFilterLabel'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isSelectionMode = !_isSelectionMode;
                                    if (!_isSelectionMode) {
                                      _selectedMembers.clear();
                                    }
                                  });
                                },
                                icon: Icon(
                                  _isSelectionMode
                                      ? Icons.close
                                      : Icons.checklist,
                                  color: AppColors.primary,
                                ),
                                tooltip: _isSelectionMode
                                    ? context.tr(
                                        'choirExitSelectionModeTooltip',
                                      )
                                    : context.tr(
                                        'choirEnableSelectionModeTooltip',
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: context.tr('choirSearchMembersHint'),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.primary,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                      icon: const Icon(Icons.clear),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  context.tr('choirAllFilterLabel'),
                                  null,
                                  _statusFilter == null,
                                  () => setState(() => _statusFilter = null),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context.tr('choirPresentLabel'),
                                  AttendanceStatus.present,
                                  _statusFilter == AttendanceStatus.present,
                                  () => setState(
                                    () => _statusFilter =
                                        AttendanceStatus.present,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context.tr('choirLateLabel'),
                                  AttendanceStatus.late,
                                  _statusFilter == AttendanceStatus.late,
                                  () => setState(
                                    () => _statusFilter = AttendanceStatus.late,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context.tr('choirAbsentLabel'),
                                  AttendanceStatus.absent,
                                  _statusFilter == AttendanceStatus.absent,
                                  () => setState(
                                    () =>
                                        _statusFilter = AttendanceStatus.absent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bulk Actions (shown when in selection mode)
                    if (_isSelectionMode && _selectedMembers.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(80),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.group,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${context.tr('choirBulkActionsLabel')} (${_selectedMembers.length} ${context.tr('choirSelectedLabel')})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildBulkActionChip(
                                  context.tr('choirMarkPresentLabel'),
                                  Icons.check_circle,
                                  Colors.green,
                                  () => _bulkUpdateAttendance(
                                    AttendanceStatus.present,
                                  ),
                                ),
                                _buildBulkActionChip(
                                  context.tr('choirMarkLateLabel'),
                                  Icons.access_time,
                                  Colors.orange,
                                  () => _bulkUpdateAttendance(
                                    AttendanceStatus.late,
                                  ),
                                ),
                                _buildBulkActionChip(
                                  context.tr('choirMarkAbsentLabel'),
                                  Icons.cancel,
                                  Colors.grey,
                                  () => _bulkUpdateAttendance(
                                    AttendanceStatus.absent,
                                  ),
                                ),
                                _buildBulkActionChip(
                                  context.tr('choirSelectAllVisibleLabel'),
                                  Icons.select_all,
                                  AppColors.primary,
                                  _selectAllVisible,
                                ),
                                _buildBulkActionChip(
                                  context.tr('choirClearSelectionLabel'),
                                  Icons.clear,
                                  Colors.red,
                                  () =>
                                      setState(() => _selectedMembers.clear()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quick Actions (always visible)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('quickActions'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildQuickActionChip(
                                context.tr('choirAllPresentLabel'),
                                Icons.check_circle,
                                Colors.green,
                                () => _updateAllAttendance(
                                  AttendanceStatus.present,
                                ),
                              ),
                              _buildQuickActionChip(
                                context.tr('choirAllLateLabel'),
                                Icons.access_time,
                                Colors.orange,
                                () =>
                                    _updateAllAttendance(AttendanceStatus.late),
                              ),
                              _buildQuickActionChip(
                                context.tr('choirAllAbsentLabel'),
                                Icons.cancel,
                                Colors.grey,
                                () => _updateAllAttendance(
                                  AttendanceStatus.absent,
                                ),
                              ),
                              _buildQuickActionChip(
                                context.tr('choirResetAllLabel'),
                                Icons.refresh,
                                AppColors.primary,
                                () {
                                  setState(() {
                                    _attendance.clear();
                                    _selectedMembers.clear();
                                  });
                                },
                              ),
                              _buildQuickActionChip(
                                context.tr('choirSmartDefaultsLabel'),
                                Icons.auto_awesome,
                                Colors.purple,
                                _applySmartDefaults,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Enhanced Members List
                    SizedBox(
                      height: 400,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withAlpha(60)),
                        ),
                        child: Column(
                          children: [
                            // Members Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr('members'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const Spacer(),
                                  Consumer<ChoirController>(
                                    builder: (context, controller, child) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(
                                            40,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${controller.choirMembers.length} ${context.tr('choirTotalLabel')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Members List
                            Expanded(
                              child: Consumer<ChoirController>(
                                builder: (context, controller, child) {
                                  final allMembers = controller.choirMembers;
                                  final filteredMembers = _getFilteredMembers(
                                    allMembers,
                                  );

                                  if (allMembers.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.people_outline,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            context.tr('choirNoMembersFound'),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (filteredMembers.isEmpty &&
                                      _searchQuery.isNotEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.search_off,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            context.tr(
                                              'choirNoMembersMatchingSearch',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: filteredMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = filteredMembers[index];
                                      final status =
                                          _attendance[member.id] ??
                                          AttendanceStatus.absent;
                                      final isSelected = _selectedMembers
                                          .contains(member.id);

                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary.withAlpha(20)
                                              : Colors.grey[25],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary.withAlpha(
                                                    100,
                                                  )
                                                : _getAttendanceColor(
                                                    status,
                                                  ).withAlpha(60),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: ExpansionTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          leading: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_isSelectionMode) ...[
                                                Checkbox(
                                                  value: isSelected,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        _selectedMembers.add(
                                                          member.id,
                                                        );
                                                      } else {
                                                        _selectedMembers.remove(
                                                          member.id,
                                                        );
                                                      }
                                                    });
                                                  },
                                                  activeColor:
                                                      AppColors.primary,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              _buildMemberAvatar(
                                                member,
                                                status,
                                              ),
                                            ],
                                          ),
                                          title: Text(
                                            _getMemberDisplayName(member),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${context.tr('choirIdLabelPrefix')} ${member.registrationNumber}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getAttendanceColor(status),
                                                  _getAttendanceColor(
                                                    status,
                                                  ).withAlpha(200),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getStatusIcon(status),
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _getStatusText(status),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                16,
                                                0,
                                                16,
                                                16,
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.grey.withAlpha(
                                                    40,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      _buildEnhancedStatusButton(
                                                        context.tr(
                                                          'choirPresentLabel',
                                                        ),
                                                        Icons.check_circle,
                                                        AttendanceStatus
                                                            .present,
                                                        member.id,
                                                      ),
                                                      _buildEnhancedStatusButton(
                                                        context.tr(
                                                          'choirLateLabel',
                                                        ),
                                                        Icons.access_time,
                                                        AttendanceStatus.late,
                                                        member.id,
                                                      ),
                                                      _buildEnhancedStatusButton(
                                                        context.tr(
                                                          'choirAbsentLabel',
                                                        ),
                                                        Icons.cancel,
                                                        AttendanceStatus.absent,
                                                        member.id,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  TextField(
                                                    decoration: InputDecoration(
                                                      labelText: context.tr(
                                                        'choirNotesOptionalLabel',
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      isDense: true,
                                                      prefixIcon: const Icon(
                                                        Icons.note_alt,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      _notes[member.id] = value;
                                                    },
                                                    maxLines: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Enhanced Session Summary
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(30),
                    AppColors.primary.withAlpha(10),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('choirSessionSummaryLabel'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEnhancedSummaryItem(
                        context.tr('choirPresentLabel'),
                        _attendance.values
                            .where((s) => s == AttendanceStatus.present)
                            .length,
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildEnhancedSummaryItem(
                        context.tr('choirLateLabel'),
                        _attendance.values
                            .where((s) => s == AttendanceStatus.late)
                            .length,
                        Colors.orange,
                        Icons.access_time,
                      ),
                      _buildEnhancedSummaryItem(
                        context.tr('choirAbsentLabel'),
                        _attendance.values
                            .where((s) => s == AttendanceStatus.absent)
                            .length,
                        Colors.grey,
                        Icons.cancel,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: Text(context.tr('cancel')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.withAlpha(120)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveAttendance,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading
                            ? context.tr('choirSavingLabel')
                            : context.tr('choirSaveAttendanceLabel'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Color _getAttendanceColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.grey;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return context.tr('choirPresentLabel');
      case AttendanceStatus.late:
        return context.tr('choirLateLabel');
      case AttendanceStatus.absent:
        return context.tr('choirAbsentLabel');
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);

    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final attendanceController = Provider.of<AttendanceController>(
      context,
      listen: false,
    );
    final authController = Provider.of<AuthController>(context, listen: false);
    const uuid = Uuid();

    try {
      // First create the session with current event type and title
      final sessionSuccess = await attendanceController.createAttendanceSession(
        choirId: widget.choir.id,
        title: _sessionTitle, // Use current title based on selected event type
        eventType: _eventTypeMap[_selectedEvent] ?? EventType.other,
        leaderId: authController.currentUser?.id ?? 'unknown',
        date: _selectedDate,
        startTime: _selectedTime,
        description: _sessionDescription,
        graceMinutes: _graceMinutes,
      );

      final createdSession = attendanceController.lastCreatedSession;
      if (!sessionSuccess || createdSession == null) {
        throw Exception('Failed to create attendance session');
      }
      // Records must reference the session that was actually created.
      final sessionId = createdSession.id;

      // Create attendance records for all members
      final attendanceRecords = <AttendanceModel>[];
      final now = DateTime.now();

      for (var member in choirController.choirMembers) {
        final status = _attendance[member.id] ?? AttendanceStatus.absent;
        final note = _notes[member.id] ?? '';

        final record = AttendanceModel(
          id: uuid.v4(),
          sessionId: sessionId,
          memberId: member.id,
          userId: member.userId,
          choirId: widget.choir.id,
          eventDate: _selectedDate,
          status: status,
          recordedBy: authController.currentUser?.id ?? 'unknown',
          recordedAt: now,
          notes: note.isEmpty ? _selectedEvent : note,
        );

        attendanceRecords.add(record);
      }

      Logger.debug(
        'About to save ${attendanceRecords.length} attendance records',
      );
      for (var record in attendanceRecords) {
        Logger.debug(
          'Record - Member: ${record.memberId}, Status: ${record.status}, Choir: ${record.choirId}',
        );
      }

      // Save attendance records
      final success = await attendanceController.recordAttendanceBatch(
        attendanceRecords,
      );

      Logger.debug('Attendance save success: $success');

      if (success) {
        final present = _attendance.values
            .where((status) => status == AttendanceStatus.present)
            .length;
        final late = _attendance.values
            .where((status) => status == AttendanceStatus.late)
            .length;
        final absent = _attendance.values
            .where((status) => status == AttendanceStatus.absent)
            .length;
        final total = _attendance.length;

        // Refresh attendance data
        await attendanceController.loadChoirAttendance(widget.choir.id);
        await attendanceController.loadAttendanceSessions(
          choirId: widget.choir.id,
        );

        // Call the callback to refresh the parent screen
        widget.onAttendanceSaved?.call();

        if (mounted) {
          Navigator.of(context).pop();
        }

        Get.snackbar(
          context.tr('choirAttendanceSavedTitle'),
          '${context.tr('choirRecordedPrefix')} $present ${context.tr('choirPresentLabel').toLowerCase()}, $late ${context.tr('choirLateLabel').toLowerCase()}, $absent ${context.tr('choirAbsentLabel').toLowerCase()} (${context.tr('choirTotalLabel')}: $total) ${context.tr('choirForEventSuffix')} $_selectedEvent',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          context.tr('error'),
          context.tr('choirSaveAttendanceFailedMessage'),
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        context.tr('error'),
        '${context.tr('choirErrorSavingAttendancePrefix')} $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getMemberDisplayName(ChoirMemberModel member) {
    final user = widget.userCache[member.userId];
    if (user != null) {
      return user.fullName;
    }

    // Fallback to registration number if user data is not available
    return '${context.tr('choirMemberFallbackPrefix')} ${member.registrationNumber}';
  }

  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.absent:
        return Icons.cancel;
    }
  }

  Widget _buildEnhancedStatusButton(
    String label,
    IconData icon,
    AttendanceStatus status,
    String memberId,
  ) {
    final isSelected = _attendance[memberId] == status;
    final color = _getAttendanceColor(status);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _attendance[memberId] = status;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [color, color.withAlpha(200)])
                : null,
            color: isSelected ? null : color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withAlpha(100),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSummaryItem(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withAlpha(180)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Search and Filter Methods
  List<ChoirMemberModel> _getFilteredMembers(List<ChoirMemberModel> members) {
    final filtered = members.where((member) {
      final memberName = _getMemberDisplayName(member).toLowerCase();
      final registrationNumber = member.registrationNumber.toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      // Search filter
      final matchesSearch =
          _searchQuery.isEmpty ||
          memberName.contains(searchLower) ||
          registrationNumber.contains(searchLower);

      // Status filter
      final memberStatus = _attendance[member.id] ?? AttendanceStatus.absent;
      final matchesStatus =
          _statusFilter == null || memberStatus == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    // Sort by name for better UX
    filtered.sort(
      (a, b) => _getMemberDisplayName(a).compareTo(_getMemberDisplayName(b)),
    );

    return filtered;
  }

  Widget _buildFilterChip(
    String label,
    AttendanceStatus? status,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final color = status != null
        ? _getAttendanceColor(status)
        : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withAlpha(100),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != null) ...[
              Icon(_getStatusIcon(status), color: color, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bulk Action Methods
  Widget _buildBulkActionChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bulkUpdateAttendance(AttendanceStatus status) {
    setState(() {
      for (final memberId in _selectedMembers) {
        _attendance[memberId] = status;
      }
      _selectedMembers.clear();
      _isSelectionMode = false;
    });

    // Show feedback
    final statusText = _getStatusText(status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${context.tr('choirMarkedPrefix')} ${_selectedMembers.length} ${context.tr('members').toLowerCase()} ${context.tr('choirAsStatusSuffix')} $statusText',
        ),
        backgroundColor: _getAttendanceColor(status),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _selectAllVisible() {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final filteredMembers = _getFilteredMembers(choirController.choirMembers);

    setState(() {
      for (final member in filteredMembers) {
        _selectedMembers.add(member.id);
      }
    });
  }

  void _updateAllAttendance(AttendanceStatus status) {
    setState(() {
      final choirController = Provider.of<ChoirController>(
        context,
        listen: false,
      );
      final members = choirController.choirMembers;

      for (final member in members) {
        _attendance[member.id] = status;
      }
    });

    _saveAnimationController.forward().then((_) {
      _saveAnimationController.reverse();
    });
  }

  void _applySmartDefaults() {
    // Simulate smart defaults based on historical attendance patterns
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final members = choirController.choirMembers;

    setState(() {
      for (final member in members) {
        // Simple logic: members with good attendance history default to present
        // This would normally use real historical data
        final attendanceRate = member.attendanceRate;
        if (attendanceRate > 0.8) {
          _attendance[member.id] = AttendanceStatus.present;
        } else if (attendanceRate > 0.5) {
          _attendance[member.id] = AttendanceStatus.late;
        } else {
          _attendance[member.id] = AttendanceStatus.absent;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('choirSmartDefaultsAppliedMessage')),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMemberAvatar(ChoirMemberModel member, AttendanceStatus status) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getAttendanceColor(status),
            _getAttendanceColor(status).withAlpha(180),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getAttendanceColor(status).withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          member.registrationNumber.length > 2
              ? member.registrationNumber.substring(
                  member.registrationNumber.length - 2,
                )
              : member.registrationNumber,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
