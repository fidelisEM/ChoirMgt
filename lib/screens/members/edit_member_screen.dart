import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/member_controller.dart';
import '../../models/choir_member_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/logger.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_widgets.dart';

class EditMemberScreen extends StatefulWidget {
  const EditMemberScreen({super.key, required this.member});
  final Map<String, dynamic> member;

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registrationNumberController = TextEditingController();

  MemberStatus _selectedStatus = MemberStatus.active;
  MemberRole _selectedRole = MemberRole.choir;
  MemberLevel _selectedLevel = MemberLevel.choir;
  bool _isLoading = false;
  String? _selectedPosition;
  String? _selectedCommittee;

  final List<MemberStatus> _statusOptions = [
    MemberStatus.active,
    MemberStatus.inactive,
    MemberStatus.suspended,
  ];
  final List<MemberRole> _roleOptions = MemberRole.values;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final userData = widget.member['users'];
    _fullNameController.text = userData?['full_name'] ?? '';
    _emailController.text = userData?['email'] ?? '';
    _phoneController.text = userData?['phone_number'] ?? '';
    _registrationNumberController.text =
        widget.member['registration_number'] ?? '';

    final statusString = widget.member['status'] ?? 'active';
    _selectedStatus = MemberStatus.values.firstWhere(
      (status) => status.name == statusString,
      orElse: () => MemberStatus.active,
    );

    final roleString = widget.member['role'] ?? 'choir';
    _selectedRole = MemberRole.values.firstWhere(
      (role) => role.name == roleString,
      orElse: () => MemberRole.choir,
    );

    final levelString = widget.member['level'] ?? 'choir';
    _selectedLevel = MemberLevel.values.firstWhere(
      (level) => level.name == levelString,
      orElse: () => MemberLevel.choir,
    );

