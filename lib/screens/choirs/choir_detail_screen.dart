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
import '../../utils/logger.dart';
import '../members/edit_member_screen.dart';
import '../members/member_detail_screen.dart';
import '../messaging/message_screen.dart';
import '../reports/report_detail_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/choir_settings_screen.dart';
import 'edit_choir_screen.dart';

class ChoirDetailScreen extends StatefulWidget {
  
  const ChoirDetailScreen({
    super.key,
    required this.choir,
  });
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
      final choirController = Provider.of<ChoirController>(context, listen: false);
      choirController.selectChoir(widget.choir);
      _loadMemberUserData();
      _loadStatistics();
      _loadRecentActivities();
    });
  }

  Future<void> _loadMemberUserData() async {
    try {
      final choirController = Provider.of<ChoirController>(context, listen: false);
      final members = choirController.choirMembers;
      
      for (var member in members) {
        if (member.userId.isNotEmpty && !_userCache.containsKey(member.userId)) {
          // Try to get user from service
          final user = await _userService.getUserById(member.userId);
          if (user != null) {
            _userCache[member.userId] = user;
          } else {
            // Create sample user data if service fails (for local demo)
            _userCache[member.userId] = _createSampleUser(member.userId, member.registrationNumber);
          }
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently handle errors to avoid flooding console
      if (!mounted) return;
      final choirController = Provider.of<ChoirController>(context, listen: false);
      final members = choirController.choirMembers;
      
      // Fallback: create sample users for all members
      for (var member in members) {
        if (member.userId.isNotEmpty && !_userCache.containsKey(member.userId)) {
          _userCache[member.userId] = _createSampleUser(member.userId, member.registrationNumber);
        }
      }
    }
  }
  
  UserModel _createSampleUser(String userId, String registrationNumber) {
    // Generate sample names based on registration number
    final sampleNames = [
      'John Doe', 'Jane Smith', 'Michael Johnson', 'Sarah Williams', 'David Brown',
      'Emily Davis', 'Christopher Wilson', 'Jessica Miller', 'Matthew Garcia', 'Ashley Martinez',
      'Daniel Rodriguez', 'Amanda Lopez', 'James Anderson', 'Jennifer Taylor', 'Robert Thomas'
    ];
    
    final index = registrationNumber.hashCode.abs() % sampleNames.length;
    final fullName = sampleNames[index];
    
    return UserModel(
      id: userId,
      email: '${fullName.toLowerCase().replaceAll(' ', '.')}@example.com',
      fullName: fullName,
      phoneNumber: '+1234567890',
      role: UserRole.choirMember,
      createdAt: DateTime.now(),
      isActive: true,
      suggestedChoir: 'St. Joseph Choir',
    );
  }

  Future<void> _loadStatistics() async {
    // Load attendance data first
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
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
    final activities = await _activityService.getChoirActivities(widget.choir.id, limit: 5);
    
    if (mounted) {
      setState(() {
        _recentActivities = activities;
      });
    }
  }

  // Calculate real attendance rate
  Future<double> _calculateAttendanceRate() async {
    try {
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      
      // Get attendance records for this choir
      final attendanceRecords = attendanceController.attendanceRecords
          .where((record) => record.choirId == widget.choir.id)
          .toList();
      
      Logger.debug('Calculating attendance rate for choir ${widget.choir.id}');
      Logger.debug('Found ${attendanceRecords.length} attendance records');
      Logger.debug('All records: ${attendanceController.attendanceRecords.length}');

      if (attendanceRecords.isEmpty) {
        Logger.debug('No attendance records found for this choir');
        // Return -1 to indicate no data (we'll handle this in the UI)
        return -1.0;
      }

      // Calculate attendance rate from actual records
      final presentCount = attendanceRecords.where((r) =>
          r.status == AttendanceStatus.present || r.status == AttendanceStatus.late).length;
      final totalRecords = attendanceRecords.length;

      final rate = totalRecords > 0 ? (presentCount / totalRecords) * 100.0 : 0.0;

      Logger.debug('Present/Late: $presentCount, Total: $totalRecords, Rate: $rate%');

      return rate;
    } catch (e) {
      Logger.error('Error calculating attendance rate', e);
      return -1.0; // Return -1 to indicate error/no data
    }
  }

  // Calculate total sessions/events count
  Future<int> _calculateTotalSessions() async {
    try {
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      
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
      appBar: AppBar(
        title: Text(widget.choir.name),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        actions: [
          Consumer<AuthController>(
            builder: (context, authController, child) {
              final canEdit = authController.isAdmin || 
                             widget.choir.leaderId == authController.currentUser?.id ||
                             widget.choir.adminId == authController.currentUser?.id;
              
              if (!canEdit) return const SizedBox.shrink();
              
              return PopupMenuButton<String>(
                onSelected: _handleAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit Choir'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Text('Settings'),
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
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Members'),
            Tab(text: 'Attendance'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMembersTab(),
          _buildAttendanceTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: Consumer<AuthController>(
        builder: (context, authController, child) {
          final canManage = authController.isAdmin || 
                           widget.choir.leaderId == authController.currentUser?.id ||
                           widget.choir.adminId == authController.currentUser?.id;
          
          if (!canManage) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: _showAddMemberDialog,
            tooltip: 'Add Member',
            child: const Icon(Icons.person_add),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: widget.choir.imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            widget.choir.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 30,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.choir.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.choir.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.choir.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow('Created', _formatDate(widget.choir.createdAt)),
            const SizedBox(height: 8),
            _buildInfoRow('Status', widget.choir.isActive ? 'Active' : 'Inactive'),
            const SizedBox(height: 8),
            _buildInfoRow('Members', widget.choir.memberCount.toString()),
            if (widget.choir.location != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Location', widget.choir.location!),
            ],
            if (widget.choir.schedule != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Schedule', widget.choir.schedule!),
            ],
            // Location section
            if (_getCurrentChoir().country != null && _getCurrentChoir().country!.isNotEmpty ||
                _getCurrentChoir().diocese != null && _getCurrentChoir().diocese!.isNotEmpty ||
                _getCurrentChoir().parish != null && _getCurrentChoir().parish!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_getCurrentChoir().country != null && _getCurrentChoir().country!.isNotEmpty) ...[
              _buildLocationRow('Country', _getCurrentChoir().country!, _getCountryFlag(_getCurrentChoir().country!)),
              const SizedBox(height: 8),
            ],
            if (_getCurrentChoir().diocese != null && _getCurrentChoir().diocese!.isNotEmpty) ...[
              _buildLocationRow('Diocese', _getCurrentChoir().diocese!, '⛪'),
              const SizedBox(height: 8),
            ],
            if (_getCurrentChoir().parish != null && _getCurrentChoir().parish!.isNotEmpty) ...[
              _buildLocationRow('Parish', _getCurrentChoir().parish!, '🏛️'),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatisticItem(
                    title: 'Total Members',
                    value: widget.choir.memberCount.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatisticItem(
                    title: 'Active',
                    value: '${widget.choir.memberCount}', // This would come from real data
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatisticItem(
                    title: 'Attendance Rate',
                    value: _attendanceRate < 0 ? 'No data' : '${_attendanceRate.round()}%',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatisticItem(
                    title: 'Events',
                    value: '$_totalSessions',
                    icon: Icons.event,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _showAllActivitiesDialog();
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentActivities.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ..._recentActivities.map((activity) => _buildActivityItem(
                icon: activity.icon,
                title: activity.title,
                subtitle: activity.description,
                time: activity.timeAgo,
              )),
          ],
        ),
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
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(20),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
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
    return 'Member ${member.registrationNumber}';
  }

  // Enhanced Members Tab Helper Methods
  Widget _buildMembersHeader(List<ChoirMemberModel> allMembers) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${allMembers.length} Members',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (allMembers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getMembersStatusSummary(allMembers),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
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
              icon: Icon(_isSearchActive ? Icons.search_off : Icons.search),
            ),
        ],
      ),
    );
  }

  String _getMembersStatusSummary(List<ChoirMemberModel> members) {
    final active = members.where((m) => m.status == MemberStatus.active).length;
    final inactive = members.where((m) => m.status == MemberStatus.inactive).length;
    final suspended = members.where((m) => m.status == MemberStatus.suspended).length;
    
    final List<String> parts = [];
    if (active > 0) parts.add('$active active');
    if (inactive > 0) parts.add('$inactive inactive');
    if (suspended > 0) parts.add('$suspended suspended');
    
    return parts.join(' • ');
  }

  Widget _buildMembersFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_isSearchActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Status',
                  isSelected: _selectedStatusFilter == 'all',
                  onSelected: () => setState(() => _selectedStatusFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Active',
                  isSelected: _selectedStatusFilter == 'active',
                  onSelected: () => setState(() => _selectedStatusFilter = 'active'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Inactive',
                  isSelected: _selectedStatusFilter == 'inactive',
                  onSelected: () => setState(() => _selectedStatusFilter = 'inactive'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Suspended',
                  isSelected: _selectedStatusFilter == 'suspended',
                  onSelected: () => setState(() => _selectedStatusFilter = 'suspended'),
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
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primary.withAlpha(50),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  List<ChoirMemberModel> _filterMembers(List<ChoirMemberModel> members) {
    final filtered = members.where((member) {
      // Status filter
      if (_selectedStatusFilter != 'all') {
        final statusMatch = member.status.toString().split('.').last == _selectedStatusFilter;
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
        if (a.status == MemberStatus.inactive && b.status == MemberStatus.suspended) return -1;
        if (a.status == MemberStatus.suspended && b.status == MemberStatus.inactive) return 1;
      }
      
      // Then by name
      return _getMemberDisplayName(a).compareTo(_getMemberDisplayName(b));
    });

    return filtered;
  }

  Widget _buildEmptyMembersState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No members yet', 
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Add your first member to get started',
               style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No members found', 
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filters',
               style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedStatusFilter = 'all';
              });
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<ChoirMemberModel> members) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (user?.email != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user!.email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
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
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 16),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'message',
                        child: Row(
                          children: [
                            Icon(Icons.message, size: 16),
                            SizedBox(width: 8),
                            Text('Send Message'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem(
                    icon: Icons.badge_outlined,
                    label: 'Reg. #',
                    value: member.registrationNumber,
                  ),
                  const SizedBox(width: 24),
                  _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'Joined',
                    value: _formatDate(member.joinDate),
                  ),
                  if (member.outstandingFees > 0) ...[
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      icon: Icons.warning,
                      label: 'Fees',
                      value: '\$${member.outstandingFees.toStringAsFixed(2)}',
                      color: Colors.orange,
                    ),
                  ],
                ],
              ),
            ],
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
      return parts.first.substring(0, parts.first.length > 2 ? 2 : parts.first.length).toUpperCase();
    }
    return 'M';
  }

  Widget _buildStatusChip(MemberStatus status) {
    final color = _getStatusColor(status);
    final statusText = status.toString().split('.').last;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRoleChip(MemberRole role) {
    final color = _getRoleColor(role);
    final roleText = role.toString().split('.').last;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Text(
        roleText.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final itemColor = color ?? Colors.grey[600];
    
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
              style: TextStyle(
                fontSize: 10,
                color: itemColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: itemColor,
                fontWeight: FontWeight.w600,
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
          padding: const EdgeInsets.all(16),
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
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up, color: AppColors.success, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            _attendanceRate < 0 ? 'No data' : '${_attendanceRate.round()}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Attendance',
                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event, color: AppColors.primary, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            '${attendanceController.sessions.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Sessions',
                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
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
                          icon: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                          label: const Text(
                            'Take Attendance',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewAttendanceHistory(),
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text(
                            'View History',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                          icon: const Icon(Icons.message, color: Colors.white, size: 16),
                          label: const Text(
                            'Message All',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewReports(),
                          icon: const Icon(Icons.analytics, size: 16),
                          label: const Text(
                            'View Reports',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                  const Text(
                    'Recent Sessions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _viewAttendanceHistory(),
                    child: const Text(
                      'View All',
                      style: TextStyle(fontSize: 12),
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
                            itemCount: attendanceController.sessions.length.clamp(0, 5),
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
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }
  
  Widget _buildEmptySessionsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance sessions yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take attendance to start tracking',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Map<String, dynamic> _getSessionAttendanceDataSync(String sessionId) {
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    
    // Use already loaded data only - don't trigger async operations during build
    final sessionRecords = attendanceController.attendanceRecords
        .where((r) => r.sessionId == sessionId)
        .toList();
    
    Logger.debug('Getting attendance for session $sessionId');
    Logger.debug('Found ${sessionRecords.length} records for this session');
    Logger.debug('Total attendance records: ${attendanceController.attendanceRecords.length}');

    // Debug: Show all unique session IDs in attendance records
    final allSessionIds = attendanceController.attendanceRecords.map((r) => r.sessionId).toSet();
    Logger.debug('All session IDs in attendance records: $allSessionIds');
    
    final presentCount = sessionRecords.where((r) => r.status == AttendanceStatus.present).length;
    final lateCount = sessionRecords.where((r) => r.status == AttendanceStatus.late).length;
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
    Logger.debug('Building session card for session ${session.id} - ${session.title}');
    final attendanceData = _getSessionAttendanceDataSync(session.id);
    final attendanceRate = attendanceData['rate'] as int;
    final presentCount = attendanceData['present'] as int;
    final lateCount = attendanceData['late'] as int;
    final totalCount = attendanceData['total'] as int;
    
    return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPercentageColor(attendanceRate).withValues(alpha: 0.1),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${session.date.day}/${session.date.month}/${session.date.year}',
              style: const TextStyle(fontSize: 12),
            ),
            if (totalCount > 0)
              Text(
                '$presentCount present, $lateCount late of $totalCount',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$attendanceRate%',
            style: TextStyle(
              color: _getPercentageColor(attendanceRate),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        onTap: () => _viewSessionDetails(session),
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
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    attendanceController.selectSession(session);
    
    // Get attendance data for this session
    final attendanceData = _getSessionAttendanceDataSync(session.id);
    final attendanceRecords = attendanceController.attendanceRecords
        .where((record) => record.sessionId == session.id)
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getEventTypeIcon(session.eventType), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Date: ${session.date.day}/${session.date.month}/${session.date.year}'),
              if (session.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Description: ${session.description}'),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('${attendanceData['present']}', 
                             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        const Text('Present', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('${attendanceData['late']}', 
                             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                        const Text('Late', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('${attendanceData['total'] - attendanceData['present'] - attendanceData['late']}', 
                             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const Text('Absent', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('${attendanceData['rate']}%', 
                             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _getPercentageColor(attendanceData['rate']))),
                        const Text('Rate', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Attendance Records:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: attendanceRecords.isEmpty
                    ? const Center(child: Text('No attendance records found'))
                    : ListView.builder(
                        itemCount: attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record = attendanceRecords[index];
                          final memberInfo = _getMemberDisplayInfo(record);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getAttendanceColor(record.status),
                                radius: 16,
                                child: Text(
                                  _getStatusText(record.status)[0],
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              title: Text(memberInfo['name'] ?? 'Unknown Member'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('ID: ${memberInfo['registrationId']}', 
                                       style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  if (record.notes?.isNotEmpty == true) 
                                    Text(record.notes!, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getAttendanceColor(record.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(record.status),
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard(
                  title: 'Membership',
                  subtitle: 'Member analytics',
                  icon: Icons.people,
                  color: Colors.blue,
                  onTap: () => _navigateToReport('membership'),
                ),
                _buildReportCard(
                  title: 'Attendance',
                  subtitle: 'Attendance reports',
                  icon: Icons.fact_check,
                  color: Colors.green,
                  onTap: () => _navigateToReport('attendance'),
                ),
                _buildReportCard(
                  title: 'Payments',
                  subtitle: 'Financial reports',
                  icon: Icons.payment,
                  color: Colors.purple,
                  onTap: () => _navigateToReport('payments'),
                ),
                _buildReportCard(
                  title: 'Activities',
                  subtitle: 'Activity summary',
                  icon: Icons.event,
                  color: Colors.orange,
                  onTap: () => _navigateToReport('activities'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReportsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Comprehensive Analytics'),
              subtitle: const Text('Full choir performance report'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _navigateToReport('comprehensive'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Growth Trends'),
              subtitle: const Text('Member and activity growth'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _navigateToReport('trends'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Export choir data to Excel/PDF/CSV'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showDirectExportOptions(),
            ),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReport(String reportType) async {
    final reportController = Provider.of<ReportController>(context, listen: false);

    // Show loading dialog
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
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
          Get.to(() => ReportDetailScreen(
            reportType: actualReportType,
            reportData: reportController.currentReport,
          ));
        }
      } else {
        Get.snackbar(
          'No Data',
          'No data available for this report',
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
      }

    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        'Error',
        'Failed to generate report: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _showDirectExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export ${widget.choir.name} Data',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Comprehensive choir overview'),
              onTap: () {
                Navigator.pop(context);
                _directExport('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              subtitle: const Text('Detailed spreadsheet with all data'),
              onTap: () {
                Navigator.pop(context);
                _directExport('excel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: const Text('Export as CSV'),
              subtitle: const Text('Comma-separated values file'),
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

  void _showExportOptions(ReportController reportController) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export ${widget.choir.name} Data',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Generate PDF report'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('pdf', reportController);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              subtitle: const Text('Generate Excel spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('excel', reportController);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: const Text('Export as CSV'),
              subtitle: const Text('Generate CSV file'),
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
    final reportController = Provider.of<ReportController>(context, listen: false);

    // Show loading dialog
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
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
          'No Data',
          'No data available for export',
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
      }

    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        'Export Error',
        'Failed to prepare data for export: $e',
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
          filePath = await exportService.exportReportToCSV(reportData, reportType);
          
          if (filePath != null) {
            Get.snackbar(
              'Export Success',
              'CSV file saved to: $filePath',
              backgroundColor: AppColors.success,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              'Export Failed',
              'Failed to save CSV file',
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
                'Coming Soon',
                'PDF export for $reportType will be available in future update',
                backgroundColor: AppColors.info,
                colorText: Colors.white,
              );
              return;
          }
          
          if (filePath != null) {
            Get.snackbar(
              'Export Success',
              'PDF file saved to: $filePath',
              backgroundColor: AppColors.success,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              'Export Failed',
              'Failed to save PDF file',
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
              filePath = await exportService.exportMembershipToExcel(reportData);
              break;
            case 'attendance':
              filePath = await exportService.exportAttendanceToExcel(reportData);
              break;
            case 'financial':
              filePath = await exportService.exportFinancialToExcel(reportData);
              break;
            case 'overview':
            case 'comprehensive':
            case 'choir_overview':
              // For overview reports, export as membership report with full data
              filePath = await exportService.exportMembershipToExcel(reportData);
              break;
            default:
              Get.snackbar(
                'Coming Soon',
                'Excel export for $reportType will be available in future update',
                backgroundColor: AppColors.info,
                colorText: Colors.white,
              );
              return;
          }
          
          if (filePath != null) {
            Get.snackbar(
              'Export Success',
              'Excel file saved to: $filePath',
              backgroundColor: AppColors.success,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              'Export Failed',
              'Failed to save Excel file',
              backgroundColor: AppColors.error,
              colorText: Colors.white,
            );
          }
          break;
      }
    } catch (e) {
      Get.snackbar(
        'Export Error',
        'Export failed: $e',
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
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLocationRow(String label, String value, String icon) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
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
    
    return countryFlags[country] ?? '🌍'; // Default globe emoji if country not found
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get the current choir - uses the selected choir from controller if available,
  /// otherwise falls back to the original widget choir
  ChoirModel _getCurrentChoir() {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    return choirController.selectedChoir ?? widget.choir;
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'edit':
        final result = await Get.to(() => EditChoirScreen(choir: widget.choir));
        if (result == true) {
          // Refresh the current screen or reload choir data
          final choirController = Provider.of<ChoirController>(context, listen: false);
          await choirController.loadChoirs();
          
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
        Get.to(() => MessageScreen(
          member: member,
          choir: widget.choir,
        ));
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
          }
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
        title: const Text('Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'Member Name/ID',
                hintText: 'Enter member name or ID',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: regNumberController,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
                hintText: 'e.g., CM001',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              userIdController.dispose();
              regNumberController.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (userIdController.text.isNotEmpty && regNumberController.text.isNotEmpty) {
                Navigator.of(context).pop();
                _addMember(userIdController.text, regNumberController.text);
              }
              userIdController.dispose();
              regNumberController.dispose();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _addMember(String userId, String registrationNumber) async {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    final success = await choirController.addMemberToChoir(
      userId: userId,
      choirId: widget.choir.id,
      registrationNumber: registrationNumber,
    );
    
    if (success) {
      Get.snackbar(
        'Success',
        'Member added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        choirController.errorMessage ?? 'Failed to add member',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void _removeMember(ChoirMemberModel member) async {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    final success = await choirController.removeMemberFromChoir(
      memberId: member.id,
      choirId: widget.choir.id,
    );
    
    if (success) {
      Get.snackbar(
        'Success',
        'Member removed successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        choirController.errorMessage ?? 'Failed to remove member',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showRemoveMemberDialog(ChoirMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
          'Are you sure you want to remove this member from the choir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMember(member);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
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
          final attendanceController = Provider.of<AttendanceController>(context, listen: false);
          
          // Wait a bit to ensure data is saved to SharedPreferences
          await Future.delayed(const Duration(milliseconds: 100));
          
          await attendanceController.loadChoirAttendance(widget.choir.id);
          await attendanceController.loadAttendanceSessions(choirId: widget.choir.id);
          
          // Then recalculate statistics
          await _loadStatistics();
          
          Logger.debug('Statistics refreshed after attendance save');
          Logger.debug('Loaded ${attendanceController.sessions.length} sessions');
        },
      ),
    );
  }
  
  void _viewAttendanceHistory() {
    // Navigate to a comprehensive attendance history screen
    _showAttendanceHistory();
  }

  void _messageAllMembers() {
    Get.to(() => MessageScreen(
      choir: widget.choir,
    ));
  }

  void _viewReports() {
    // Navigate to reports screen
    Get.to(() => const ReportsScreen());
  }
  
  void _showAttendanceHistory() {
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    
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
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }
  
  // Helper method to get member display info
  Map<String, String> _getMemberDisplayInfo(AttendanceModel record) {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
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
    final displayName = user?.fullName ?? 'Unknown Member';
    final registrationId = member.registrationNumber;
    
    return {
      'name': displayName,
      'registrationId': registrationId,
    };
  }

  void _showAllActivitiesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                      'All Activities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                const Divider(),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<ActivityModel>>(
                    future: _activityService.getChoirActivities(widget.choir.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading activities: ${snapshot.error}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }
                      
                      final activities = snapshot.data ?? [];
                      
                      if (activities.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No activities found',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
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
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                                child: Icon(
                                  activity.icon,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                activity.title,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activity.description),
                                  const SizedBox(height: 4),
                                  Text(
                                    activity.timeAgo,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
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
  
  const AttendanceDialog({super.key, required this.choir, this.onAttendanceSaved, required this.userCache});
  final ChoirModel choir;
  final VoidCallback? onAttendanceSaved;
  final Map<String, UserModel> userCache;
  
  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}


class _AttendanceDialogState extends State<AttendanceDialog> with TickerProviderStateMixin {
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
    final choirController = Provider.of<ChoirController>(context, listen: false);
    final members = choirController.choirMembers;
    
    for (var member in members) {
      _attendance[member.id] = AttendanceStatus.absent;
    }
  }
  
  Future<void> _updateSessionDetails() async {
    if (_currentSession != null) {
      final attendanceController = Provider.of<AttendanceController>(context, listen: false);
      
      try {
        // Update the session with new details
        final updatedSession = AttendanceSessionModel(
          id: _currentSession!.id,
          choirId: _currentSession!.choirId,
          title: _sessionTitle, // Use updated title
          eventType: _eventTypeMap[_selectedEvent] ?? EventType.other, // Use updated event type
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
        final sessionIndex = attendanceController.sessions.indexWhere((s) => s.id == _currentSession!.id);
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
            colors: [
              Colors.white,
              AppColors.primary.withAlpha(10),
            ],
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
                    child: const Icon(Icons.how_to_reg, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Take Attendance',
                          style: TextStyle(
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
                            'Session Details',
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
                                    labelText: 'Event Type',
                                    prefixIcon: const Icon(Icons.event, color: AppColors.primary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: _eventTypes.map((event) =>
                                    DropdownMenuItem(
                                      value: event, 
                                      child: Text(event, style: const TextStyle(fontSize: 14)),
                                    )
                                  ).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedEvent = value ?? 'Sunday Service';
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey.withAlpha(120)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Text('Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              Text(
                                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                              const Icon(Icons.search, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Search & Filter',
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
                                  _isSelectionMode ? Icons.close : Icons.checklist,
                                  color: AppColors.primary,
                                ),
                                tooltip: _isSelectionMode ? 'Exit Selection Mode' : 'Enable Selection Mode',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search members...',
                              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
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
                                  'All',
                                  null,
                                  _statusFilter == null,
                                  () => setState(() => _statusFilter = null),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'Present',
                                  AttendanceStatus.present,
                                  _statusFilter == AttendanceStatus.present,
                                  () => setState(() => _statusFilter = AttendanceStatus.present),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'Late',
                                  AttendanceStatus.late,
                                  _statusFilter == AttendanceStatus.late,
                                  () => setState(() => _statusFilter = AttendanceStatus.late),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'Absent',
                                  AttendanceStatus.absent,
                                  _statusFilter == AttendanceStatus.absent,
                                  () => setState(() => _statusFilter = AttendanceStatus.absent),
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
                          border: Border.all(color: AppColors.primary.withAlpha(80)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.group, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Bulk Actions (${_selectedMembers.length} selected)',
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
                                  'Mark Present',
                                  Icons.check_circle,
                                  Colors.green,
                                  () => _bulkUpdateAttendance(AttendanceStatus.present),
                                ),
                                _buildBulkActionChip(
                                  'Mark Late',
                                  Icons.access_time,
                                  Colors.orange,
                                  () => _bulkUpdateAttendance(AttendanceStatus.late),
                                ),
                                _buildBulkActionChip(
                                  'Mark Absent',
                                  Icons.cancel,
                                  Colors.grey,
                                  () => _bulkUpdateAttendance(AttendanceStatus.absent),
                                ),
                                _buildBulkActionChip(
                                  'Select All Visible',
                                  Icons.select_all,
                                  AppColors.primary,
                                  _selectAllVisible,
                                ),
                                _buildBulkActionChip(
                                  'Clear Selection',
                                  Icons.clear,
                                  Colors.red,
                                  () => setState(() => _selectedMembers.clear()),
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
                            'Quick Actions',
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
                                'All Present',
                                Icons.check_circle,
                                Colors.green,
                                () => _updateAllAttendance(AttendanceStatus.present),
                              ),
                              _buildQuickActionChip(
                                'All Late',
                                Icons.access_time,
                                Colors.orange,
                                () => _updateAllAttendance(AttendanceStatus.late),
                              ),
                              _buildQuickActionChip(
                                'All Absent',
                                Icons.cancel,
                                Colors.grey,
                                () => _updateAllAttendance(AttendanceStatus.absent),
                              ),
                              _buildQuickActionChip(
                                'Reset All',
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
                                'Smart Defaults',
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
                                  const Icon(Icons.people, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Members',
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(40),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${controller.choirMembers.length} Total',
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
                                  final filteredMembers = _getFilteredMembers(allMembers);
                                  
                                  if (allMembers.isEmpty) {
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                          SizedBox(height: 16),
                                          Text('No members found', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  if (filteredMembers.isEmpty && _searchQuery.isNotEmpty) {
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                                          SizedBox(height: 16),
                                          Text('No members found matching your search', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: filteredMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = filteredMembers[index];
                                      final status = _attendance[member.id] ?? AttendanceStatus.absent;
                                      final isSelected = _selectedMembers.contains(member.id);
                                      
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary.withAlpha(20) : Colors.grey[25],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected 
                                                ? AppColors.primary.withAlpha(100)
                                                : _getAttendanceColor(status).withAlpha(60),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: ExpansionTile(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          leading: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_isSelectionMode) ...[
                                                Checkbox(
                                                  value: isSelected,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        _selectedMembers.add(member.id);
                                                      } else {
                                                        _selectedMembers.remove(member.id);
                                                      }
                                                    });
                                                  },
                                                  activeColor: AppColors.primary,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              _buildMemberAvatar(member, status),
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
                                            'ID: ${member.registrationNumber}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getAttendanceColor(status),
                                                  _getAttendanceColor(status).withAlpha(200),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
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
                                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey.withAlpha(40)),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      _buildEnhancedStatusButton(
                                                        'Present', 
                                                        Icons.check_circle, 
                                                        AttendanceStatus.present, 
                                                        member.id
                                                      ),
                                                      _buildEnhancedStatusButton(
                                                        'Late', 
                                                        Icons.access_time, 
                                                        AttendanceStatus.late, 
                                                        member.id
                                                      ),
                                                      _buildEnhancedStatusButton(
                                                        'Absent', 
                                                        Icons.cancel, 
                                                        AttendanceStatus.absent, 
                                                        member.id
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  TextField(
                                                    decoration: InputDecoration(
                                                      labelText: 'Notes (optional)',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      isDense: true,
                                                      prefixIcon: const Icon(Icons.note_alt, color: AppColors.primary),
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
                      const Icon(Icons.analytics, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Session Summary',
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
                        'Present', 
                        _attendance.values.where((s) => s == AttendanceStatus.present).length, 
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildEnhancedSummaryItem(
                        'Late', 
                        _attendance.values.where((s) => s == AttendanceStatus.late).length, 
                        Colors.orange,
                        Icons.access_time,
                      ),
                      _buildEnhancedSummaryItem(
                        'Absent', 
                        _attendance.values.where((s) => s == AttendanceStatus.absent).length, 
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
                      label: const Text('Cancel'),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Saving...' : 'Save Attendance'),
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
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }
  
  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);
    
    final choirController = Provider.of<ChoirController>(context, listen: false);
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    final authController = Provider.of<AuthController>(context, listen: false);
    const uuid = Uuid();
    
    try {
      // First create the session with current event type and title
      final sessionId = uuid.v4();
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
      
      if (!sessionSuccess) {
        throw Exception('Failed to create attendance session');
      }
      
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
      
      Logger.debug('About to save ${attendanceRecords.length} attendance records');
      for (var record in attendanceRecords) {
        Logger.debug('Record - Member: ${record.memberId}, Status: ${record.status}, Choir: ${record.choirId}');
      }

      // Save attendance records
      final success = await attendanceController.recordAttendanceBatch(attendanceRecords);

      Logger.debug('Attendance save success: $success');
      
      if (success) {
        final present = _attendance.values.where((status) => status == AttendanceStatus.present).length;
        final late = _attendance.values.where((status) => status == AttendanceStatus.late).length;
        final absent = _attendance.values.where((status) => status == AttendanceStatus.absent).length;
        final total = _attendance.length;
        
        // Refresh attendance data
        await attendanceController.loadChoirAttendance(widget.choir.id);
        await attendanceController.loadAttendanceSessions(choirId: widget.choir.id);
        
        // Call the callback to refresh the parent screen
        widget.onAttendanceSaved?.call();
        
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        Get.snackbar(
          'Attendance Saved',
          'Recorded: $present present, $late late, $absent absent (Total: $total) for $_selectedEvent',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to save attendance. Please try again.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error saving attendance: $e',
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
    return 'Member ${member.registrationNumber}';
  }

  Widget _buildQuickActionChip(String label, IconData icon, Color color, VoidCallback onPressed) {
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

  Widget _buildEnhancedStatusButton(String label, IconData icon, AttendanceStatus status, String memberId) {
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
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
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

  Widget _buildEnhancedSummaryItem(String label, int count, Color color, IconData icon) {
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
      final matchesSearch = _searchQuery.isEmpty || 
          memberName.contains(searchLower) || 
          registrationNumber.contains(searchLower);
      
      // Status filter
      final memberStatus = _attendance[member.id] ?? AttendanceStatus.absent;
      final matchesStatus = _statusFilter == null || memberStatus == _statusFilter;
      
      return matchesSearch && matchesStatus;
    }).toList();
    
    // Sort by name for better UX
    filtered.sort((a, b) => _getMemberDisplayName(a).compareTo(_getMemberDisplayName(b)));
    
    return filtered;
  }

  Widget _buildFilterChip(String label, AttendanceStatus? status, bool isSelected, VoidCallback onTap) {
    final color = status != null ? _getAttendanceColor(status) : AppColors.primary;
    
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
  Widget _buildBulkActionChip(String label, IconData icon, Color color, VoidCallback onPressed) {
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
        content: Text('Marked ${_selectedMembers.length} members as $statusText'),
        backgroundColor: _getAttendanceColor(status),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _selectAllVisible() {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    final filteredMembers = _getFilteredMembers(choirController.choirMembers);
    
    setState(() {
      for (final member in filteredMembers) {
        _selectedMembers.add(member.id);
      }
    });
  }

  void _updateAllAttendance(AttendanceStatus status) {
    setState(() {
      final choirController = Provider.of<ChoirController>(context, listen: false);
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
    final choirController = Provider.of<ChoirController>(context, listen: false);
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
      const SnackBar(
        content: Text('Applied smart defaults based on attendance history'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
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
              ? member.registrationNumber.substring(member.registrationNumber.length - 2)
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