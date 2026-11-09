import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/communication_controller.dart';
import '../../controllers/member_controller.dart';
import '../../models/communication_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_widgets.dart';

class ComposeMessageScreen extends StatefulWidget {
  const ComposeMessageScreen({
    super.key,
    this.editMessage,
    this.replyTo,
    this.forwardFrom,
    this.subject,
  });
  final MessageModel? editMessage;
  final MessageModel? replyTo;
  final MessageModel? forwardFrom;
  final String? subject;

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedType = 'discussion';
  String _selectedRecipientGroup = 'all';
  List<String> _selectedMembers = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get _recipientGroups => [
    {
      'value': 'all',
      'label': context.tr('msgRecipientAll'),
      'description': context.tr('msgRecipientAllDesc'),
      'icon': Icons.groups,
      'color': AppColors.primary,
    },
    {
      'value': 'leaders',
      'label': context.tr('msgRecipientLeaders'),
      'description': context.tr('msgRecipientLeadersDesc'),
      'icon': Icons.admin_panel_settings,
      'color': AppColors.warning,
    },
    {
      'value': 'committee',
      'label': context.tr('msgRecipientCommittee'),
      'description': context.tr('msgRecipientCommitteeDesc'),
      'icon': Icons.business_center,
      'color': AppColors.info,
    },
    {
      'value': 'active',
      'label': context.tr('msgRecipientActive'),
      'description': context.tr('msgRecipientActiveDesc'),
      'icon': Icons.verified_user,
      'color': AppColors.success,
    },
    {
      'value': 'custom',
      'label': context.tr('msgRecipientCustom'),
      'description': context.tr('msgRecipientCustomDesc'),
      'icon': Icons.person_add,
      'color': AppColors.gray600,
    },
  ];

