import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/music_model.dart';
import '../utils/logger.dart';
import 'web_music_fetcher.dart';

class MusicService {
  factory MusicService() => _instance;
  MusicService._internal();
  static final MusicService _instance = MusicService._internal();

  final _supabase = Supabase.instance.client;

  // Get all public music
  Future<List<MusicModel>> getPublicMusic() async {
    try {
      final response = await _supabase
          .from('music')
          .select()
          .eq('is_public', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MusicModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Error fetching public music: $e');
      return MusicModelSample.getAllSampleMusic();
    }
  }

  // Get music by choir ID
  Future<List<MusicModel>> getChoirMusic(String choirId) async {
    try {
      final response = await _supabase
          .from('music')
          .select()
          .or('choir_id.eq.$choirId,is_public.eq.true')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MusicModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Error fetching choir music: $e');
      return MusicModelSample.getAllSampleMusic();
    }
  }

  // Get music by category
  Future<List<MusicModel>> getMusicByCategory(MusicCategory category) async {
    try {
      final response = await _supabase
          .from('music')
          .select()
          .eq('category', category.toString().split('.').last)
          .eq('is_public', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MusicModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Error fetching music by category: $e');
      return _filterSampleMusicByCategory(category);
    }
  }

  // Search music by title, artist, or lyrics
  Future<List<MusicModel>> searchMusic(String query) async {
    try {
      if (query.isEmpty) return await getPublicMusic();

      final response = await _supabase
          .from('music')
          .select()
          .or(
            'title.ilike.%$query%,artist.ilike.%$query%,lyrics.ilike.%$query%',
          )
          .eq('is_public', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MusicModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Error searching music: $e');
      return _searchSampleMusic(query);
    }
  }

  // Get music by language
  Future<List<MusicModel>> getMusicByLanguage(String language) async {
    try {
      final response = await _supabase
          .from('music')
          .select()
          .eq('language', language)
          .eq('is_public', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MusicModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Error fetching music by language: $e');
      return _filterSampleMusicByLanguage(language);
    }
  }

  // Add new music
  Future<bool> addMusic(MusicModel music) async {
    try {
      await _supabase.from('music').insert(music.toJson());
      Logger.info('Music added successfully: ${music.title}');
      return true;
    } catch (e) {
      Logger.error('Error adding music: $e');
      return false;
    }
  }

  // Update existing music
  Future<bool> updateMusic(MusicModel music) async {
    try {
      final updatedMusic = music.copyWith(updatedAt: DateTime.now());
      await _supabase
          .from('music')
          .update(updatedMusic.toJson())
          .eq('id', music.id);
      Logger.info('Music updated successfully: ${music.title}');
      return true;
    } catch (e) {
      Logger.error('Error updating music: $e');
      return false;
    }
  }

  // Delete music
  Future<bool> deleteMusic(String musicId) async {
    try {
      await _supabase.from('music').delete().eq('id', musicId);
      Logger.info('Music deleted successfully: $musicId');
      return true;
    } catch (e) {
      Logger.error('Error deleting music: $e');
      return false;
    }
  }

  // Get music by ID
  Future<MusicModel?> getMusicById(String musicId) async {
    try {
      final response = await _supabase
          .from('music')
          .select()
          .eq('id', musicId)
          .single();

      return MusicModel.fromJson(response);
    } catch (e) {
      Logger.error('Error fetching music by ID: $e');
      return null;
    }
  }

  // Fetch music from external Swahili music websites
  Future<List<MusicModel>> fetchSwahiliMusicFromWeb() async {
    try {
      Logger.info('Fetching Swahili music from web sources...');

      // Use the dedicated web fetcher service
      final webFetcher = WebMusicFetcher();
      final webMusic = await webFetcher.fetchSwahiliMusicFromWeb();

      // Add to database if not already present
      for (final music in webMusic) {
        final existing = await getMusicById(music.id);
        if (existing == null) {
          await addMusic(music);
        }
      }

      Logger.info(
        'Successfully fetched and stored ${webMusic.length} songs from web sources',
      );
      return webMusic;
    } catch (e) {
      Logger.error('Error fetching Swahili music from web: $e');
      // Fallback to local sample data
      return MusicModelSample.getSampleSwahiliMusic();
    }
  }

  // Get featured music
  Future<List<MusicModel>> getFeaturedMusic() async {
    try {
      final response = await _supabase
          .from('music')
          .select()
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List)
          .map((json) => MusicModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Error fetching featured music: $e');
      return MusicModelSample.getAllSampleMusic();
    }
  }

  // Get popular music (mock implementation)
  Future<List<MusicModel>> getPopularMusic() async {
    try {
      // In a real implementation, this would be based on view counts, likes, etc.
      final allMusic = await getPublicMusic();
      return allMusic.take(5).toList();
    } catch (e) {
      Logger.error('Error fetching popular music: $e');
      return [];
    }
  }

  // Helper methods for sample data
  List<MusicModel> _filterSampleMusicByCategory(MusicCategory category) {
    return MusicModelSample.getAllSampleMusic()
        .where((music) => music.category == category)
        .toList();
  }

  List<MusicModel> _filterSampleMusicByLanguage(String language) {
    return MusicModelSample.getAllSampleMusic()
        .where(
          (music) => music.language.toLowerCase() == language.toLowerCase(),
        )
        .toList();
  }

  List<MusicModel> _searchSampleMusic(String query) {
    final lowerQuery = query.toLowerCase();
    return MusicModelSample.getAllSampleMusic().where((music) {
      return music.title.toLowerCase().contains(lowerQuery) ||
          music.artist.toLowerCase().contains(lowerQuery) ||
          music.lyrics.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Initialize sample data (for development/testing)
  Future<void> initializeSampleData() async {
    try {
      final existingMusic = await getPublicMusic();
      if (existingMusic.isEmpty) {
        final sampleMusic = MusicModelSample.getAllSampleMusic();
        for (final music in sampleMusic) {
          await addMusic(music);
        }
        Logger.info('Sample music data initialized');
      }
    } catch (e) {
      Logger.error('Error initializing sample data: $e');
    }
  }

  // Clear cache (if implementing caching)
  void clearCache() {
    // Implementation for clearing cached music data
    Logger.info('Music cache cleared');
  }
}