    // Initialize position/committee from metadata
    final metadata = widget.member['metadata'] as Map<String, dynamic>?;
    if (metadata != null) {
      _selectedPosition = metadata['position'];
      _selectedCommittee = metadata['committee'];
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Member'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildPersonalInfoSection(),
                  const SizedBox(height: 16),
                  _buildMembershipInfoSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Edit Member Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Update member information and settings',
            style: TextStyle(color: AppColors.gray600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) => Validators.name(value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => Validators.email(value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) => Validators.phoneNumber(value),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipInfoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Membership Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registrationNumberController,
            decoration: const InputDecoration(
              labelText: 'Registration Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
            validator: (value) =>
                Validators.required(value, 'registration number'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MemberStatus>(
            initialValue: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Member Status',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.info),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem<MemberStatus>(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status.name),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(status.name.toUpperCase()),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MemberRole>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Member Role',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.admin_panel_settings),
            ),
            items: _roleOptions.map((role) {
              return DropdownMenuItem<MemberRole>(
                value: role,
                child: Row(
                  children: [
                    Icon(
                      _getRoleIcon(role),
                      size: 16,
                      color: _getRoleColor(role),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_getRoleLabel(role)} - ${_getRoleDescription(role)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
                // Clear position/committee when role changes
                _selectedPosition = null;
                _selectedCommittee = null;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MemberLevel>(
            initialValue: _selectedLevel,
            decoration: const InputDecoration(
              labelText: 'Member Level',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.layers),
            ),
            items: MemberLevel.values.map((level) {
              return DropdownMenuItem<MemberLevel>(
                value: level,
                child: Row(
                  children: [
                    Icon(
                      _getLevelIcon(level),
                      size: 16,
                      color: _getLevelColor(level),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_getLevelLabel(level)} - ${_getLevelDescription(level)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLevel = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Additional fields based on role
          if (_selectedRole == MemberRole.leader)
            Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedPosition,
                  decoration: const InputDecoration(
                    labelText: 'Leadership Position',
                    prefixIcon: Icon(Icons.admin_panel_settings),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      const [
                            'Chairperson',
                            'Vice-Chairperson',
                            'Assistant Chairperson',
                            'Secretary',
                            'Vice-Secretary',
                            'Assistant Secretary',
                            'Treasurer',
                            'Assistant Treasurer',
                            'Organizing Secretary',
                            'Music Director',
                            'Assistant Music Director',
                            'Director',
                            'Assistant Director',
                            'President',
                            'Vice-President',
                            'Assistant President',
                            'Other',
                          ]
                          .map(
                            (position) => DropdownMenuItem(
                              value: position,
                              child: Text(position),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPosition = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),

          if (_selectedRole == MemberRole.committee)
            Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedCommittee,
                  decoration: const InputDecoration(
                    labelText: 'Committee Name',
                    prefixIcon: Icon(Icons.business_center),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      const [
                            'Finance Committee',
                            'Events Committee',
                            'Music Committee',
                            'Disciplinary Committee',
                            'Fundraising Committee',
                            'Welfare Committee',
                            'Youth Committee',
                            'Women Committee',
                            'Men Committee',
                            'Publicity Committee',
                            'Training Committee',
                            'Other',
                          ]
                          .map(
                            (committee) => DropdownMenuItem(
                              value: committee,
                              child: Text(committee),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCommittee = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),

          if (_selectedRole == MemberRole.trainer)
            Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedPosition,
                  decoration: const InputDecoration(
                    labelText: 'Trainer Position',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      const [
                            'Head Trainer',
                            'Assistant Trainer',
                            'Music Trainer',
                            'Voice Coach',
                            'Choir Master',
                            'Assistant Choir Master',
                            'Accompanist',
                            'Music Theory Instructor',
                            'Performance Coach',
                            'Other',
                          ]
                          .map(
                            (position) => DropdownMenuItem(
                              value: position,
                              child: Text(position),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPosition = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Role and status changes will affect member access and permissions',
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Get.back(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateMember,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(MemberRole role) {
    switch (role) {
      case MemberRole.leader:
        return 'Leader';
      case MemberRole.committee:
        return 'Committee';
      case MemberRole.board:
        return 'Board';
      case MemberRole.choir:
        return 'Choir Member';
      case MemberRole.patron:
        return 'Patron';
      case MemberRole.trainer:
        return 'Trainer';
    }
  }

  String _getRoleDescription(MemberRole role) {
    switch (role) {
      case MemberRole.leader:
        return 'Leadership & management';
      case MemberRole.committee:
        return 'Committee member';
      case MemberRole.board:
        return 'Board of directors';
      case MemberRole.choir:
        return 'Regular choir member';
      case MemberRole.patron:
        return 'Patron & supporter';
      case MemberRole.trainer:
        return 'Trainer & instructor';
    }
  }

  IconData _getRoleIcon(MemberRole role) {
    switch (role) {
      case MemberRole.leader:
        return Icons.star;
      case MemberRole.committee:
        return Icons.group;
      case MemberRole.board:
        return Icons.business;
      case MemberRole.choir:
        return Icons.music_note;
      case MemberRole.patron:
        return Icons.favorite;
      case MemberRole.trainer:
        return Icons.school;
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

  String _getLevelLabel(MemberLevel level) {
    switch (level) {
      case MemberLevel.national:
        return 'National';
      case MemberLevel.diocese:
        return 'Diocese';
      case MemberLevel.parish:
        return 'Parish';
      case MemberLevel.choir:
        return 'Choir';
    }
  }

  String _getLevelDescription(MemberLevel level) {
    switch (level) {
      case MemberLevel.national:
        return 'National level oversight';
      case MemberLevel.diocese:
        return 'Diocese level oversight';
      case MemberLevel.parish:
        return 'Parish level oversight';
      case MemberLevel.choir:
        return 'Choir level only';
    }
  }

  IconData _getLevelIcon(MemberLevel level) {
    switch (level) {
      case MemberLevel.national:
        return Icons.flag;
      case MemberLevel.diocese:
        return Icons.account_balance;
      case MemberLevel.parish:
        return Icons.church;
      case MemberLevel.choir:
        return Icons.music_note;
    }
  }

  Color _getLevelColor(MemberLevel level) {
    switch (level) {
      case MemberLevel.national:
        return Colors.red;
      case MemberLevel.diocese:
        return Colors.purple;
      case MemberLevel.parish:
        return Colors.blue;
      case MemberLevel.choir:
        return Colors.green;
    }
  }

  Future<void> _updateMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final memberController = Provider.of<MemberController>(
        context,
        listen: false,
      );
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );

      if (!authController.isChoirLeader) {
        Helpers.showErrorSnackbar(
          'Only choir leaders can edit member profiles',
        );
        return;
      }

      Logger.debug('Updating member profile');
      Logger.debug(
        'Original user name: ${widget.member['users']?['full_name']}',
      );
      Logger.debug('New name from controller: ${_fullNameController.text}');

      // First update the user profile information (name, email, phone)
      bool userProfileSuccess = true;
      final userData = widget.member['users'];
      if (userData != null) {
        // Check if user profile data has changed
        final hasUserChanges =
            _fullNameController.text.trim() != (userData['full_name'] ?? '') ||
            _emailController.text.trim() != (userData['email'] ?? '') ||
            _phoneController.text.trim() != (userData['phone_number'] ?? '');

        if (hasUserChanges) {
          Logger.debug(
            'User profile changes detected, updating user profile...',
          );
          final userId = userData['id'];
          if (userId != null) {
            userProfileSuccess = await authController.updateUserProfileByUserId(
              userId: userId,
              displayName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
            );
            Logger.debug('User profile update result: $userProfileSuccess');
          } else {
            Logger.warning('No user ID found, cannot update user profile');
            userProfileSuccess = false;
          }
        }
      }

      final success = await memberController.updateMemberStatus(
        memberId: widget.member['id'],
        choirId: widget.member['choir_id'],
        status: _selectedStatus,
      );

      // Prepare metadata based on role
      Map<String, dynamic>? metadata;
      if (_selectedRole == MemberRole.leader && _selectedPosition != null) {
        metadata = {'position': _selectedPosition};
      } else if (_selectedRole == MemberRole.committee &&
          _selectedCommittee != null) {
        metadata = {'committee': _selectedCommittee};
      } else if (_selectedRole == MemberRole.trainer &&
          _selectedPosition != null) {
        metadata = {'position': _selectedPosition};
      }

      final detailsSuccess = await memberController.updateMemberDetails(
        memberId: widget.member['id'],
        choirId: widget.member['choir_id'],
        registrationNumber: _registrationNumberController.text.trim(),
        metadata: metadata,
      );

      final roleSuccess = await memberController.updateMemberRole(
        memberId: widget.member['id'],
        choirId: widget.member['choir_id'],
        newRole: _selectedRole.name,
      );

      final levelSuccess = await memberController.updateMemberLevel(
        memberId: widget.member['id'],
        choirId: widget.member['choir_id'],
        newLevel: _selectedLevel.name,
      );

      if (success &&
          detailsSuccess &&
          roleSuccess &&
          levelSuccess &&
          userProfileSuccess) {
        Helpers.showSuccessSnackbar('Member profile updated successfully');
        Get.back(result: true); // Return success indicator
      } else {
        Helpers.showErrorSnackbar('Failed to update member profile');
      }
    } catch (e) {
      Helpers.showErrorSnackbar('Error updating member: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
