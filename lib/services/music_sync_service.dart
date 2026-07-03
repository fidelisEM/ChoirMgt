import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_model.dart';
import '../services/music_service.dart';
import '../services/swahili_music_scraper.dart';
import '../utils/logger.dart';

class MusicSyncService {
  static const String _lastSyncKey = 'last_music_sync';
  static const String _syncEnabledKey = 'music_sync_enabled';
  static const Duration _syncInterval = Duration(hours: 24); // Sync every 24 hours
  static const Duration _backgroundSyncInterval = Duration(minutes: 30); // Check every 30 minutes
  
  static Timer? _backgroundTimer;
  static bool _isSyncing = false;
  
  /// Initialize the music sync service
  static Future<void> initialize() async {
    try {
      Logger.info('[MusicSyncService] Initializing music sync service...');

      // Check if sync is enabled
      final prefs = await SharedPreferences.getInstance();
      final syncEnabled = prefs.getBool(_syncEnabledKey) ?? true;

      if (syncEnabled) {
        // Check if we need to sync immediately
        await _checkAndPerformSync();

        // Start background sync timer
        _startBackgroundSync();

        Logger.info('[MusicSyncService] Music sync service initialized successfully');
      } else {
        Logger.info('[MusicSyncService] Music sync is disabled');
      }
    } catch (e) {
      Logger.error('[MusicSyncService] Error initializing sync service', e);
    }
  }
  