  List<Map<String, dynamic>> get _messageTypes => [
    {
      'value': 'announcement',
      'label': context.tr('msgTypeAnnouncement'),
      'description': context.tr('msgTypeAnnouncementDesc'),
      'icon': Icons.campaign,
      'color': AppColors.warning,
    },
    {
      'value': 'discussion',
      'label': context.tr('msgTypeDiscussion'),
      'description': context.tr('msgTypeDiscussionDesc'),
      'icon': Icons.forum,
      'color': AppColors.primary,
    },
    {
      'value': 'reminder',
      'label': context.tr('msgTypeReminder'),
      'description': context.tr('msgTypeReminderDesc'),
      'icon': Icons.notification_important,
      'color': AppColors.info,
    },
    {
      'value': 'urgent',
      'label': context.tr('msgTypeUrgent'),
      'description': context.tr('msgTypeUrgentDesc'),
      'icon': Icons.priority_high,
      'color': AppColors.error,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.editMessage != null) {
      // Editing existing message
      _subjectController.text = widget.editMessage!.subject;
      _contentController.text = widget.editMessage!.content;
      _selectedType = widget.editMessage!.type;
    } else if (widget.replyTo != null) {
      // Replying to message
      _subjectController.text =
          widget.subject ?? 'Re: ${widget.replyTo!.subject}';
      _contentController.text =
          '\n\n--- Original Message ---\nFrom: ${widget.replyTo!.senderName}\nSubject: ${widget.replyTo!.subject}\nSent: ${_formatDateTime(widget.replyTo!.createdAt)}\n\n${widget.replyTo!.content}';
      _selectedType = 'discussion';
    } else if (widget.forwardFrom != null) {
      // Forwarding message
      _subjectController.text =
          widget.subject ?? 'Fwd: ${widget.forwardFrom!.subject}';
      _contentController.text =
          '\n\n--- Forwarded Message ---\nFrom: ${widget.forwardFrom!.senderName}\nSubject: ${widget.forwardFrom!.subject}\nSent: ${_formatDateTime(widget.forwardFrom!.createdAt)}\nType: ${widget.forwardFrom!.type.toUpperCase()}\n\n${widget.forwardFrom!.content}';
      _selectedType = widget.forwardFrom!.type;
      // When forwarding, suggest sending to all members by default
      _selectedRecipientGroup = 'all';
    } else if (widget.subject != null) {
      // Pre-filled subject
      _subjectController.text = widget.subject!;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year at $hour:$minute $ampm';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.editMessage != null;
  bool get isReplying => widget.replyTo != null;
  bool get isForwarding => widget.forwardFrom != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? context.tr('msgEditMessage')
              : isReplying
              ? context.tr('msgReplyToMessage')
              : isForwarding
              ? context.tr('msgForwardMessage')
              : context.tr('msgComposeMessage'),
        ),
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
                  _buildHeader(isEditing),
                  const SizedBox(height: 24),
                  _buildRecipientSelection(),
                  const SizedBox(height: 16),
                  _buildMessageTypeSelection(),
                  const SizedBox(height: 16),
                  _buildSubjectField(),
                  const SizedBox(height: 16),
                  _buildContentField(),
                  const SizedBox(height: 32),
                  _buildActionButtons(isEditing, isReplying, isForwarding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.message,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEditing
                ? context.tr('msgEditMessage')
                : isReplying
                ? context.tr('msgReplyToMessage')
                : isForwarding
                ? context.tr('msgForwardMessage')
                : context.tr('msgComposeNewMessage'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEditing
                ? context.tr('msgEditSubtitle')
                : isReplying
                ? context.tr('msgReplySubtitle')
                : isForwarding
                ? context.tr('msgForwardSubtitle')
                : context.tr('msgComposeSubtitle'),
            style: const TextStyle(color: AppColors.gray600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientSelection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('msgSendTo'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recipientGroups.map((group) {
              final isSelected = _selectedRecipientGroup == group['value'];
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      group['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : group['color'],
                    ),
                    const SizedBox(width: 8),
                    Text(group['label'] as String),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedRecipientGroup = group['value'] as String;
                    if (_selectedRecipientGroup != 'custom') {
                      _selectedMembers
                          .clear(); // Clear custom selection when changing groups
                    }
                  });
                },
                selectedColor: group['color'] as Color,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getSelectedRecipientColor().withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getSelectedRecipientIcon(),
                  color: _getSelectedRecipientColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSelectedRecipientDescription(),
                    style: TextStyle(
                      color: _getSelectedRecipientColor(),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedRecipientGroup == 'custom') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('msgChooseSpecificMembers'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildCustomMemberSelection(),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomMemberSelection() {
    return Consumer2<ChoirController, MemberController>(
      builder: (context, choirController, memberController, child) {
        final selectedChoir = choirController.selectedChoir;
        if (selectedChoir == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('msgSelectChoirFirst'),
              style: const TextStyle(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Load members if not loaded yet
        if (memberController.membersWithUserInfo.isEmpty &&
            !memberController.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            memberController.loadChoirMembers(selectedChoir.id);
          });
        }

        if (memberController.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final members = memberController.membersWithUserInfo;

        if (members.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('msgNoMembersInChoir'),
              style: const TextStyle(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('msgSelectMembersLabel'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedMembers.length == members.length) {
                        _selectedMembers.clear();
                      } else {
                        _selectedMembers = members
                            .map((m) => m['users']['id'] as String)
                            .toList();
                      }
                    });
                  },
                  child: Text(
                    _selectedMembers.length == members.length
                        ? context.tr('msgClearAll')
                        : context.tr('msgSelectAll'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: members.map((member) {
                    final userData = member['users'] as Map<String, dynamic>;
                    final memberData = member;
                    final userId = userData['id'] as String;
                    final isSelected = _selectedMembers.contains(userId);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedMembers.add(userId);
                          } else {
                            _selectedMembers.remove(userId);
                          }
                        });
                      },
                      title: Text(
                        userData['full_name'] as String? ?? 'Unknown Name',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (memberData['role'] as String? ?? 'Member')
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (userData['email'] != null)
                            Text(
                              userData['email'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                      dense: true,
                      isThreeLine: userData['email'] != null,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_selectedMembers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_selectedMembers.length} ${context.tr('msgMembersSelectedSuffix')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMessageTypeSelection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('msgMessageType'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _messageTypes.map((type) {
              final isSelected = _selectedType == type['value'];
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : type['color'],
                    ),
                    const SizedBox(width: 8),
                    Text(type['label'] as String),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedType = type['value'] as String;
                  });
                },
                selectedColor: type['color'] as Color,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getSelectedTypeColor().withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getSelectedTypeIcon(),
                  color: _getSelectedTypeColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSelectedTypeDescription(),
                    style: TextStyle(
                      color: _getSelectedTypeColor(),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('msgSubject'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: context.tr('msgSubjectFieldLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title),
            ),
            validator: (value) => Validators.required(value, 'subject'),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildContentField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('msgMessageContent'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: context.tr('msgWriteMessageHint'),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => Validators.required(value, 'message content'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getRecipientInfoText(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    bool isEditing,
    bool isReplying,
    bool isForwarding,
  ) {
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
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _sendMessage(isEditing),
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isEditing ? Icons.save : Icons.send),
                      const SizedBox(width: 8),
                      Text(
                        isEditing
                            ? context.tr('update')
                            : isReplying
                            ? context.tr('msgSendReply')
                            : isForwarding
                            ? context.tr('msgForwardMessage')
                            : context.tr('msgSendMessage'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Color _getSelectedTypeColor() {
    return _messageTypes.firstWhere(
          (type) => type['value'] == _selectedType,
          orElse: () => _messageTypes[0],
        )['color']
        as Color;
  }

  IconData _getSelectedTypeIcon() {
    return _messageTypes.firstWhere(
          (type) => type['value'] == _selectedType,
          orElse: () => _messageTypes[0],
        )['icon']
        as IconData;
  }

  String _getSelectedTypeDescription() {
    return _messageTypes.firstWhere(
          (type) => type['value'] == _selectedType,
          orElse: () => _messageTypes[0],
        )['description']
        as String;
  }

  Color _getSelectedRecipientColor() {
    return _recipientGroups.firstWhere(
          (group) => group['value'] == _selectedRecipientGroup,
          orElse: () => _recipientGroups[0],
        )['color']
        as Color;
  }

  IconData _getSelectedRecipientIcon() {
    return _recipientGroups.firstWhere(
          (group) => group['value'] == _selectedRecipientGroup,
          orElse: () => _recipientGroups[0],
        )['icon']
        as IconData;
  }

  String _getSelectedRecipientDescription() {
    final description =
        _recipientGroups.firstWhere(
              (group) => group['value'] == _selectedRecipientGroup,
              orElse: () => _recipientGroups[0],
            )['description']
            as String;

    if (_selectedRecipientGroup == 'custom' && _selectedMembers.isNotEmpty) {
      return '$description (${_selectedMembers.length} selected)';
    }
    return description;
  }

  List<String>? _getRecipientsForGroup() {
    final memberController = Provider.of<MemberController>(
      context,
      listen: false,
    );
    final members = memberController.membersWithUserInfo;

    switch (_selectedRecipientGroup) {
      case 'all':
        return null; // null means all members
      case 'leaders':
        // Filter members with leader roles
        return members
            .where((member) {
              final role = member['role'] as String? ?? '';
              return role.toLowerCase().contains('leader') ||
                  role.toLowerCase().contains('admin') ||
                  role.toLowerCase().contains('chair');
            })
            .map((member) => member['users']['id'] as String)
            .toList();
      case 'committee':
        // Filter members with committee roles
        return members
            .where((member) {
              final role = member['role'] as String? ?? '';
              return role.toLowerCase().contains('committee') ||
                  role.toLowerCase().contains('officer');
            })
            .map((member) => member['users']['id'] as String)
            .toList();
      case 'active':
        // Filter active members
        return members
            .where((member) {
              final status = member['status'] as String? ?? 'active';
              return status.toLowerCase() == 'active';
            })
            .map((member) => member['users']['id'] as String)
            .toList();
      case 'custom':
        return _selectedMembers.isNotEmpty ? _selectedMembers : null;
      default:
        return null;
    }
  }

  String _getRecipientInfoText() {
    final memberController = Provider.of<MemberController>(
      context,
      listen: false,
    );
    final totalMembers = memberController.membersWithUserInfo.length;

    switch (_selectedRecipientGroup) {
      case 'all':
        return totalMembers > 0
            ? '${context.tr('msgSendToAllPrefix')} $totalMembers ${context.tr('msgChoirMembersSuffix')}'
            : context.tr('msgSendToAllMembers');
      case 'leaders':
        final recipients = _getRecipientsForGroup();
        final count = recipients?.length ?? 0;
        return '${context.tr('msgSendToPrefix')} $count ${context.tr('msgChoirLeadersSuffix')}';
      case 'committee':
        final recipients = _getRecipientsForGroup();
        final count = recipients?.length ?? 0;
        return '${context.tr('msgSendToPrefix')} $count ${context.tr('msgCommitteeMembersSuffix')}';
      case 'active':
        final recipients = _getRecipientsForGroup();
        final count = recipients?.length ?? 0;
        return '${context.tr('msgSendToPrefix')} $count ${context.tr('msgActiveMembersSuffix')}';
      case 'custom':
        if (_selectedMembers.isEmpty) {
          return context.tr('msgSelectMembersToSend');
        }
        return '${context.tr('msgSendToPrefix')} ${_selectedMembers.length} ${context.tr('msgSelectedMembersSuffix')}';
      default:
        return context.tr('msgSendToAllMembers');
    }
  }

  Future<void> _sendMessage(bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate recipient selection for custom option
    if (_selectedRecipientGroup == 'custom' && _selectedMembers.isEmpty) {
      Helpers.showErrorSnackbar(context.tr('msgSelectAtLeastOneMember'));
      return;
    }

    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final authController = Provider.of<AuthController>(context, listen: false);

    if (choirController.selectedChoir == null) {
      Helpers.showErrorSnackbar(context.tr('msgSelectChoirFirst'));
      return;
    }

    if (authController.currentUser == null) {
      Helpers.showErrorSnackbar(context.tr('msgLoginRequiredToSend'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final successMessage = isEditing
        ? context.tr('msgUpdatedSuccess')
        : context.tr('msgSentSuccess');
    final failureMessage = isEditing
        ? context.tr('msgUpdateFailed')
        : context.tr('msgSendFailed');
    final errorPrefix = context.tr('error');

    try {
      final communicationController = Provider.of<CommunicationController>(
        context,
        listen: false,
      );
      bool success = false;

      if (isEditing && widget.editMessage != null) {
        // Update existing message
        success = await communicationController.updateMessage(
          messageId: widget.editMessage!.id,
          choirId: choirController.selectedChoir!.id,
          subject: _subjectController.text.trim(),
          content: _contentController.text.trim(),
          type: _selectedType,
        );
      } else {
        // Send new message
        success = await communicationController.sendMessage(
          choirId: choirController.selectedChoir!.id,
          senderId: authController.currentUser!.id,
          senderName: authController.currentUser!.fullName,
          subject: _subjectController.text.trim(),
          content: _contentController.text.trim(),
          type: _selectedType,
          recipients: _getRecipientsForGroup(),
        );
      }

      if (success) {
        Get.back(); // pop before the snackbar, which is itself a route
        Helpers.showSuccessSnackbar(successMessage);
      } else {
        Helpers.showErrorSnackbar(failureMessage);
      }
    } catch (e) {
      Helpers.showErrorSnackbar('$errorPrefix: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
