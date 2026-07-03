import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  factory OfflineService() => _instance;
  OfflineService._internal();
  static final OfflineService _instance = OfflineService._internal();

  static const String _pendingActionsKey = 'pending_actions';
  static const String _cachedDataKey = 'cached_data';

  // Queue actions when offline
  Future<void> queueAction(Map<String, dynamic> action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingActions = prefs.getStringList(_pendingActionsKey) ?? [];
      
      action['timestamp'] = DateTime.now().toIso8601String();
      action['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      
      existingActions.add(jsonEncode(action));
      await prefs.setStringList(_pendingActionsKey, existingActions);
      
      debugPrint('Queued offline action: ${action['type']}');
    } catch (e) {
      debugPrint('Error queuing offline action: $e');
    }
  }

  // Get pending actions
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionStrings = prefs.getStringList(_pendingActionsKey) ?? [];
      
      return actionStrings
          .map((actionString) => jsonDecode(actionString) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting pending actions: $e');
      return [];
    }
  }

  // Process pending actions when back online
  Future<void> processPendingActions() async {
    try {
      final pendingActions = await getPendingActions();
      if (pendingActions.isEmpty) return;

      debugPrint('Processing ${pendingActions.length} pending actions');

      for (final action in pendingActions) {
        try {
          await _processAction(action);
          await _removeAction(action['id']);
          debugPrint('Processed action: ${action['type']}');
        } catch (e) {
          debugPrint('Failed to process action ${action['type']}: $e');
          // Keep the action in queue for retry
        }
      }
    } catch (e) {
      debugPrint('Error processing pending actions: $e');
    }
  }

  // Process individual action based on type
  Future<void> _processAction(Map<String, dynamic> action) async {
    switch (action['type']) {
      case 'add_member':
        // Would implement actual API call here
        // await MemberService().addMemberToChoir(...)
        break;
      case 'update_member':
        // await MemberService().updateMember(...)
        break;
      case 'record_attendance':
        // await AttendanceService().recordAttendance(...)
        break;
      case 'add_payment':
        // await PaymentService().addPayment(...)
        break;
      default:
        debugPrint('Unknown action type: ${action['type']}');
    }
  }

  // Remove processed action
  Future<void> _removeAction(String actionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionStrings = prefs.getStringList(_pendingActionsKey) ?? [];
      
      final filteredActions = actionStrings.where((actionString) {
        final action = jsonDecode(actionString) as Map<String, dynamic>;
        return action['id'] != actionId;
      }).toList();
      
      await prefs.setStringList(_pendingActionsKey, filteredActions);
    } catch (e) {
      debugPrint('Error removing action: $e');
    }
  }

  // Cache data for offline use
  Future<void> cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheMap = await _getCacheMap();
      
      cacheMap[key] = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_cachedDataKey, jsonEncode(cacheMap));
      debugPrint('Cached data for key: $key');
    } catch (e) {
      debugPrint('Error caching data: $e');
    }
  }

  // Get cached data
  Future<T?> getCachedData<T>(String key, {Duration? maxAge}) async {
    try {
      final cacheMap = await _getCacheMap();
      final cachedEntry = cacheMap[key];
      
      if (cachedEntry == null) return null;
      
      if (maxAge != null) {
        final timestamp = DateTime.parse(cachedEntry['timestamp']);
        final age = DateTime.now().difference(timestamp);
        
        if (age > maxAge) {
          // Data is too old, remove it
          await _removeCachedData(key);
          return null;
        }
      }
      
      return cachedEntry['data'] as T;
    } catch (e) {
      debugPrint('Error getting cached data: $e');
      return null;
    }
  }

  // Get cache map
  Future<Map<String, dynamic>> _getCacheMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_cachedDataKey);
      
      if (cacheString == null) return {};
      return jsonDecode(cacheString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting cache map: $e');
      return {};
    }
  }

  // Remove cached data
  Future<void> _removeCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheMap = await _getCacheMap();
      
      cacheMap.remove(key);
      await prefs.setString(_cachedDataKey, jsonEncode(cacheMap));
    } catch (e) {
      debugPrint('Error removing cached data: $e');
    }
  }

  // Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedDataKey);
      debugPrint('Cleared all cached data');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Clear all pending actions (use with caution)
  Future<void> clearPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingActionsKey);
      debugPrint('Cleared all pending actions');
    } catch (e) {
      debugPrint('Error clearing pending actions: $e');
    }
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheMap = await _getCacheMap();
      final pendingActions = await getPendingActions();
      
      int totalSize = 0;
      for (final entry in cacheMap.values) {
        totalSize += jsonEncode(entry).length;
      }
      
      return {
        'cached_items': cacheMap.length,
        'pending_actions': pendingActions.length,
        'total_cache_size': totalSize,
        'oldest_cache_entry': _getOldestCacheEntry(cacheMap),
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }

  String? _getOldestCacheEntry(Map<String, dynamic> cacheMap) {
    if (cacheMap.isEmpty) return null;
    
    DateTime? oldest;
    String? oldestKey;
    
    for (final entry in cacheMap.entries) {
      final timestamp = DateTime.parse(entry.value['timestamp']);
      if (oldest == null || timestamp.isBefore(oldest)) {
        oldest = timestamp;
        oldestKey = entry.key;
      }
    }
    
    return oldestKey;
  }
}

// Mixin to add offline capabilities to services
mixin OfflineCapable {
  Future<T> executeWithOfflineSupport<T>(
    String actionType,
    Map<String, dynamic> actionData,
    Future<T> Function() onlineAction,
    T Function()? offlineFallback,
  ) async {
    try {
      // Try online action first
      final result = await onlineAction();
      
      // If successful and we have cached offline actions, process them
      if (await _hasConnection()) {
        OfflineService().processPendingActions();
      }
      
      return result;
    } catch (e) {
      // Online action failed, check if it's a connection issue
      if (await _isConnectionError(e)) {
        // Queue for later processing
        await OfflineService().queueAction({
          'type': actionType,
          ...actionData,
        });
        
        // Return offline fallback if available
        if (offlineFallback != null) {
          return offlineFallback();
        }
      }
      
      rethrow;
    }
  }

  Future<bool> _hasConnection() async {
    // Simplified connection check
    // In a real app, you'd use connectivity_plus package
    return true; // Assume online for now
  }

  Future<bool> _isConnectionError(dynamic error) async {
    // Check if error indicates connection issues
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable');
  }
}