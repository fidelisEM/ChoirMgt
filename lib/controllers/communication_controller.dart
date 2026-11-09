import 'package:flutter/material.dart';
import '../models/communication_model.dart';
import '../services/communication_service.dart';
import '../utils/logger.dart';

class CommunicationController extends ChangeNotifier {
  final CommunicationService _communicationService = CommunicationService();

  List<MessageModel> _messages = [];
  final List<MessageModel> _sentMessages = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<MessageModel> get messages => _messages;
  List<MessageModel> get sentMessages => _sentMessages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load messages for a choir
  Future<void> loadMessages({required String choirId}) async {
    try {
      _setLoading(true);
      _clearError();

      _messages = await _communicationService.getChoirMessages(choirId);
      _setLoading(false);
    } catch (e, stackTrace) {
      Logger.error('Error loading messages', e, stackTrace);
      _setError('Failed to load messages: $e');
      _setLoading(false);
    }
  }

  // Send a new message
  Future<bool> sendMessage({
    required String choirId,
    required String senderId,
    required String senderName,
    required String subject,
    required String content,
    required String type,
    List<String>? recipients,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final message = await _communicationService.sendMessage(
        choirId: choirId,
        senderId: senderId,
        senderName: senderName,
        subject: subject,
        content: content,
        type: type,
        recipients: recipients,
      );

      if (message != null) {
        // Add to local messages list
        _messages.insert(0, message);
        notifyListeners();
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      Logger.error('Error sending message', e, stackTrace);
      _setError('Failed to send message: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update an existing message
  Future<bool> updateMessage({
    required String messageId,
    required String choirId,
    required String subject,
    required String content,
    required String type,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _communicationService.updateMessage(
        messageId: messageId,
        subject: subject,
        content: content,
        type: type,
      );

      if (success) {
        // Reload messages to get the latest data
        await loadMessages(choirId: choirId);
      }

      _setLoading(false);
      return success;
    } catch (e, stackTrace) {
      Logger.error('Error updating message', e, stackTrace);
      _setError('Failed to update message: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _communicationService.deleteMessage(messageId);

      if (success) {
        // Remove from local list
        _messages.removeWhere((message) => message.id == messageId);
        notifyListeners();
      }

      _setLoading(false);
      return success;
    } catch (e, stackTrace) {
      Logger.error('Error deleting message', e, stackTrace);
      _setError('Failed to delete message: $e');
      _setLoading(false);
      return false;
    }
  }

  // Reply to a message
  Future<bool> replyToMessage({
    required String messageId,
    required String senderId,
    required String senderName,
    required String content,
    String? parentReplyId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final reply = await _communicationService.replyToMessage(
        messageId: messageId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        parentReplyId: parentReplyId,
      );

      if (reply != null) {
        // Update the message with the new reply
        final messageIndex = _messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            replies: [..._messages[messageIndex].replies, reply],
          );
        }
        notifyListeners();
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      Logger.error('Error replying to message', e, stackTrace);
      _setError('Failed to send reply: $e');
      _setLoading(false);
      return false;
    }
  }

  // Mark message as read
  Future<void> markAsRead(String messageId, String userId) async {
    try {
      await _communicationService.markMessageAsRead(messageId, userId);

      // Update local message
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        // Update read status locally
        notifyListeners();
      }
    } catch (e, stackTrace) {
      Logger.error('Error marking message as read', e, stackTrace);
    }
  }

  // Get unread message count
  int getUnreadCount(String userId) {
    return _messages
        .where(
          (message) =>
              !message.readBy.contains(userId) && message.senderId != userId,
        )
        .length;
  }

  // Get messages by type
  List<MessageModel> getMessagesByType(String type) {
    return _messages.where((message) => message.type == type).toList();
  }

  // Search messages
  List<MessageModel> searchMessages(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _messages
        .where(
          (message) =>
              message.subject.toLowerCase().contains(lowercaseQuery) ||
              message.content.toLowerCase().contains(lowercaseQuery) ||
              message.senderName.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  // Clear all messages
  void clearMessages() {
    _messages.clear();
    _sentMessages.clear();
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
