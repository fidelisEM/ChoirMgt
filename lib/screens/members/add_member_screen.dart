import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/member_controller.dart';
import '../../models/models.dart';
import '../../services/error_service.dart';
import '../../services/loading_service.dart';
import '../../utils/logger.dart';
import '../../widgets/form_widgets.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({
    super.key,
    required this.choirId,
    required this.choirName,
  });
  final String choirId;
  final String choirName;

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _searchController = TextEditingController();
  UserModel? _selectedUser;
  String _searchQuery = '';
  MemberRole _selectedRole = MemberRole.choir;
  MemberLevel _selectedLevel = MemberLevel.choir;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateRegistrationNumber();
    });
  }

  void _generateRegistrationNumber() async {
    final memberController = Provider.of<MemberController>(
      context,
      listen: false,
    );
    final regNumber = await memberController.generateRegistrationNumber(
      widget.choirId,
    );
    _formKey.currentState?.fields['registrationNumber']?.didChange(regNumber);
  }

  void _searchUsers(String query) {
    setState(() {
      _searchQuery = query;
    });

    final memberController = Provider.of<MemberController>(
      context,
      listen: false,
    );
    memberController.searchAvailableUsers(
      choirId: widget.choirId,
      query: query,
    );
  }

  void _selectUser(UserModel user) {
    setState(() {
      _selectedUser = user;
      _searchController.text = user.fullName;
    });
  }

  void _addMember() async {
    if (_selectedUser == null) {
      context.showErrorMessage(
        'Please select a user to add to the choir',
        type: ErrorType.validation,
      );
      return;
    }

    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      context.showErrorMessage(
        'Please check the form and fix any errors',
        type: ErrorType.validation,
      );
      return;
    }

    try {
      final formData = _formKey.currentState!.value;
      final memberController = Provider.of<MemberController>(
        context,
        listen: false,
      );

      // Prepare metadata based on role
      Map<String, dynamic>? metadata;
      if (_selectedRole == MemberRole.leader &&
          formData['leaderPosition'] != null) {
        metadata = {'position': formData['leaderPosition']};
      } else if (_selectedRole == MemberRole.committee &&
          formData['committeeName'] != null) {
        metadata = {'committee': formData['committeeName']};
      } else if (_selectedRole == MemberRole.trainer &&
          formData['trainerPosition'] != null) {
        metadata = {'position': formData['trainerPosition']};
      }

      await LoadingService.withLoading(
        context,
        () async {
          final success = await memberController.addMemberToChoir(
            userId: _selectedUser!.id,
            choirId: widget.choirId,
            customRegistrationNumber: formData['registrationNumber'],
            role: _selectedRole,
            level: _selectedLevel,
            metadata: metadata,
          );

          if (!success) {
            throw Exception(
              memberController.errorMessage ?? 'Failed to add member',
            );
          }
        },
        loadingMessage: 'Adding ${_selectedUser!.fullName} to choir...',
        successMessage:
            '${_selectedUser!.fullName} has been added to the choir!',
      );

      // Success - navigate back
      Get.back(result: true);
    } on AppError catch (e) {
      context.showError(e);
    } catch (e) {
      context.showErrorMessage(
        'Failed to add member to choir. Please try again.',
        type: ErrorType.unknown,
      );
      ErrorService().logError(
        ErrorService().createDatabaseError(
          'Add member failed',
          technicalMessage: e.toString(),
        ),
      );
    }
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Member Role',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MemberRole.values.map((role) {
              final isSelected = _selectedRole == role;
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(role),
                      size: 16,
                      color: isSelected ? Colors.white : _getRoleColor(role),
                    ),
                    const SizedBox(width: 8),
                    Text(_getRoleDisplayName(role)),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedRole = role;
                  });
                },
                selectedColor: _getRoleColor(role),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getRoleColor(_selectedRole).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getRoleIcon(_selectedRole),
                color: _getRoleColor(_selectedRole),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _getRoleDescription(_selectedRole),
                  style: TextStyle(
                    color: _getRoleColor(_selectedRole),
                    fontSize: 12,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(MemberRole role) {
    switch (role) {
      case MemberRole.leader:
        return 'Leader';
      case MemberRole.committee:
        return 'Committee';
      case MemberRole.board:
        return 'Board';
      case MemberRole.choir:
        return 'Choir';
      case MemberRole.patron:
        return 'Patron';
      case MemberRole.trainer:
        return 'Trainer';
    }
  }

  IconData _getRoleIcon(MemberRole role) {
    switch (role) {
      case MemberRole.leader:
        return Icons.admin_panel_settings;
      case MemberRole.committee:
        return Icons.business_center;
      case MemberRole.board:
        return Icons.corporate_fare;
      case MemberRole.choir:
        return Icons.music_note;
      case MemberRole.patron:
        return Icons.star;
      case MemberRole.trainer:
        return Icons.school;
    }
  }

  Color _getRoleColor(MemberRole role) {
    switch (role) {
      case MemberRole.leader:
        return Colors.red.shade600;
      case MemberRole.committee:
        return Colors.orange.shade600;
      case MemberRole.board:
        return Colors.purple.shade600;
      case MemberRole.choir:
        return Colors.blue.shade600;
      case MemberRole.patron:
        return Colors.amber.shade600;
      case MemberRole.trainer:
        return Colors.green.shade600;
    }
  }

  String _getRoleDescription(MemberRole role) {
    switch (role) {
      case MemberRole.leader:
        return 'Leadership and administrative responsibilities';
      case MemberRole.committee:
        return 'Committee member with specific duties';
      case MemberRole.board:
        return 'Board member with governance responsibilities';
      case MemberRole.choir:
        return 'Regular choir member who participates in performances';
      case MemberRole.patron:
        return 'Patron who supports the choir financially or otherwise';
      case MemberRole.trainer:
        return 'Trainer responsible for teaching and development';
    }
  }

  Widget _buildLevelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Member Level',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MemberLevel.values.map((level) {
              final isSelected = _selectedLevel == level;
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getLevelIcon(level),
                      size: 16,
                      color: isSelected ? Colors.white : _getLevelColor(level),
                    ),
                    const SizedBox(width: 8),
                    Text(_getLevelDisplayName(level)),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedLevel = level;
                  });
                },
                selectedColor: _getLevelColor(level),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getLevelColor(_selectedLevel).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getLevelIcon(_selectedLevel),
                color: _getLevelColor(_selectedLevel),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _getLevelDescription(_selectedLevel),
                  style: TextStyle(
                    color: _getLevelColor(_selectedLevel),
                    fontSize: 12,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getLevelDisplayName(MemberLevel level) {
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

  String _getLevelDescription(MemberLevel level) {
    switch (level) {
      case MemberLevel.national:
        return 'National level authority with oversight across the entire country';
      case MemberLevel.diocese:
        return 'Diocese level authority with oversight within a specific diocese';
      case MemberLevel.parish:
        return 'Parish level authority with oversight within a specific parish';
      case MemberLevel.choir:
        return 'Choir level authority limited to the specific choir';
    }
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug(
      'AddMemberScreen build - choirId: ${widget.choirId}, choirName: ${widget.choirName}',
    );
    Logger.debug(
      'Search query: "$_searchQuery", Selected user: $_selectedUser',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Member to ${widget.choirName}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Debug info
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Get.snackbar(
                'Debug Info',
                'Choir: ${widget.choirId}\nSearch: "$_searchQuery"\nSelected: ${_selectedUser?.fullName ?? "None"}',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search User',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchUsers('');
                                setState(() {
                                  _selectedUser = null;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: _searchUsers,
                  ),
                ],
              ),
            ),

            // Search results
            if (_searchQuery.isNotEmpty && _selectedUser == null)
              Expanded(
                flex: 2,
                child: Consumer<MemberController>(
                  builder: (context, memberController, child) {
                    if (memberController.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = memberController.availableUsers;

                    if (users.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text('No users found'),
                            Text('Try a different search term'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(user.email),
                                if (user.phoneNumber.isNotEmpty)
                                  Text(
                                    user.phoneNumber,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _selectUser(user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Select'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            // Selected user info and form
            if (_selectedUser != null)
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected user card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                child: Text(
                                  _selectedUser!.fullName.isNotEmpty
                                      ? _selectedUser!.fullName[0].toUpperCase()
                                      : 'U',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedUser!.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _selectedUser!.email,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    if (_selectedUser!.phoneNumber.isNotEmpty)
                                      Text(
                                        _selectedUser!.phoneNumber,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    if (_selectedUser!
                                        .suggestedChoir
                                        .isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.music_note,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Suggested Choir: ${_selectedUser!.suggestedChoir}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedUser = null;
                                    _searchController.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Member details form
                      Text(
                        'Member Details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 16),

                      FormBuilder(
                        key: _formKey,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                FormBuilderField<String>(
                                  name: 'registrationNumber',
                                  builder: (FormFieldState<String?> field) {
                                    return RegistrationNumberFormField(
                                      label: 'Registration Number',
                                      initialValue: field.value,
                                      onChanged: (value) =>
                                          field.didChange(value),
                                      required: true,
                                    );
                                  },
                                ),

                                const SizedBox(height: 20),

                                _buildRoleSelection(),

                                const SizedBox(height: 20),

                                _buildLevelSelection(),

                                const SizedBox(height: 20),

                                // Additional fields based on role
                                if (_selectedRole == MemberRole.leader)
                                  Column(
                                    children: [
                                      FormBuilderDropdown<String>(
                                        name: 'leaderPosition',
                                        decoration: const InputDecoration(
                                          labelText: 'Leadership Position',
                                          prefixIcon: Icon(
                                            Icons.admin_panel_settings,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator:
                                            FormBuilderValidators.compose([
                                              FormBuilderValidators.required(),
                                            ]),
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
                                                  (position) =>
                                                      DropdownMenuItem(
                                                        value: position,
                                                        child: Text(position),
                                                      ),
                                                )
                                                .toList(),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),

                                if (_selectedRole == MemberRole.committee)
                                  Column(
                                    children: [
                                      FormBuilderDropdown<String>(
                                        name: 'committeeName',
                                        decoration: const InputDecoration(
                                          labelText: 'Committee Name',
                                          prefixIcon: Icon(
                                            Icons.business_center,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator:
                                            FormBuilderValidators.compose([
                                              FormBuilderValidators.required(),
                                            ]),
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
                                                  (committee) =>
                                                      DropdownMenuItem(
                                                        value: committee,
                                                        child: Text(committee),
                                                      ),
                                                )
                                                .toList(),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),

                                if (_selectedRole == MemberRole.trainer)
                                  Column(
                                    children: [
                                      FormBuilderDropdown<String>(
                                        name: 'trainerPosition',
                                        decoration: const InputDecoration(
                                          labelText: 'Trainer Position',
                                          prefixIcon: Icon(Icons.school),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator:
                                            FormBuilderValidators.compose([
                                              FormBuilderValidators.required(),
                                            ]),
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
                                                  (position) =>
                                                      DropdownMenuItem(
                                                        value: position,
                                                        child: Text(position),
                                                      ),
                                                )
                                                .toList(),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),

                                Consumer<MemberController>(
                                  builder: (context, memberController, child) {
                                    return SizedBox(
                                      width: double.infinity,
                                      child: LoadingButton(
                                        onPressed: _addMember,
                                        text: 'Add to Choir',
                                        isLoading: memberController.isLoading,
                                        color: Theme.of(context).primaryColor,
                                        textColor: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Initial state - no search or selection
            if (_searchQuery.isEmpty && _selectedUser == null)
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Search for Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start typing to find users to add to the choir',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Fallback container to ensure something is always visible
            if (_searchQuery.isNotEmpty &&
                _selectedUser == null &&
                _searchQuery.length < 2)
              const Expanded(
                child: Center(
                  child: Text('Type at least 2 characters to search'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
