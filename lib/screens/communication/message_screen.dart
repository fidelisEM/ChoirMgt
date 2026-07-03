import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/communication_controller.dart';
import '../../theme/app_colors.dart';
import 'compose_message_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final choirController = Provider.of<ChoirController>(context, listen: false);
      if (choirController.selectedChoir != null) {
        _loadMessages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMessages() async {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    final communicationController = Provider.of<CommunicationController>(context, listen: false);
    
    if (choirController.selectedChoir != null) {
      await communicationController.loadMessages(
        choirId: choirController.selectedChoir!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Messages'),
            Tab(text: 'Announcements'),
            Tab(text: 'Discussions'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          Consumer<AuthController>(
            builder: (context, authController, child) {
              if (authController.isChoirLeader) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => Get.to(() => const ComposeMessageScreen()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer3<CommunicationController, ChoirController, AuthController>(
        builder: (context, communicationController, choirController, authController, child) {
          if (choirController.selectedChoir == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No Choir Selected'),
                  Text('Please select a choir from the Choirs tab first'),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllMessagesTab(communicationController, authController),
              _buildAnnouncementsTab(communicationController, authController),
              _buildDiscussionsTab(communicationController, authController),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AuthController>(
        builder: (context, authController, child) {
          if (authController.isChoirLeader) {
            return FloatingActionButton(
              onPressed: () => Get.to(() => const ComposeMessageScreen()),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAllMessagesTab(CommunicationController controller, AuthController authController) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.messages.isEmpty) {
      return _buildEmptyState(
        'No Messages Yet',
        authController.isChoirLeader 
            ? 'Start communicating with your choir members'
            : 'Messages from choir leaders will appear here',
        authController.isChoirLeader,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final message = controller.messages[index];
        return _buildMessageCard(message, authController);
      },
    );
  }

  Widget _buildAnnouncementsTab(CommunicationController controller, AuthController authController) {
    final announcements = controller.messages.where((m) => m.type == 'announcement').toList();

    if (announcements.isEmpty) {
      return _buildEmptyState(
        'No Announcements',
        authController.isChoirLeader 
            ? 'Create your first announcement to keep members informed'
            : 'Choir announcements will appear here',
        authController.isChoirLeader,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final message = announcements[index];
        return _buildMessageCard(message, authController);
      },
    );
  }

  Widget _buildDiscussionsTab(CommunicationController controller, AuthController authController) {
    final discussions = controller.messages.where((m) => m.type == 'discussion').toList();

    if (discussions.isEmpty) {
      return _buildEmptyState(
        'No Discussions',
        'Start a discussion to engage with choir members',
        true, // Anyone can start discussions
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: discussions.length,
      itemBuilder: (context, index) {
        final message = discussions[index];
        return _buildMessageCard(message, authController);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool showAction) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (showAction) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const ComposeMessageScreen()),
              icon: const Icon(Icons.add),
              label: const Text('Send First Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageCard(message, AuthController authController) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getMessageTypeColor(message.type).withAlpha(30),
                  child: Icon(
                    _getMessageTypeIcon(message.type),
                    color: _getMessageTypeColor(message.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'From: ${message.senderName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getMessageTypeColor(message.type).withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              message.type.toUpperCase(),
                              style: TextStyle(
                                color: _getMessageTypeColor(message.type),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDateTime(message.createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Content Preview
            Text(
              message.content.length > 150 
                  ? '${message.content.substring(0, 150)}...'
                  : message.content,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewFullMessage(message),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _replyToMessage(message),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                if (message.senderId == authController.currentUser?.id) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMessageAction(message, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    child: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMessageTypeColor(String type) {
    switch (type) {
      case 'announcement':
        return AppColors.warning;
      case 'discussion':
        return AppColors.primary;
      case 'reminder':
        return AppColors.info;
      case 'urgent':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getMessageTypeIcon(String type) {
    switch (type) {
      case 'announcement':
        return Icons.campaign;
      case 'discussion':
        return Icons.forum;
      case 'reminder':
        return Icons.notification_important;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.message;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _viewFullMessage(message) {
    Get.dialog(
      AlertDialog(
        title: Text(message.subject),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'From: ${message.senderName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDateTime(message.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                message.content,
                style: const TextStyle(height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _replyToMessage(message);
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _replyToMessage(message) {
    Get.to(() => ComposeMessageScreen(
      replyTo: message,
      subject: 'Re: ${message.subject}',
    ));
  }

  void _handleMessageAction(message, String action) {
    switch (action) {
      case 'edit':
        Get.to(() => ComposeMessageScreen(
          editMessage: message,
        ));
        break;
      case 'delete':
        _showDeleteConfirmation(message);
        break;
    }
  }

  void _showDeleteConfirmation(message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Message'),
        content: Text('Are you sure you want to delete "${message.subject}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _deleteMessage(message);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(message) async {
    final communicationController = Provider.of<CommunicationController>(context, listen: false);
    
    final success = await communicationController.deleteMessage(message.id);
    
    if (success) {
      Get.snackbar(
        'Success',
        'Message deleted successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to delete message',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}