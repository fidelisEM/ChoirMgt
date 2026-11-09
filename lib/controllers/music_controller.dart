import 'package:flutter/foundation.dart';
import '../models/music_model.dart';
import '../services/music_service.dart';
import '../services/music_sync_service.dart';
import '../services/website_cloner_service.dart';
import '../utils/logger.dart';

class MusicController extends ChangeNotifier {
  final MusicService _musicService = MusicService();

  // State variables
  List<MusicModel> _allMusic = [];
  List<MusicModel> _filteredMusic = [];
  List<MusicModel> _featuredMusic = [];
  List<MusicModel> _popularMusic = [];

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isSyncing = false;
  String _searchQuery = '';
  MusicCategory? _selectedCategory;
  String? _selectedLanguage;
  String? _errorMessage;
  SyncStats? _syncStats;

  // Getters
  List<MusicModel> get allMusic => _allMusic;
  List<MusicModel> get filteredMusic => _filteredMusic;
  List<MusicModel> get featuredMusic => _featuredMusic;
  List<MusicModel> get popularMusic => _popularMusic;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isSyncing => _isSyncing;
  String get searchQuery => _searchQuery;
  MusicCategory? get selectedCategory => _selectedCategory;
  String? get selectedLanguage => _selectedLanguage;
  String? get errorMessage => _errorMessage;
  SyncStats? get syncStats => _syncStats;

  bool get hasMusic => _allMusic.isNotEmpty;
  bool get hasFilteredMusic => _filteredMusic.isNotEmpty;

  // Available categories and languages
  List<MusicCategory> get availableCategories => MusicCategory.values;
  List<String> get availableLanguages => _getAvailableLanguages();

  // Load all public music
  Future<void> loadPublicMusic() async {
    await _performAsyncOperation(() async {
      _allMusic = await _musicService.getPublicMusic();
      _filteredMusic = List.from(_allMusic);
      Logger.info('Loaded ${_allMusic.length} public music tracks');
    });
  }

  // Load choir-specific music
  Future<void> loadChoirMusic(String choirId) async {
    await _performAsyncOperation(() async {
      _allMusic = await _musicService.getChoirMusic(choirId);
      _filteredMusic = List.from(_allMusic);
      Logger.info('Loaded ${_allMusic.length} music tracks for choir $choirId');
    });
  }

  // Load featured music
  Future<void> loadFeaturedMusic() async {
    try {
      _featuredMusic = await _musicService.getFeaturedMusic();
      notifyListeners();
      Logger.info('Loaded ${_featuredMusic.length} featured music tracks');
    } catch (e) {
      Logger.error('Error loading featured music: $e');
      _errorMessage = 'Failed to load featured music';
      notifyListeners();
    }
  }

  // Load popular music
  Future<void> loadPopularMusic() async {
    try {
      _popularMusic = await _musicService.getPopularMusic();
      notifyListeners();
      Logger.info('Loaded ${_popularMusic.length} popular music tracks');
    } catch (e) {
      Logger.error('Error loading popular music: $e');
      _errorMessage = 'Failed to load popular music';
      notifyListeners();
    }
  }

