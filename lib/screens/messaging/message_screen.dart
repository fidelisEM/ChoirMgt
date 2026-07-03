import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/choir_controller.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

class MessageScreen extends StatefulWidget {

  const MessageScreen({
    super.key,
    this.member,
    required this.choir,
  });
  final ChoirMemberModel? member;
  final ChoirModel choir;

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final FocusNode _subjectFocusNode = FocusNode();
  
  List<ChoirMemberModel> _selectedMembers = [];
  String _messageType = 'sms';
  bool _isUrgent = false;
  bool _scheduleMessage = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  
  final List<String> _predefinedMessages = [
    'Practice session reminder: Tomorrow at 6 PM',
    'Sunday service at 9 AM. Please arrive 30 minutes early.',
    'Congratulations on your excellent performance!',
    'Please confirm your attendance for this weekend\'s event.',
    'Important: Change of venue for next practice session.',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _selectedMembers = [widget.member!];
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    _messageFocusNode.dispose();
    _subjectFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.member != null 
              ? 'Message ${_getMemberName(widget.member!)}' 
              : 'Send Message',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            tooltip: 'Send Message',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withAlpha(200),
                ],
              ),
            ),
            child: Column(
              children: [
                // Message Type Selection
                Row(
                  children: [
                    Expanded(
                      child: _buildMessageTypeCard('SMS', Icons.sms, 'sms'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMessageTypeCard('Email', Icons.email, 'email'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMessageTypeCard('Push', Icons.notifications, 'push'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Recipients Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: Colors.white.withAlpha(200), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.member != null 
                            ? '1 recipient selected'
                            : '${_selectedMembers.length} recipients selected',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (widget.member == null)
                        TextButton(
                          onPressed: _selectRecipients,
                          child: Text(
                            'Select Recipients',
                            style: TextStyle(
                              color: Colors.white.withAlpha(240),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Message Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Message Templates
                  if (_predefinedMessages.isNotEmpty) ...[
                    _buildSectionHeader('Quick Messages', Icons.flash_on),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _predefinedMessages.length,
                        itemBuilder: (context, index) {
                          return _buildQuickMessageCard(_predefinedMessages[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Subject (for email)
                  if (_messageType == 'email') ...[
                    _buildSectionHeader('Subject', Icons.subject),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subjectController,
                      focusNode: _subjectFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Enter message subject...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Message Content
                  _buildSectionHeader('Message', Icons.message),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    maxLines: _messageType == 'sms' ? 3 : 8,
                    decoration: InputDecoration(
                      hintText: _getMessageHint(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.edit, color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      counterText: _messageType == 'sms' 
                          ? '${_messageController.text.length}/160'
                          : null,
                    ),
                    onChanged: (text) {
                      if (_messageType == 'sms') {
                        setState(() {}); // Update character counter
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Message Options
                  _buildSectionHeader('Options', Icons.tune),
                  const SizedBox(height: 12),
                  
                  // Priority Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withAlpha(60)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Mark as Urgent'),
                          subtitle: Text(
                            'Recipients will receive high priority notification',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          value: _isUrgent,
                          onChanged: (value) => setState(() => _isUrgent = value),
                          activeThumbColor: AppColors.primary,
                          secondary: Icon(
                            Icons.priority_high,
                            color: _isUrgent ? AppColors.primary : Colors.grey,
                          ),
                        ),
                        
                        const Divider(),
                        
                        // Schedule Message
                        SwitchListTile(
                          title: const Text('Schedule Message'),
                          subtitle: Text(
                            _scheduledDate != null && _scheduledTime != null
                                ? 'Scheduled for ${_formatScheduledDateTime()}'
                                : 'Send message at a specific time',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          value: _scheduleMessage,
                          onChanged: (value) {
                            setState(() => _scheduleMessage = value);
                            if (value) {
                              _selectScheduleTime();
                            }
                          },
                          activeThumbColor: AppColors.primary,
                          secondary: Icon(
                            Icons.schedule,
                            color: _scheduleMessage ? AppColors.primary : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 97), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sendMessage,
        backgroundColor: AppColors.primary,
        icon: Icon(
          _scheduleMessage ? Icons.schedule_send : Icons.send,
          color: Colors.white,
        ),
        label: Text(
          _scheduleMessage ? 'Schedule' : 'Send Now',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMessageTypeCard(String title, IconData icon, String type) {
    final isSelected = _messageType == type;
    return GestureDetector(
      onTap: () => setState(() => _messageType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withAlpha(60)
              : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.white.withAlpha(120)
                : Colors.white.withAlpha(40),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isSelected ? 24 : 20,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSelected ? 14 : 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMessageCard(String message) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          _messageController.text = message;
          _messageFocusNode.requestFocus();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(40),
                AppColors.primary.withAlpha(20),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.touch_app, color: AppColors.primary, size: 16),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                'Tap to use',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMemberName(ChoirMemberModel member) {
    // This would typically get the actual name from user data
    return 'Member ${member.registrationNumber}';
  }

  String _getMessageHint() {
    switch (_messageType) {
      case 'sms':
        return 'Type your SMS message here (max 160 characters)...';
      case 'email':
        return 'Compose your email message here...';
      case 'push':
        return 'Write your push notification message...';
      default:
        return 'Type your message here...';
    }
  }

  String _formatScheduledDateTime() {
    if (_scheduledDate == null || _scheduledTime == null) return '';
    return '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} at ${_scheduledTime!.format(context)}';
  }

  void _selectRecipients() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => RecipientSelectionSheet(
        choir: widget.choir,
        selectedMembers: _selectedMembers,
        onSelectionChanged: (members) {
          setState(() => _selectedMembers = members);
        },
      ),
    );
  }

  void _selectScheduleTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        setState(() {
          _scheduledDate = date;
          _scheduledTime = time;
        });
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one recipient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simulate sending message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(_scheduleMessage ? 'Scheduling message...' : 'Sending message...'),
          ],
        ),
      ),
    );

    // Simulate API call delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close loading dialog
      Navigator.of(context).pop(); // Close message screen
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _scheduleMessage 
                ? 'Message scheduled successfully!'
                : 'Message sent to ${_selectedMembers.length} member(s)!',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    });
  }
}

// Recipient Selection Sheet
class RecipientSelectionSheet extends StatefulWidget {

  const RecipientSelectionSheet({
    super.key,
    required this.choir,
    required this.selectedMembers,
    required this.onSelectionChanged,
  });
  final ChoirModel choir;
  final List<ChoirMemberModel> selectedMembers;
  final Function(List<ChoirMemberModel>) onSelectionChanged;

  @override
  State<RecipientSelectionSheet> createState() => _RecipientSelectionSheetState();
}

class _RecipientSelectionSheetState extends State<RecipientSelectionSheet> {
  List<ChoirMemberModel> _tempSelectedMembers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelectedMembers = List.from(widget.selectedMembers);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Text(
                'Select Recipients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Actions
          Row(
            children: [
              TextButton.icon(
                onPressed: _selectAll,
                icon: const Icon(Icons.select_all),
                label: const Text('Select All'),
              ),
              TextButton.icon(
                onPressed: _clearSelection,
                icon: const Icon(Icons.clear),
                label: const Text('Clear All'),
              ),
            ],
          ),
          
          // Members List
          Expanded(
            child: Consumer<ChoirController>(
              builder: (context, controller, child) {
                final filteredMembers = _getFilteredMembers(controller.choirMembers);
                
                return ListView.builder(
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    final isSelected = _tempSelectedMembers.any((m) => m.id == member.id);
                    
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _tempSelectedMembers.add(member);
                          } else {
                            _tempSelectedMembers.removeWhere((m) => m.id == member.id);
                          }
                        });
                      },
                      title: Text('Member ${member.registrationNumber}'),
                      subtitle: Text('ID: ${member.registrationNumber}'),
                      activeColor: AppColors.primary,
                    );
                  },
                );
              },
            ),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSelectionChanged(_tempSelectedMembers);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Select ${_tempSelectedMembers.length}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ChoirMemberModel> _getFilteredMembers(List<ChoirMemberModel> members) {
    if (_searchQuery.isEmpty) return members;
    
    return members.where((member) {
      return member.registrationNumber.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _selectAll() {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    setState(() {
      _tempSelectedMembers = List.from(choirController.choirMembers);
    });
  }

  void _clearSelection() {
    setState(() {
      _tempSelectedMembers.clear();
    });
  }
}