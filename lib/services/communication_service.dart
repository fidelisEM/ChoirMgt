import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/communication_model.dart';

class CommunicationService {
  factory CommunicationService() => _instance;
  CommunicationService._internal();
  static final CommunicationService _instance = CommunicationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all messages for a choir with optional pagination and filtering
  Future<List<MessageModel>> getChoirMessages(
    String choirId, {
    int? limit = 50,
    int? offset = 0,
    String? messageType,
    bool includeReplies = true,
  }) async {
    try {
      debugPrint('CommunicationService: Fetching messages for choir $choirId');
      
      // Build the query in one chain
      var queryBuilder = _supabase
          .from('messages')
          .select('*')
          .eq('choir_id', choirId)
          .eq('is_active', true);

      // Add optional filters
      if (messageType != null) {
        queryBuilder = queryBuilder.eq('type', messageType);
      }

      // Add ordering and pagination in one chain
      var query = queryBuilder.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null && offset > 0) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;
      debugPrint('CommunicationService: Fetched ${response.length} messages');

      final List<MessageModel> messages = [];
      
      for (final messageData in response) {
        final message = MessageModel.fromJson(messageData);
        
        // Fetch replies if requested
        List<MessageReplyModel> replies = [];
        if (includeReplies) {
          replies = await getMessageReplies(message.id);
        }
        
        messages.add(message.copyWith(replies: replies));
      }

      return messages;
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error fetching messages: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get replies for a specific message
  Future<List<MessageReplyModel>> getMessageReplies(String messageId) async {
    try {
      final response = await _supabase
          .from('message_replies')
          .select('*')
          .eq('message_id', messageId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return response
          .map<MessageReplyModel>((data) => MessageReplyModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('CommunicationService: Error fetching replies: $e');
      return [];
    }
  }

  /// Send a new message
  Future<MessageModel?> sendMessage({
    required String choirId,
    required String senderId,
    required String senderName,
    required String subject,
    required String content,
    required String type,
    List<String>? recipients,
    String? parentMessageId, // For threading
  }) async {
    try {
      debugPrint('CommunicationService: Sending message to choir $choirId');

      // Validate inputs
      if (subject.trim().isEmpty) {
        throw ArgumentError('Subject cannot be empty');
      }
      if (content.trim().isEmpty) {
        throw ArgumentError('Content cannot be empty');
      }

      // Prepare message data
      final messageData = {
        'choir_id': choirId,
        'sender_id': senderId,
        'sender_name': senderName.trim(),
        'subject': subject.trim(),
        'content': content.trim(),
        'type': type,
        'recipients': recipients ?? [],
        'read_by': <String>[], // Initialize empty
        'is_active': true,
      };

      // Insert message into database
      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      debugPrint('CommunicationService: Message sent successfully');
      return MessageModel.fromJson(response);
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Reply to a message
  Future<MessageReplyModel?> replyToMessage({
    required String messageId,
    required String senderId,
    required String senderName,
    required String content,
    String? parentReplyId,
  }) async {
    try {
      debugPrint('CommunicationService: Replying to message $messageId');

      if (content.trim().isEmpty) {
        throw ArgumentError('Reply content cannot be empty');
      }

      final replyData = {
        'message_id': messageId,
        'parent_reply_id': parentReplyId,
        'sender_id': senderId,
        'sender_name': senderName.trim(),
        'content': content.trim(),
        'read_by': <String>[], // Initialize empty
        'is_active': true,
      };

      final response = await _supabase
          .from('message_replies')
          .insert(replyData)
          .select()
          .single();

      debugPrint('CommunicationService: Reply sent successfully');
      return MessageReplyModel.fromJson(response);
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error sending reply: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update an existing message
  Future<bool> updateMessage({
    required String messageId,
    required String subject,
    required String content,
    required String type,
  }) async {
    try {
      debugPrint('CommunicationService: Updating message $messageId');

      if (subject.trim().isEmpty) {
        throw ArgumentError('Subject cannot be empty');
      }
      if (content.trim().isEmpty) {
        throw ArgumentError('Content cannot be empty');
      }

      await _supabase
          .from('messages')
          .update({
            'subject': subject.trim(),
            'content': content.trim(),
            'type': type,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', _supabase.auth.currentUser?.id ?? ''); // Security: only update own messages

      debugPrint('CommunicationService: Message updated successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error updating message: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete a message (soft delete)
  Future<bool> deleteMessage(String messageId) async {
    try {
      debugPrint('CommunicationService: Deleting message $messageId');

      await _supabase
          .from('messages')
          .update({'is_active': false})
          .eq('id', messageId)
          .eq('sender_id', _supabase.auth.currentUser?.id ?? ''); // Security: only delete own messages

      debugPrint('CommunicationService: Message deleted successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error deleting message: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Mark message as read
  Future<bool> markMessageAsRead(String messageId, String userId) async {
    try {
      debugPrint('CommunicationService: Marking message $messageId as read for user $userId');

      // Use the database function for atomic operation
      await _supabase.rpc('mark_message_as_read', params: {
        'message_uuid': messageId,
        'user_uuid': userId,
      });

      debugPrint('CommunicationService: Message marked as read');
      return true;
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error marking message as read: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Mark reply as read
  Future<bool> markReplyAsRead(String replyId, String userId) async {
    try {
      debugPrint('CommunicationService: Marking reply $replyId as read for user $userId');

      await _supabase.rpc('mark_reply_as_read', params: {
        'reply_uuid': replyId,
        'user_uuid': userId,
      });

      debugPrint('CommunicationService: Reply marked as read');
      return true;
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error marking reply as read: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get unread message count for a user in a choir
  Future<int> getUnreadMessageCount(String choirId, String userId) async {
    try {
      final response = await _supabase.rpc('get_unread_message_count', params: {
        'choir_uuid': choirId,
        'user_uuid': userId,
      });

      return response as int? ?? 0;
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error getting unread count: $e');
      debugPrint('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Search messages
  Future<List<MessageModel>> searchMessages({
    required String choirId,
    required String query,
    String? messageType,
    int? limit = 20,
  }) async {
    try {
      debugPrint('CommunicationService: Searching messages for "$query"');

      if (query.trim().isEmpty) {
        return [];
      }

      final searchTerm = '%${query.trim().toLowerCase()}%';
      
      var queryBuilder = _supabase
          .from('messages')
          .select('*')
          .eq('choir_id', choirId)
          .eq('is_active', true)
          .or('subject.ilike.$searchTerm,content.ilike.$searchTerm,sender_name.ilike.$searchTerm');

      if (messageType != null) {
        queryBuilder = queryBuilder.eq('type', messageType);
      }

      var dbQuery = queryBuilder.order('created_at', ascending: false);

      if (limit != null) {
        dbQuery = dbQuery.limit(limit);
      }

      final response = await dbQuery;
      
      final List<MessageModel> messages = [];
      for (final messageData in response) {
        final message = MessageModel.fromJson(messageData);
        final replies = await getMessageReplies(message.id);
        messages.add(message.copyWith(replies: replies));
      }

      debugPrint('CommunicationService: Found ${messages.length} search results');
      return messages;
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error searching messages: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get messages by type
  Future<List<MessageModel>> getMessagesByType({
    required String choirId,
    required String messageType,
    int? limit = 50,
  }) async {
    return await getChoirMessages(
      choirId,
      limit: limit,
      messageType: messageType,
    );
  }

  /// Get message by ID with replies
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('id', messageId)
          .eq('is_active', true)
          .single();

      final message = MessageModel.fromJson(response);
      final replies = await getMessageReplies(messageId);
      
      return message.copyWith(replies: replies);
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error getting message by ID: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get message statistics for a choir
  Future<Map<String, int>> getMessageStatistics(String choirId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('type')
          .eq('choir_id', choirId)
          .eq('is_active', true);

      final stats = <String, int>{
        'total': response.length,
        'announcement': 0,
        'discussion': 0,
        'reminder': 0,
        'urgent': 0,
      };

      for (final message in response) {
        final type = message['type'] as String;
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return stats;
    } catch (e, stackTrace) {
      debugPrint('CommunicationService: Error getting message statistics: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'total': 0,
        'announcement': 0,
        'discussion': 0,
        'reminder': 0,
        'urgent': 0,
      };
    }
  }

  /// Subscribe to real-time message updates for a choir
  RealtimeChannel subscribeToChoirMessages({
    required String choirId,
    required Function(MessageModel) onMessageInserted,
    required Function(MessageModel) onMessageUpdated,
    required Function(String) onMessageDeleted,
  }) {
    return _supabase
        .channel('choir_messages_$choirId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'choir_id',
            value: choirId,
          ),
          callback: (payload) async {
            final message = MessageModel.fromJson(payload.newRecord);
            final replies = await getMessageReplies(message.id);
            onMessageInserted(message.copyWith(replies: replies));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'choir_id',
            value: choirId,
          ),
          callback: (payload) async {
            final message = MessageModel.fromJson(payload.newRecord);
            final replies = await getMessageReplies(message.id);
            onMessageUpdated(message.copyWith(replies: replies));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'choir_id',
            value: choirId,
          ),
          callback: (payload) {
            onMessageDeleted(payload.oldRecord['id'] as String);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from real-time updates
  void unsubscribeFromChoirMessages(RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }

  /// Clear all local caches (for testing/debugging)
  Future<void> clearLocalCaches() async {
    // No local caches to clear since we're using database directly
    debugPrint('CommunicationService: Local caches cleared (database-backed)');
  }
}