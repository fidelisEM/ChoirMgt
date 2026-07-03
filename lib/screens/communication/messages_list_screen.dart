import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/communication_controller.dart';
import '../../models/communication_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_widgets.dart';
import 'compose_message_screen.dart';
import 'message_detail_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<MessageModel> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterMessages();
    });
  }

  void _loadMessages() {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    final communicationController = Provider.of<CommunicationController>(context, listen: false);
    
    if (choirController.selectedChoir != null) {
      communicationController.loadMessages(choirId: choirController.selectedChoir!.id);
    }
  }

  void _filterMessages() {
    final communicationController = Provider.of<CommunicationController>(context, listen: false);
    List<MessageModel> filtered = communicationController.messages;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = communicationController.searchMessages(_searchQuery);
    }

    // Filter by tab
    switch (_tabController.index) {
      case 0: // All
        break;
      case 1: // Unread
        filtered = filtered.where((message) => !_isMessageRead(message)).toList();
        break;
      case 2: // Announcements
        filtered = filtered.where((message) =>
            message.type == 'announcement' || message.type == 'urgent').toList();
        break;
      case 3: // Discussions
        filtered = filtered.where((message) => message.type == 'discussion').toList();
        break;
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _filteredMessages = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _composeMessage(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (_) => _filterMessages(),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('All'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getTabCount(0)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unread'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getTabCount(1)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Announcements'),
            const Tab(text: 'Discussions'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Consumer2<CommunicationController, ChoirController>(
          builder: (context, communicationController, choirController, child) {
            return _buildBody(communicationController, choirController);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _composeMessage,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(CommunicationController communicationController, ChoirController choirController) {
    if (choirController.selectedChoir == null) {
      return const Center(
        child: Text(
          'Please select a choir to view messages',
          style: TextStyle(fontSize: 16, color: AppColors.gray600),
        ),
      );
    }

    if (communicationController.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (communicationController.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${communicationController.errorMessage}',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Update filtered messages based on real data
    _updateFilteredMessages(communicationController);

    if (_filteredMessages.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _loadMessages(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredMessages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final message = _filteredMessages[index];
          return _buildMessageCard(message);
        },
      ),
    );
  }

  void _updateFilteredMessages(CommunicationController communicationController) {
    List<MessageModel> filtered = communicationController.messages;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = communicationController.searchMessages(_searchQuery);
    }

    // Filter by tab
    switch (_tabController.index) {
      case 0: // All
        break;
      case 1: // Unread
        filtered = filtered.where((message) => !_isMessageRead(message)).toList();
        break;
      case 2: // Announcements
        filtered = filtered.where((message) => message.type == 'announcement').toList();
        break;
      case 3: // Discussions
        filtered = filtered.where((message) => message.type == 'discussion').toList();
        break;
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _filteredMessages = filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.gray200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search_off : Icons.message,
                size: 64,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty ? 'No messages found' : 'No messages yet',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Start a conversation with your choir members',
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _searchQuery.isNotEmpty ? _clearSearch : _composeMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: Icon(_searchQuery.isNotEmpty ? Icons.clear : Icons.add),
              label: Text(_searchQuery.isNotEmpty ? 'Clear Search' : 'Compose Message'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(MessageModel message) {
    return GlassCard(
      onTap: () => _openMessage(message),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getMessageTypeColor(message.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _isMessageRead(message) ? FontWeight.w500 : FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
                  if (!_isMessageRead(message)) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message.content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.gray600,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMessageTypeColor(message.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getMessageTypeLabel(message.type),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getMessageTypeColor(message.type),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                message.recipients.isEmpty
                    ? 'All members'
                    : '${message.recipients.length} recipients',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getTabCount(int tabIndex) {
    final communicationController = Provider.of<CommunicationController>(context, listen: false);
    final messages = communicationController.messages;
    
    switch (tabIndex) {
      case 0: // All
        return messages.length;
      case 1: // Unread
        return messages.where((m) => !_isMessageRead(m)).length;
      case 2: // Announcements
        return messages.where((m) => m.type == 'announcement' || m.type == 'urgent').length;
      case 3: // Discussions
        return messages.where((m) => m.type == 'discussion').length;
      default:
        return 0;
    }
  }

  bool _isMessageRead(MessageModel message) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUserId = authController.currentUser?.id;
    
    if (currentUserId == null) return false;
    
    return message.readBy.contains(currentUserId);
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

  String _formatMessageTime(DateTime dateTime) {
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearSearch();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filterMessages();
    });
  }

  void _composeMessage() {
    Get.to(() => const ComposeMessageScreen());
  }

  void _openMessage(MessageModel message) {
    // Mark as read by adding current user to readBy list
    setState(() {
      if (!message.readBy.contains('user1')) {
        message.readBy.add('user1');
      }
      _filterMessages();
    });

    Get.to(() => MessageDetailScreen(message: message));
  }
}