  // Search music
  Future<void> searchMusic(String query) async {
    _searchQuery = query;
    _isSearching = true;
    notifyListeners();

    try {
      if (query.isEmpty) {
        _filteredMusic = List.from(_allMusic);
      } else {
        _filteredMusic = await _musicService.searchMusic(query);
      }
      _errorMessage = null;
    } catch (e) {
      Logger.error('Error searching music: $e');
      _errorMessage = 'Search failed. Please try again.';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Filter by category
  Future<void> filterByCategory(MusicCategory? category) async {
    _selectedCategory = category;
    await _performAsyncOperation(() async {
      if (category == null) {
        _filteredMusic = List.from(_allMusic);
      } else {
        _filteredMusic = await _musicService.getMusicByCategory(category);
      }
      Logger.info('Filtered by category: ${category?.toString() ?? 'All'}');
    });
  }

  // Filter by language
  Future<void> filterByLanguage(String? language) async {
    _selectedLanguage = language;
    await _performAsyncOperation(() async {
      if (language == null || language.isEmpty) {
        _filteredMusic = List.from(_allMusic);
      } else {
        _filteredMusic = await _musicService.getMusicByLanguage(language);
      }
      Logger.info('Filtered by language: ${language ?? 'All'}');
    });
  }

  // Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _selectedLanguage = null;
    _searchQuery = '';
    _filteredMusic = List.from(_allMusic);
    _errorMessage = null;
    notifyListeners();
    Logger.info('All filters cleared');
  }

  // Get music by ID
  Future<MusicModel?> getMusicById(String musicId) async {
    try {
      return await _musicService.getMusicById(musicId);
    } catch (e) {
      Logger.error('Error getting music by ID: $e');
      return null;
    }
  }

  // Add new music
  Future<bool> addMusic(MusicModel music) async {
    try {
      final success = await _musicService.addMusic(music);
      if (success) {
        await loadPublicMusic(); // Refresh the list
        Logger.info('Music added successfully: ${music.title}');
      }
      return success;
    } catch (e) {
      Logger.error('Error adding music: $e');
      _errorMessage = 'Failed to add music';
      notifyListeners();
      return false;
    }
  }

  // Update music
  Future<bool> updateMusic(MusicModel music) async {
    try {
      final success = await _musicService.updateMusic(music);
      if (success) {
        await loadPublicMusic(); // Refresh the list
        Logger.info('Music updated successfully: ${music.title}');
      }
      return success;
    } catch (e) {
      Logger.error('Error updating music: $e');
      _errorMessage = 'Failed to update music';
      notifyListeners();
      return false;
    }
  }

  // Delete music
  Future<bool> deleteMusic(String musicId) async {
    try {
      final success = await _musicService.deleteMusic(musicId);
      if (success) {
        await loadPublicMusic(); // Refresh the list
        Logger.info('Music deleted successfully: $musicId');
      }
      return success;
    } catch (e) {
      Logger.error('Error deleting music: $e');
      _errorMessage = 'Failed to delete music';
      notifyListeners();
      return false;
    }
  }

  // Fetch Swahili music from web
  Future<void> fetchSwahiliMusicFromWeb() async {
    await _performAsyncOperation(() async {
      final webMusic = await _musicService.fetchSwahiliMusicFromWeb();
      // Add web music to the existing list
      _allMusic.addAll(webMusic);
      _filteredMusic = List.from(_allMusic);
      Logger.info('Fetched ${webMusic.length} music tracks from web');
    });
  }

  // Sync music from SwahiliMusicNotes.com
  Future<SyncResult> syncFromSwahiliMusicNotes({bool forceSync = false}) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await MusicSyncService.syncMusicFromSwahiliNotes(
        forceSync: forceSync,
      );

      if (result.success) {
        // Refresh the music list after successful sync
        await loadPublicMusic();
        Logger.info(
          'Music sync completed: ${result.newSongs} new, ${result.updatedSongs} updated',
        );
      }

      // Update sync stats
      _syncStats = await MusicSyncService.getSyncStats();

      return result;
    } catch (e) {
      _errorMessage = 'Sync failed: $e';
      Logger.error('Music sync failed: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        newSongs: 0,
        updatedSongs: 0,
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Get sync statistics
  Future<void> loadSyncStats() async {
    try {
      _syncStats = await MusicSyncService.getSyncStats();
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading sync stats: $e');
    }
  }

  // Enable/disable automatic sync
  Future<void> setSyncEnabled(bool enabled) async {
    try {
      await MusicSyncService.setSyncEnabled(enabled);
      await loadSyncStats();
      Logger.info('Auto sync ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _errorMessage = 'Failed to update sync settings';
      Logger.error('Error updating sync settings: $e');
      notifyListeners();
    }
  }

  // Force sync now
  Future<SyncResult> forceSyncNow() async {
    return await syncFromSwahiliMusicNotes(forceSync: true);
  }

  // Clone entire SwahiliMusicNotes.com website
  Future<CloneResult> cloneWebsite({
    bool includeImages = true,
    bool includePDFs = true,
    bool cacheContent = true,
  }) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await WebsiteClonerService.cloneWebsite(
        includeImages: includeImages,
        includePDFs: includePDFs,
        cacheContent: cacheContent,
        onProgress: (message) {
          Logger.info('Clone progress: $message');
        },
      );

      if (result.success) {
        // Refresh the music list after successful clone
        await loadPublicMusic();
        Logger.info(
          'Website clone completed: ${result.songsCloned} songs, ${result.pdfsDownloaded} PDFs',
        );
      }

      return result;
    } catch (e) {
      _errorMessage = 'Website clone failed: $e';
      Logger.error('Website clone failed: $e');
      return CloneResult(
        success: false,
        message: 'Clone failed: $e',
        duration: Duration.zero,
        totalPages: 0,
        songsCloned: 0,
        pdfsDownloaded: 0,
        assetsCache: 0,
        music: [],
        downloadedPDFs: [],
        cachedAssets: {},
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    await _performAsyncOperation(() async {
      await loadPublicMusic();
      await loadFeaturedMusic();
      await loadPopularMusic();
      Logger.info('All music data refreshed');
    });
  }

  // Initialize sample data
  Future<void> initializeSampleData() async {
    await _performAsyncOperation(() async {
      await _musicService.initializeSampleData();
      await loadPublicMusic();
      Logger.info('Sample music data initialized');
    });
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private helper methods
  Future<void> _performAsyncOperation(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
    } catch (e) {
      Logger.error('Async operation failed: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> _getAvailableLanguages() {
    final languages = <String>{};
    for (final music in _allMusic) {
      if (music.language.isNotEmpty) {
        languages.add(music.language);
      }
    }
    return languages.toList()..sort();
  }

  // Get music by difficulty
  List<MusicModel> getMusicByDifficulty(MusicDifficulty difficulty) {
    return _allMusic.where((music) => music.difficulty == difficulty).toList();
  }

  // Get music with audio
  List<MusicModel> getMusicWithAudio() {
    return _allMusic.where((music) => music.hasAudio).toList();
  }

  // Get music with sheet music
  List<MusicModel> getMusicWithSheetMusic() {
    return _allMusic.where((music) => music.hasSheetMusic).toList();
  }

  // Get recently added music
  List<MusicModel> getRecentMusic([int limit = 10]) {
    final sortedMusic = List<MusicModel>.from(_allMusic);
    sortedMusic.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedMusic.take(limit).toList();
  }

  // Statistics
  int get totalMusicCount => _allMusic.length;
  int get swahiliMusicCount =>
      _allMusic.where((m) => m.category == MusicCategory.swahili).length;
  int get englishMusicCount =>
      _allMusic.where((m) => m.category == MusicCategory.english).length;
  int get hymnCount =>
      _allMusic.where((m) => m.category == MusicCategory.hymn).length;

  @override
  void dispose() {
    _musicService.clearCache();
    super.dispose();
  }
}
