import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/member_controller.dart';
import '../../models/models.dart';
import '../../services/export_service.dart';
import '../../utils/app_translations.dart';
import '../../utils/currency_utils.dart';
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
        if (authController.currentUser!.isAdmin) {
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
          context.tr('error'),
          '${context.tr('memberLoadChoirsFailed')}: $e',
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
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(context.tr('memberLoadingChoirs')),
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
            Expanded(child: Text(context.tr('memberNoChoirsAvailable'))),
            TextButton(
              onPressed: _loadChoirs,
              child: Text(context.tr('retry')),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedChoirId,
      decoration: InputDecoration(
        labelText: context.tr('memberSelectChoir'),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.music_note),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    // The bottom area holds the choir dropdown and, once a choir is chosen,
    // the search field. Reserve what they need so they don't spill over the list.
    final hasChoir = context.watch<ChoirController>().selectedChoir != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('memberChoirMembersTitle')),
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
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        const Icon(Icons.download, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('memberExportMembers')),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(hasChoir ? 168 : 92),
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
                        decoration: InputDecoration(
                          hintText: context.tr('memberSearchHint'),
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
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
                    context.tr('memberSelectChoirPrompt'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('memberChooseChoirHint'),
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
                    context.tr('memberErrorLoadingMembers'),
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
                    child: Text(context.tr('retry')),
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
                        ? context.tr('memberNoMembersFound')
                        : context.tr('memberNoMatchingMembers'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isEmpty
                        ? context.tr('memberAddFirstPrompt')
                        : context.tr('memberAdjustSearchPrompt'),
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchController.text.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMemberDialog(),
                      icon: const Icon(Icons.person_add),
                      label: Text(context.tr('addMember')),
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
                child: _buildStatisticsBar(context, memberController.memberStatistics),
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
            tooltip: context.tr('addMember'),
            child: const Icon(Icons.person_add),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsBar(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(child: _buildStatItem(context.tr('memberTotal'), stats['total_members']?.toString() ?? '0', Colors.blue)),
        Expanded(child: _buildStatItem(context.tr('active'), stats['active_members']?.toString() ?? '0', Colors.green)),
        Expanded(child: _buildStatItem(context.tr('inactive'), stats['inactive_members']?.toString() ?? '0', Colors.orange)),
        Expanded(child: _buildStatItem(context.tr('memberSuspended'), stats['suspended_members']?.toString() ?? '0', Colors.red)),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    final name = userData?['full_name'] ?? context.tr('memberUnknownUser');
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          value: 'status',
                          child: Row(
                            children: [
                              const Icon(Icons.swap_horiz, size: 16),
                              const SizedBox(width: 8),
                              Text(context.tr('memberChangeStatus')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(Icons.remove_circle, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(context.tr('remove'), style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildInfoChip(
                    icon: Icons.badge,
                    label: regNumber,
                    color: Colors.blue,
                  ),
                  _buildInfoChip(
                    icon: Icons.circle,
                    label: status.toUpperCase(),
                    color: _getStatusColor(status),
                  ),
                  if (outstandingFees > 0)
                    _buildInfoChip(
                      icon: Icons.payment,
                      label: CurrencyUtils.formatAmount(
                        (outstandingFees as num).toDouble(),
                        CurrencyUtils.getDefaultCurrency(),
                      ),
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${context.tr('memberJoinedLabel')}: ${_formatDate(joinDate)}',
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
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
          title: Text(context.tr('memberChangeStatusTitle')),
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
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateMemberStatus(member, selectedStatus);
              },
              child: Text(context.tr('update')),
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

    if (!mounted) return;
    if (success) {
      Get.snackbar(
        context.tr('memberSuccessTitle'),
        context.tr('memberStatusUpdateSuccess'),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        context.tr('error'),
        memberController.errorMessage ?? context.tr('memberStatusUpdateFailed'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showRemoveMemberDialog(Map<String, dynamic> member) {
    final userData = member['users'];
    final name = userData?['full_name'] ?? context.tr('memberUnknownUser');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('memberRemoveTitle')),
        content: Text(
          '${context.tr('memberRemoveConfirmPrefix')} "$name" ${context.tr('memberRemoveConfirmSuffix')}',
        ),
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
            child: Text(context.tr('remove'), style: const TextStyle(color: Colors.white)),
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

    if (!mounted) return;
    if (success) {
      Get.snackbar(
        context.tr('memberSuccessTitle'),
        context.tr('memberRemovedSuccess'),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        context.tr('error'),
        memberController.errorMessage ?? context.tr('memberRemoveFailed'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showExportOptions() {
    final memberController = Provider.of<MemberController>(context, listen: false);
    final choirController = Provider.of<ChoirController>(context, listen: false);

    if (choirController.selectedChoir == null) {
      Helpers.showErrorSnackbar(context.tr('memberSelectChoirFirst'));
      return;
    }

    final members = _searchController.text.isNotEmpty
        ? _filteredMembers
        : memberController.membersWithUserInfo;

    if (members.isEmpty) {
      Helpers.showErrorSnackbar(context.tr('memberNoMembersToExport'));
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
            Text(
              context.tr('memberExportListTitle'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('memberExportCountPrefix')} ${members.length} ${context.tr('memberExportCountSuffix')} ${choirController.selectedChoir!.name}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(context.tr('memberExportAsPdf')),
              subtitle: Text(context.tr('memberGeneratePdfDoc')),
              onTap: () {
                Navigator.pop(context);
                _exportMembers('pdf', members);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text(context.tr('memberExportAsExcel')),
              subtitle: Text(context.tr('memberGenerateExcelDoc')),
              onTap: () {
                Navigator.pop(context);
                _exportMembers('excel', members);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: Text(context.tr('memberExportAsCsv')),
              subtitle: Text(context.tr('memberGenerateCsvDoc')),
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

      if (!mounted) return;
      if (result != null) {
        Helpers.showSuccessSnackbar(context.tr('memberExportSuccess'));
      } else {
        Helpers.showErrorSnackbar(context.tr('memberExportFailed'));
      }
    } catch (e) {
      // Hide loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      if (!mounted) return;
      Helpers.showErrorSnackbar('${context.tr('memberExportFailedWithError')}: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}