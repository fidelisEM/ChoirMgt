import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/member_controller.dart';
import '../../models/models.dart';
import '../../services/export_service.dart';
import '../../utils/helpers.dart';
import 'add_member_screen.dart';
import 'edit_member_screen.dart';
import 'member_detail_screen.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredMembers = [];
  String? _selectedChoirId;
  bool _isLoadingChoirs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChoirs();
    });
  }

  Future<void> _loadChoirs() async {
    setState(() => _isLoadingChoirs = true);
    try {
      final choirController = Provider.of<ChoirController>(context, listen: false);
      final authController = Provider.of<AuthController>(context, listen: false);
      
      if (authController.currentUser != null) {
        if (authController.currentUser!.role == UserRole.admin) {
          await choirController.loadChoirs(adminView: true);
        } else {
          await choirController.loadChoirs(
            userId: authController.currentUser!.id,
            adminView: false,
          );
        }
        
        // If there's already a selected choir, keep it selected
        if (choirController.selectedChoir != null) {
          _selectedChoirId = choirController.selectedChoir!.id;
          _loadMembers();
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load choirs: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingChoirs = false);
      }
    }
  }

  void _loadMembers() {
    final memberController = Provider.of<MemberController>(context, listen: false);
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    if (choirController.selectedChoir != null) {
      _selectedChoirId = choirController.selectedChoir!.id;
      memberController.loadChoirMembers(_selectedChoirId!).then((_) {
        // Initialize filtered members after data loads
        setState(() {
          _filteredMembers = List.from(memberController.membersWithUserInfo);
        });
      });
    }
  }

  void _filterMembers(String query) {
    final memberController = Provider.of<MemberController>(context, listen: false);
    final allMembers = memberController.membersWithUserInfo;
    
    if (query.isEmpty) {
      setState(() {
        _filteredMembers = List.from(allMembers);
      });
    } else {
      setState(() {
        _filteredMembers = allMembers.where((member) {
          final userData = member['users'];
          if (userData == null) return false;
          
          final name = userData['full_name']?.toString().toLowerCase() ?? '';
          final email = userData['email']?.toString().toLowerCase() ?? '';
          final regNumber = member['registration_number']?.toString().toLowerCase() ?? '';
          
          return name.contains(query.toLowerCase()) ||
                 email.contains(query.toLowerCase()) ||
                 regNumber.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Widget _buildChoirSelection(ChoirController choirController) {
    if (_isLoadingChoirs) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading choirs...'),
          ],
        ),
      );
    }

    if (choirController.choirs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('No choirs available')),
            TextButton(
              onPressed: _loadChoirs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedChoirId,
      decoration: const InputDecoration(
        labelText: 'Select Choir',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.music_note),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: choirController.choirs.map((choir) {
        return DropdownMenuItem<String>(
          value: choir.id,
          child: Text(choir.name),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final selectedChoir = choirController.choirs.firstWhere((c) => c.id == value);
          choirController.selectChoir(selectedChoir);
          setState(() {
            _selectedChoirId = value;
          });
          _loadMembers();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choir Members'),
        actions: [
          Consumer2<AuthController, ChoirController>(
            builder: (context, authController, choirController, child) {
              if (choirController.selectedChoir == null || !authController.isChoirLeader) {
                return const SizedBox.shrink();
              }
              
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'export') {
                    _showExportOptions();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 20),
                        SizedBox(width: 8),
                        Text('Export Members'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120), // Increased height for choir selection
          child: Consumer<ChoirController>(
            builder: (context, choirController, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Choir selection dropdown
                    _buildChoirSelection(choirController),
                    const SizedBox(height: 16),
                    // Search field (only show if choir is selected)
                    if (choirController.selectedChoir != null)
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search members...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: _filterMembers,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: Consumer3<MemberController, AuthController, ChoirController>(
        builder: (context, memberController, authController, choirController, child) {
          if (choirController.selectedChoir == null) {
            return Center(
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
                    'Select a choir to view members',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a choir from the dropdown above',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (memberController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (memberController.errorMessage != null) {
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
                    'Error loading members',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    memberController.errorMessage!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      memberController.clearError();
                      _loadMembers();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Use filtered members if search is active, otherwise all members
          final members = _searchController.text.isNotEmpty 
              ? _filteredMembers 
              : memberController.membersWithUserInfo;

          if (members.isEmpty) {
            return Center(
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
                    _searchController.text.isEmpty 
                        ? 'No members found'
                        : 'No matching members',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Add your first member to get started'
                        : 'Try adjusting your search terms',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchController.text.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMemberDialog(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Member'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              // Statistics bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: _buildStatisticsBar(memberController.memberStatistics),
              ),
              
              // Members list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadMembers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return _buildMemberCard(context, member, authController);
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
          if (choirController.selectedChoir == null || !authController.isChoirLeader) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: _showAddMemberDialog,
            tooltip: 'Add Member',
            child: const Icon(Icons.person_add),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsBar(Map<String, dynamic> stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Total', stats['total_members']?.toString() ?? '0', Colors.blue),
        _buildStatItem('Active', stats['active_members']?.toString() ?? '0', Colors.green),
        _buildStatItem('Inactive', stats['inactive_members']?.toString() ?? '0', Colors.orange),
        _buildStatItem('Suspended', stats['suspended_members']?.toString() ?? '0', Colors.red),
      ],
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

  Widget _buildMemberCard(BuildContext context, Map<String, dynamic> member, AuthController authController) {
    final userData = member['users'];
    final name = userData?['full_name'] ?? 'Unknown User';
    final email = userData?['email'] ?? '';
    final regNumber = member['registration_number'] ?? '';
    final status = member['status'] ?? 'active';
    final joinDate = DateTime.tryParse(member['join_date'] ?? '') ?? DateTime.now();
    final outstandingFees = member['outstanding_fees'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToMemberDetail(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getStatusColor(status).withAlpha(50),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (authController.isChoirLeader)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMemberAction(context, member, value),
                      itemBuilder: (context) => [
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
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz, size: 16),
                              SizedBox(width: 8),
                              Text('Change Status'),
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
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.badge,
                    label: regNumber,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.circle,
                    label: status.toUpperCase(),
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 8),
                  if (outstandingFees > 0)
                    _buildInfoChip(
                      icon: Icons.payment,
                      label: '\$${outstandingFees.toStringAsFixed(2)}',
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Joined: ${_formatDate(joinDate)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddMemberDialog() {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    if (choirController.selectedChoir == null) return;
    
    Get.to(() => AddMemberScreen(
      choirId: choirController.selectedChoir!.id,
      choirName: choirController.selectedChoir!.name,
    ))?.then((result) {
      if (result == true) {
        _loadMembers();
      }
    });
  }

  void _navigateToMemberDetail(Map<String, dynamic> member) {
    Get.to(() => MemberDetailScreen(member: member));
  }

  void _handleMemberAction(BuildContext context, Map<String, dynamic> member, String action) {
    switch (action) {
      case 'edit':
        Get.to(() => EditMemberScreen(member: member));
        break;
      case 'status':
        _showChangeStatusDialog(member);
        break;
      case 'remove':
        _showRemoveMemberDialog(member);
        break;
    }
  }

  void _showChangeStatusDialog(Map<String, dynamic> member) {
    final currentStatus = member['status'] ?? 'active';
    MemberStatus selectedStatus = MemberStatus.values.firstWhere(
      (status) => status.toString().split('.').last == currentStatus,
      orElse: () => MemberStatus.active,
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Member Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: MemberStatus.values.map((status) {
              return RadioListTile<MemberStatus>(
                title: Text(status.toString().split('.').last.toUpperCase()),
                value: status,
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateMemberStatus(member, selectedStatus);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateMemberStatus(Map<String, dynamic> member, MemberStatus status) async {
    final memberController = Provider.of<MemberController>(context, listen: false);
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    if (choirController.selectedChoir == null) return;
    
    final success = await memberController.updateMemberStatus(
      memberId: member['id'],
      status: status,
      choirId: choirController.selectedChoir!.id,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Member status updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        memberController.errorMessage ?? 'Failed to update member status',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showRemoveMemberDialog(Map<String, dynamic> member) {
    final userData = member['users'];
    final name = userData?['full_name'] ?? 'Unknown User';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove "$name" from the choir? This action cannot be undone.',
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

  void _removeMember(Map<String, dynamic> member) async {
    final memberController = Provider.of<MemberController>(context, listen: false);
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    if (choirController.selectedChoir == null) return;
    
    final success = await memberController.removeMemberFromChoir(
      member['id'],
      choirController.selectedChoir!.id,
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
        memberController.errorMessage ?? 'Failed to remove member',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showExportOptions() {
    final memberController = Provider.of<MemberController>(context, listen: false);
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    if (choirController.selectedChoir == null) {
      Helpers.showErrorSnackbar('Please select a choir first');
      return;
    }

    final members = _searchController.text.isNotEmpty 
        ? _filteredMembers 
        : memberController.membersWithUserInfo;

    if (members.isEmpty) {
      Helpers.showErrorSnackbar('No members to export');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Member List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export ${members.length} members from ${choirController.selectedChoir!.name}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Generate PDF document'),
              onTap: () {
                Navigator.pop(context);
                _exportMembers('pdf', members);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              subtitle: const Text('Generate Excel spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                _exportMembers('excel', members);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: const Text('Export as CSV'),
              subtitle: const Text('Generate CSV file'),
              onTap: () {
                Navigator.pop(context);
                _exportMembers('csv', members);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportMembers(String format, List<Map<String, dynamic>> members) async {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    final exportService = ExportService();
    
    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Transform member data for export
      final totalOutstanding = members.fold(0.0, (sum, m) => sum + (m['outstanding_fees'] ?? 0.0));
      final totalPaid = members.fold(0.0, (sum, m) => sum + (m['total_paid'] ?? 0.0));
      final totalAmount = totalPaid + totalOutstanding;
      final collectionRate = totalAmount > 0 ? (totalPaid / totalAmount) * 100 : 0.0;
      
      final reportData = {
        'members': members,
        'summary': {
          'total_members': members.length,
          'active_members': members.where((m) => m['status'] == 'active').length,
          'inactive_members': members.where((m) => m['status'] == 'inactive').length,
          'suspended_members': members.where((m) => m['status'] == 'suspended').length,
          'total_outstanding': totalOutstanding,
          'total_paid': totalPaid,
          'collection_rate': collectionRate,
          'choir_name': choirController.selectedChoir?.name ?? '',
          'exported_at': DateTime.now().toString(),
        }
      };

      String? result;
      switch (format) {
        case 'pdf':
          result = await exportService.exportMembershipToPDF(reportData);
          break;
        case 'excel':
          result = await exportService.exportMembershipToExcel(reportData);
          break;
        case 'csv':
          result = await exportService.exportReportToCSV(reportData, 'membership');
          break;
      }

      // Hide loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (result != null) {
        Helpers.showSuccessSnackbar('Members exported successfully');
      } else {
        Helpers.showErrorSnackbar('Failed to export members');
      }
    } catch (e) {
      // Hide loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Helpers.showErrorSnackbar('Export failed: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}