  /// Start background sync timer
  static void _startBackgroundSync() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(_backgroundSyncInterval, (timer) {
      _checkAndPerformSync();
    });
    Logger.debug('[MusicSyncService] Background sync timer started');
  }

  /// Stop background sync timer
  static void stopBackgroundSync() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    Logger.debug('[MusicSyncService] Background sync timer stopped');
  }

  /// Check if sync is needed and perform it
  static Future<void> _checkAndPerformSync() async {
    try {
      if (_isSyncing) {
        Logger.warning('[MusicSyncService] Sync already in progress, skipping...');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      
      DateTime? lastSync;
      if (lastSyncString != null) {
        lastSync = DateTime.tryParse(lastSyncString);
      }
      
      // Check if sync is needed
      final now = DateTime.now();
      if (lastSync == null || now.difference(lastSync) >= _syncInterval) {
        Logger.info('[MusicSyncService] Sync needed - starting sync process...');
        await syncMusicFromSwahiliNotes();
      } else {
        final nextSync = lastSync.add(_syncInterval);
        final timeUntilSync = nextSync.difference(now);
        Logger.debug('[MusicSyncService] Next sync in ${timeUntilSync.inHours} hours');
      }
    } catch (e) {
      Logger.error('[MusicSyncService] Error checking sync', e);
    }
  }
  
  /// Manually trigger sync from Swahili Music Notes
  static Future<SyncResult> syncMusicFromSwahiliNotes({
    bool forceSync = false,
  }) async {
    if (_isSyncing && !forceSync) {
      return const SyncResult(
        success: false,
        message: 'Sync already in progress',
        newSongs: 0,
        updatedSongs: 0,
      );
    }
    
    _isSyncing = true;
    final stopwatch = Stopwatch()..start();
    
    try {
      Logger.info('[MusicSyncService] Starting music sync from SwahiliMusicNotes.com...');

      // Fetch music from SwahiliMusicNotes.com
      final newMusic = await SwahiliMusicScraper.fetchAllMusic();
      Logger.info('[MusicSyncService] Fetched ${newMusic.length} songs from SwahiliMusicNotes.com');
      
      if (newMusic.isEmpty) {
        return const SyncResult(
          success: false,
          message: 'No music found on SwahiliMusicNotes.com',
          newSongs: 0,
          updatedSongs: 0,
        );
      }
      
      // Get existing music from database
      final musicService = MusicService();
      final existingMusic = await musicService.getPublicMusic();
      final existingTitles = existingMusic.map((m) => m.title.toLowerCase().trim()).toSet();
      
      int newSongs = 0;
      int updatedSongs = 0;
      final List<MusicModel> songsToAdd = [];
      final List<MusicModel> songsToUpdate = [];
      
      // Process each fetched song
      for (final song in newMusic) {
        final normalizedTitle = song.title.toLowerCase().trim();
        
        if (existingTitles.contains(normalizedTitle)) {
          // Song exists - check if it needs updating
          final existingSong = existingMusic.firstWhere(
            (m) => m.title.toLowerCase().trim() == normalizedTitle,
          );
          
          if (_shouldUpdateSong(existingSong, song)) {
            songsToUpdate.add(song.copyWith(id: existingSong.id));
            updatedSongs++;
          }
        } else {
          // New song
          songsToAdd.add(song);
          newSongs++;
        }
      }
      
      // Add new songs to database
      for (final song in songsToAdd) {
        try {
          final success = await musicService.addMusic(song);
          if (success) {
            Logger.debug('[MusicSyncService] Added new song: ${song.title}');
          }
        } catch (e) {
          Logger.error('[MusicSyncService] Error adding song ${song.title}', e);
        }
      }

      // Update existing songs
      for (final song in songsToUpdate) {
        try {
          final success = await musicService.updateMusic(song);
          if (success) {
            Logger.debug('[MusicSyncService] Updated song: ${song.title}');
          }
        } catch (e) {
          Logger.error('[MusicSyncService] Error updating song ${song.title}', e);
        }
      }
      
      // Download PDFs for new songs (background task)
      _downloadPdfsInBackground(songsToAdd);
      
      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      stopwatch.stop();
      final duration = stopwatch.elapsed;
      
      final result = SyncResult(
        success: true,
        message: 'Sync completed successfully in ${duration.inSeconds}s',
        newSongs: newSongs,
        updatedSongs: updatedSongs,
        duration: duration,
      );
      
      Logger.info('[MusicSyncService] ${result.message}');
      Logger.info('[MusicSyncService] New songs: $newSongs, Updated: $updatedSongs');

      return result;
    } catch (e) {
      Logger.error('[MusicSyncService] Error during sync', e);
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        newSongs: 0,
        updatedSongs: 0,
      );
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Check if a song needs updating
  static bool _shouldUpdateSong(MusicModel existing, MusicModel fetched) {
    // Update if:
    // - PDF URL changed or was added
    // - Lyrics were added/updated
    // - Music notes were added/updated
    
    final pdfUrlChanged = existing.sheetMusicUrl != fetched.sheetMusicUrl &&
        fetched.sheetMusicUrl?.isNotEmpty == true;
    
    final lyricsAdded = existing.lyrics.isEmpty && fetched.lyrics.isNotEmpty;
    
    final notesAdded = existing.musicNotes.isEmpty && fetched.musicNotes.isNotEmpty;
    
    return pdfUrlChanged || lyricsAdded || notesAdded;
  }
  
  /// Download PDFs in background (non-blocking)
  static void _downloadPdfsInBackground(List<MusicModel> songs) {
    final songsWithPdfs = songs.where((s) => s.sheetMusicUrl?.isNotEmpty == true).toList();
    
    if (songsWithPdfs.isEmpty) return;
    
    Logger.info('[MusicSyncService] Starting background PDF download for ${songsWithPdfs.length} songs');
    
    // Run in background without blocking
    Timer.run(() async {
      for (final song in songsWithPdfs) {
        try {
          final success = await SwahiliMusicScraper.downloadPdf(
            song.sheetMusicUrl!,
            'downloads/${song.id}.pdf',
          );
          
          if (success) {
            Logger.debug('[MusicSyncService] Downloaded PDF for: ${song.title}');
          }
        } catch (e) {
          Logger.error('[MusicSyncService] Error downloading PDF for ${song.title}', e);
        }
        
        // Small delay between downloads
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    });
  }
  
  /// Enable or disable automatic sync
  static Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, enabled);
    
    if (enabled) {
      await initialize();
    } else {
      stopBackgroundSync();
    }
    
    Logger.info('[MusicSyncService] Auto sync ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Get sync status
  static Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? true;
  }
  
  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    return lastSyncString != null ? DateTime.tryParse(lastSyncString) : null;
  }
  
  /// Get sync statistics
  static Future<SyncStats> getSyncStats() async {
    final lastSync = await getLastSyncTime();
    final syncEnabled = await isSyncEnabled();
    
    return SyncStats(
      lastSyncTime: lastSync,
      syncEnabled: syncEnabled,
      isSyncing: _isSyncing,
      nextSyncTime: lastSync?.add(_syncInterval),
    );
  }
  
  /// Force immediate sync
  static Future<SyncResult> forceSyncNow() async {
    Logger.info('[MusicSyncService] Forcing immediate sync...');
    return await syncMusicFromSwahiliNotes(forceSync: true);
  }
  
  /// Clear all sync data (for testing)
  static Future<void> clearSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    Logger.info('[MusicSyncService] Sync data cleared');
  }
}

/// Result of a sync operation
class SyncResult {
  
  const SyncResult({
    required this.success,
    required this.message,
    required this.newSongs,
    required this.updatedSongs,
    this.duration,
  });
  final bool success;
  final String message;
  final int newSongs;
  final int updatedSongs;
  final Duration? duration;
  
  @override
  String toString() {
    return 'SyncResult(success: $success, newSongs: $newSongs, updated: $updatedSongs, message: $message)';
  }
}

/// Sync statistics
class SyncStats {
  
  const SyncStats({
    this.lastSyncTime,
    required this.syncEnabled,
    required this.isSyncing,
    this.nextSyncTime,
  });
  final DateTime? lastSyncTime;
  final bool syncEnabled;
  final bool isSyncing;
  final DateTime? nextSyncTime;
  
  String get statusMessage {
    if (!syncEnabled) return 'Sync disabled';
    if (isSyncing) return 'Syncing now...';
    if (lastSyncTime == null) return 'Never synced';
    
    final now = DateTime.now();
    final timeSince = now.difference(lastSyncTime!);
    
    if (timeSince.inDays > 0) {
      return 'Last sync: ${timeSince.inDays} days ago';
    } else if (timeSince.inHours > 0) {
      return 'Last sync: ${timeSince.inHours} hours ago';
    } else {
      return 'Last sync: ${timeSince.inMinutes} minutes ago';
    }
  }
}