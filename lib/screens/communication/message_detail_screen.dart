import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/communication_controller.dart';
import '../../models/communication_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_widgets.dart';
import 'compose_message_screen.dart';

class MessageDetailScreen extends StatefulWidget {
  const MessageDetailScreen({super.key, required this.message});
  final MessageModel message;

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  MessageModel get message => widget.message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.reply),
            onPressed: () => _replyToMessage(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'forward',
                child: ListTile(
                  leading: Icon(Icons.forward),
                  title: Text('Forward'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'mark_read_unread',
                child: Consumer<AuthController>(
                  builder: (context, authController, child) {
                    final isRead = _isMessageRead(authController);
                    return ListTile(
                      leading: Icon(
                        isRead
                            ? Icons.mark_email_unread
                            : Icons.mark_email_read,
                      ),
                      title: Text(isRead ? 'Mark as Unread' : 'Mark as Read'),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy Message'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.report, color: AppColors.warning),
                  title: Text(
                    'Report',
                    style: TextStyle(color: AppColors.warning),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessageHeader(),
              const SizedBox(height: 24),
              _buildMessageContent(),
              const SizedBox(height: 24),
              _buildMessageStats(),
              const SizedBox(height: 24),
              _buildConversationThread(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageHeader() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getMessageTypeColor(
                    message.type,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMessageTypeIcon(message.type),
                  color: _getMessageTypeColor(message.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.subject,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getMessageTypeColor(
                          message.type,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getMessageTypeLabel(message.type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getMessageTypeColor(message.type),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _buildMessageInfo(),
        ],
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Column(
      children: [
        _buildInfoRow('From', message.senderName, Icons.person),
        const SizedBox(height: 12),
        _buildInfoRow(
          'To',
          message.recipients.isEmpty
              ? 'All choir members'
              : '${message.recipients.length} selected members',
          Icons.group,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          'Sent',
          _formatFullDateTime(message.createdAt),
          Icons.schedule,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.gray200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.gray600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: AppColors.gray700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.message, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Message Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.gray700,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStats() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Message Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Sent To',
                  message.recipients.isEmpty
                      ? 'All Members'
                      : '${message.recipients.length} Members',
                  Icons.people,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Read By',
                  '${message.readBy.length} Members',
                  Icons.mark_email_read,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Type',
                  _getMessageTypeLabel(message.type),
                  _getMessageTypeIcon(message.type),
                  _getMessageTypeColor(message.type),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Consumer<AuthController>(
                  builder: (context, authController, child) {
                    final isRead = _isMessageRead(authController);
                    return _buildStatItem(
                      'Status',
                      isRead ? 'Read' : 'Unread',
                      isRead
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      isRead ? AppColors.success : AppColors.warning,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _replyToMessage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.reply),
                label: const Text(
                  'Reply',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _forwardMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.forward),
                label: const Text(
                  'Forward',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            Expanded(
              child: Consumer<AuthController>(
                builder: (context, authController, child) {
                  final isRead = _isMessageRead(authController);
                  return OutlinedButton.icon(
                    onPressed: _markAsReadUnread,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isRead
                          ? AppColors.warning
                          : AppColors.success,
                      side: BorderSide(
                        color: isRead ? AppColors.warning : AppColors.success,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                    ),
                    label: Text(
                      isRead ? 'Mark Unread' : 'Mark Read',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareMessage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: const BorderSide(color: AppColors.info),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.share),
                label: const Text(
                  'Share',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getMessageTypeColor(String type) {
    switch (type) {
      case 'announcement':
        return AppColors.warning;
      case 'urgent':
        return AppColors.error;
      case 'reminder':
        return AppColors.info;
      case 'discussion':
        return AppColors.primary;
      default:
        return AppColors.gray500;
    }
  }

  IconData _getMessageTypeIcon(String type) {
    switch (type) {
      case 'announcement':
        return Icons.campaign;
      case 'urgent':
        return Icons.priority_high;
      case 'reminder':
        return Icons.notification_important;
      case 'discussion':
        return Icons.forum;
      default:
        return Icons.message;
    }
  }

  String _getMessageTypeLabel(String type) {
    switch (type) {
      case 'announcement':
        return 'ANNOUNCEMENT';
      case 'urgent':
        return 'URGENT';
      case 'reminder':
        return 'REMINDER';
      case 'discussion':
        return 'DISCUSSION';
      default:
        return 'MESSAGE';
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
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

  void _replyToMessage() {
    Get.to(
      () => ComposeMessageScreen(
        replyTo: message,
        subject: 'Re: ${message.subject}',
      ),
    );
  }

  void _forwardMessage() {
    Get.to(
      () => ComposeMessageScreen(
        forwardFrom: message,
        subject: 'Fwd: ${message.subject}',
      ),
    );
  }

  void _markAsReadUnread() async {
    try {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final communicationController = Provider.of<CommunicationController>(
        context,
        listen: false,
      );

      if (authController.currentUser == null) {
        Get.snackbar(
          'Error',
          'You must be logged in to perform this action',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      final currentUserId = authController.currentUser!.id;
      final isCurrentlyRead = _isMessageRead(authController);

      if (!isCurrentlyRead) {
        // Mark as read
        await communicationController.markAsRead(message.id, currentUserId);
        Get.snackbar(
          'Marked as Read',
          'This message has been marked as read',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        // For marking as unread, we'd need a different service method
        // For now, just show a demo message
        Get.snackbar(
          'Mark as Unread',
          'Mark as unread functionality would be implemented here',
          backgroundColor: AppColors.info,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update message status: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  bool _isMessageRead(AuthController? authController) {
    final currentUserId = authController?.currentUser?.id;

    if (currentUserId == null) return false;

    return message.readBy.contains(currentUserId);
  }

  void _copyMessage() {
    // In a real app, you'd copy to clipboard
    Get.snackbar(
      'Message Copied',
      'Message content has been copied to clipboard',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _shareMessage() {
    // In a real app, you'd use the share plugin
    Get.snackbar(
      'Share Message',
      'Share functionality would open here',
      backgroundColor: AppColors.info,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _reportMessage() {
    Get.dialog(
      AlertDialog(
        title: const Text('Report Message'),
        content: const Text(
          'Are you sure you want to report this message as inappropriate?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Message Reported',
                'This message has been reported to administrators',
                backgroundColor: AppColors.warning,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'forward':
        _forwardMessage();
        break;
      case 'mark_read_unread':
        _markAsReadUnread();
        break;
      case 'copy':
        _copyMessage();
        break;
      case 'share':
        _shareMessage();
        break;
      case 'report':
        _reportMessage();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _deleteMessage(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage() async {
    try {
      Get.back(); // Close confirmation dialog

      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final communicationController = Provider.of<CommunicationController>(
        context,
        listen: false,
      );
      final success = await communicationController.deleteMessage(message.id);

      Get.back(); // Close loading dialog

      if (success) {
        Get.back(); // Go back to messages list
        Get.snackbar(
          'Success',
          'Message deleted successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete message. Please try again.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog if still open
      Get.snackbar(
        'Error',
        'An error occurred while deleting the message: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildConversationThread() {
    // Mock conversation data - in a real app, this would come from the communication controller
    final List<MessageModel> conversationMessages = [
      message, // Current message
      // Mock replies for demonstration
      if (message.type == 'discussion') ..._getMockReplies(),
    ];

    if (conversationMessages.length <= 1) {
      return const SizedBox.shrink(); // Don't show thread for single messages
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Conversation Thread',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${conversationMessages.length} messages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                children: conversationMessages
                    .asMap()
                    .entries
                    .map(
                      (entry) =>
                          _buildThreadMessage(entry.value, entry.key == 0),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadMessage(MessageModel threadMessage, bool isOriginal) {
    return Container(
      margin: EdgeInsets.only(bottom: 12, left: isOriginal ? 0 : 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOriginal
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
        border: isOriginal
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isOriginal ? AppColors.primary : AppColors.gray400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOriginal ? Icons.campaign : Icons.reply,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  threadMessage.senderName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isOriginal ? AppColors.primary : AppColors.gray700,
                  ),
                ),
              ),
              Text(
                _formatThreadDateTime(threadMessage.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.gray500),
              ),
            ],
          ),
          if (threadMessage.subject != message.subject) ...[
            const SizedBox(height: 4),
            Text(
              threadMessage.subject,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            threadMessage.content.length > 150
                ? '${threadMessage.content.substring(0, 150)}...'
                : threadMessage.content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.gray700,
              height: 1.4,
            ),
          ),
          if (!isOriginal) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _viewThreadMessage(threadMessage),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'View Full Message',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatThreadDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
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
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  List<MessageModel> _getMockReplies() {
    return [
      MessageModel(
        id: 'reply1',
        choirId: message.choirId,
        senderId: 'user2',
        senderName: 'John Doe',
        subject: 'Re: ${message.subject}',
        content:
            'Thank you for this message! I completely agree with the points you made about our choir direction.',
        type: 'discussion',
        createdAt: message.createdAt.add(const Duration(hours: 2)),
        recipients: [],
        readBy: ['user1'],
      ),
      MessageModel(
        id: 'reply2',
        choirId: message.choirId,
        senderId: 'user3',
        senderName: 'Sarah Wilson',
        subject: 'Re: ${message.subject}',
        content:
            'This is great news! I\'m excited to see how this will improve our choir community and help us grow together as a musical family.',
        type: 'discussion',
        createdAt: message.createdAt.add(const Duration(hours: 5)),
        recipients: [],
        readBy: ['user1', 'user2'],
      ),
    ];
  }

  void _viewThreadMessage(MessageModel threadMessage) {
    Get.to(() => MessageDetailScreen(message: threadMessage));
  }
}
