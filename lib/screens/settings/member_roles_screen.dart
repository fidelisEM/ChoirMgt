import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/member_controller.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';

class MemberRolesScreen extends StatefulWidget {

  const MemberRolesScreen({super.key, required this.choir});
  final ChoirModel choir;

  @override
  State<MemberRolesScreen> createState() => _MemberRolesScreenState();
}

class _MemberRolesScreenState extends State<MemberRolesScreen> {
  bool _isLoading = false;

  final List<Map<String, dynamic>> _roleDefinitions = [
    {
      'role': 'leader',
      'title': 'Choir Leader',
      'description': 'Full access to manage choir, members, and settings',
      'permissions': ['Manage Members', 'Edit Settings', 'Delete Choir', 'View Reports', 'Manage Payments'],
      'color': Colors.red,
      'icon': Icons.admin_panel_settings,
    },
    {
      'role': 'assistant',
      'title': 'Assistant Leader',
      'description': 'Help manage choir activities and members',
      'permissions': ['Manage Members', 'Take Attendance', 'View Reports', 'Send Messages'],
      'color': Colors.orange,
      'icon': Icons.supervisor_account,
    },
    {
      'role': 'secretary',
      'title': 'Secretary',
      'description': 'Handle communications and record keeping',
      'permissions': ['Send Messages', 'Take Attendance', 'View Reports'],
      'color': Colors.blue,
      'icon': Icons.edit_note,
    },
    {
      'role': 'treasurer',
      'title': 'Treasurer',
      'description': 'Manage payments and financial records',
      'permissions': ['Manage Payments', 'View Financial Reports', 'Export Data'],
      'color': Colors.green,
      'icon': Icons.account_balance,
    },
    {
      'role': 'member',
      'title': 'Member',
      'description': 'Basic choir member with limited access',
      'permissions': ['View Messages', 'View Own Profile', 'View Attendance'],
      'color': Colors.grey,
      'icon': Icons.person,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMembers();
    });
  }

  void _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final memberController = Provider.of<MemberController>(context, listen: false);
      await memberController.loadChoirMembers(widget.choir.id);
    } catch (e) {
      Helpers.showErrorSnackbar('Failed to load members: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Roles'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer3<MemberController, ChoirController, AuthController>(
        builder: (context, memberController, choirController, authController, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleDefinitions(),
                const SizedBox(height: 24),
                _buildMembersList(memberController, authController),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleDefinitions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role Definitions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.gray800,
          ),
        ),
        const SizedBox(height: 16),
        ..._roleDefinitions.map((role) => _buildRoleCard(role)),
      ],
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (role['color'] as Color).withAlpha(30),
                  child: Icon(
                    role['icon'] as IconData,
                    color: role['color'] as Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        role['description'] as String,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Permissions:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (role['permissions'] as List<String>).map((permission) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (role['color'] as Color).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    permission,
                    style: TextStyle(
                      color: role['color'] as Color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(MemberController memberController, AuthController authController) {
    final members = memberController.membersWithUserInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Assign Member Roles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray800,
              ),
            ),
            const Spacer(),
            Text(
              '${members.length} members',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (members.isEmpty)
          _buildEmptyState()
        else
          ...members.map((member) => _buildMemberRoleCard(member, authController)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Members Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add members to the choir to assign roles',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRoleCard(Map<String, dynamic> member, AuthController authController) {
    final userData = member['users'] ?? {};
    final fullName = userData['full_name'] ?? 'Unknown Member';
    final email = userData['email'] ?? '';
    final currentRole = member['role'] ?? 'member';
    
    // Don't allow changing the leader's role
    final isLeader = member['id'] == widget.choir.leaderId;
    final canEdit = authController.currentUser?.id == widget.choir.leaderId && !isLeader;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(currentRole).withAlpha(30),
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: _getRoleColor(currentRole),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getRoleIcon(currentRole),
                        size: 16,
                        color: _getRoleColor(currentRole),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getRoleTitle(currentRole),
                        style: TextStyle(
                          color: _getRoleColor(currentRole),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLeader) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'OWNER',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (canEdit)
              PopupMenuButton<String>(
                onSelected: (role) => _changeRole(member, role),
                itemBuilder: (context) => _roleDefinitions
                    .where((role) => role['role'] != 'leader') // Can't assign leader role
                    .map((role) => PopupMenuItem<String>(
                          value: role['role'] as String,
                          child: Row(
                            children: [
                              Icon(
                                role['icon'] as IconData,
                                size: 20,
                                color: role['color'] as Color,
                              ),
                              const SizedBox(width: 12),
                              Text(role['title'] as String),
                            ],
                          ),
                        ))
                    .toList(),
                child: const Icon(Icons.more_vert),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    final roleData = _roleDefinitions.firstWhere(
      (r) => r['role'] == role,
      orElse: () => _roleDefinitions.last,
    );
    return roleData['color'] as Color;
  }

  IconData _getRoleIcon(String role) {
    final roleData = _roleDefinitions.firstWhere(
      (r) => r['role'] == role,
      orElse: () => _roleDefinitions.last,
    );
    return roleData['icon'] as IconData;
  }

  String _getRoleTitle(String role) {
    final roleData = _roleDefinitions.firstWhere(
      (r) => r['role'] == role,
      orElse: () => _roleDefinitions.last,
    );
    return roleData['title'] as String;
  }

  void _changeRole(Map<String, dynamic> member, String newRole) async {
    final userData = member['users'] ?? {};
    final fullName = userData['full_name'] ?? 'Unknown Member';

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Change Member Role'),
        content: Text(
          'Change $fullName\'s role to ${_getRoleTitle(newRole)}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Change Role'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final memberController = Provider.of<MemberController>(context, listen: false);
        
        // Update member role (this would need to be implemented in the controller)
        final success = await memberController.updateMemberRole(
          memberId: member['id'],
          choirId: widget.choir.id,
          newRole: newRole,
        );

        if (success) {
          Helpers.showSuccessSnackbar('$fullName\'s role updated to ${_getRoleTitle(newRole)}');
          _loadMembers(); // Reload to show changes
        } else {
          Helpers.showErrorSnackbar('Failed to update member role');
        }
      } catch (e) {
        Helpers.showErrorSnackbar('Error updating role: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}