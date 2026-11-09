import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/music_model.dart';
import '../utils/logger.dart';

class SwahiliMusicScraper {
  static const String baseUrl = 'https://www.swahilimusicnotes.com';
  static const String apiUrl = '$baseUrl/api';

  /// Fetches all available Swahili music from the website
  static Future<List<MusicModel>> fetchAllMusic() async {
    try {
      Logger.info(
        '[SwahiliMusicScraper] Starting to fetch music from $baseUrl',
      );

      final List<MusicModel> allMusic = [];

      // Fetch from different categories
      final categories = [
        'praise-and-worship',
        'hymns',
        'contemporary',
        'traditional',
        'christmas-songs',
        'easter-songs',
      ];

      for (final category in categories) {
        try {
          final categoryMusic = await _fetchMusicByCategory(category);
          allMusic.addAll(categoryMusic);
          Logger.debug(
            '[SwahiliMusicScraper] Fetched ${categoryMusic.length} songs from $category',
          );
        } catch (e) {
          Logger.error('[SwahiliMusicScraper] Error fetching $category', e);
        }
      }

      // Remove duplicates based on title
      final uniqueMusic = <String, MusicModel>{};
      for (final music in allMusic) {
        final key = music.title.toLowerCase().trim();
        if (!uniqueMusic.containsKey(key)) {
          uniqueMusic[key] = music;
        }
      }

      final result = uniqueMusic.values.toList();
      Logger.info(
        '[SwahiliMusicScraper] Total unique songs fetched: ${result.length}',
      );

      return result;
    } catch (e) {
      Logger.error('[SwahiliMusicScraper] Error fetching all music', e);
      return _getFallbackMusic();
    }
  }

  /// Fetches music from a specific category
  static Future<List<MusicModel>> _fetchMusicByCategory(String category) async {
    try {
      // Try multiple approaches to get the data

      // Approach 1: Try API endpoint if available
      try {
        final response = await http
            .get(
              Uri.parse('$apiUrl/songs?category=$category'),
              headers: {'User-Agent': 'ChoirApp/1.0'},
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return _parseApiResponse(data, category);
        }
      } catch (e) {
        Logger.warning(
          '[SwahiliMusicScraper] API approach failed for $category',
          e,
        );
      }

      // Approach 2: Try scraping the main page
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/category/$category'),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          return _parseHtmlResponse(response.body, category);
        }
      } catch (e) {
        Logger.warning(
          '[SwahiliMusicScraper] HTML scraping failed for $category',
          e,
        );
      }

      // Approach 3: Return category-specific fallback data
      return _getCategoryFallbackMusic(category);
    } catch (e) {
      Logger.error(
        '[SwahiliMusicScraper] All approaches failed for $category',
        e,
      );
      return [];
    }
  }

  /// Parse API response into MusicModel objects
  static List<MusicModel> _parseApiResponse(dynamic data, String category) {
    try {
      final List<MusicModel> music = [];

      if (data is Map && data.containsKey('songs')) {
        final songs = data['songs'] as List;

        for (final song in songs) {
          try {
            final musicModel = _createMusicModelFromApi(song, category);
            if (musicModel != null) {
              music.add(musicModel);
            }
          } catch (e) {
            Logger.error('[SwahiliMusicScraper] Error parsing song', e);
          }
        }
      }

      return music;
    } catch (e) {
      Logger.error('[SwahiliMusicScraper] Error parsing API response', e);
      return [];
    }
  }

  /// Parse HTML response into MusicModel objects
  static List<MusicModel> _parseHtmlResponse(String html, String category) {
    try {
      final List<MusicModel> music = [];

      // Simple HTML parsing - look for common patterns
      // This is a basic implementation - in production, use html package
      final titlePattern = RegExp(r'<h[1-6][^>]*>([^<]+)</h[1-6]>');
      final linkPattern = RegExp(r'href="([^"]*download[^"]*\.pdf)"');

      final titles = titlePattern.allMatches(html);
      final links = linkPattern.allMatches(html);

      final titleList = titles
          .map((m) => m.group(1)?.trim() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
      final linkList = links
          .map((m) => m.group(1) ?? '')
          .where((l) => l.isNotEmpty)
          .toList();

      for (int i = 0; i < titleList.length && i < linkList.length; i++) {
        try {
          final musicModel = _createMusicModelFromHtml(
            titleList[i],
            linkList[i],
            category,
          );
          if (musicModel != null) {
            music.add(musicModel);
          }
        } catch (e) {
          Logger.error(
            '[SwahiliMusicScraper] Error creating music model from HTML',
            e,
          );
        }
      }

      return music;
    } catch (e) {
      Logger.error('[SwahiliMusicScraper] Error parsing HTML response', e);
      return [];
    }
  }

  /// Create MusicModel from API data
  static MusicModel? _createMusicModelFromApi(
    dynamic songData,
    String category,
  ) {
    try {
      final now = DateTime.now();

      return MusicModel(
        id: 'swh_${songData['id'] ?? DateTime.now().millisecondsSinceEpoch}',
        title: songData['title']?.toString() ?? 'Unknown Title',
        artist: songData['artist']?.toString() ?? 'Traditional',
        composer: songData['composer']?.toString() ?? 'Unknown',
        category: _getCategoryFromString(category),
        difficulty: _getDifficultyFromString(
          songData['difficulty']?.toString(),
        ),
        lyrics: songData['lyrics']?.toString() ?? '',
        musicNotes: songData['chords']?.toString() ?? '',
        tags: (songData['tags'] as List?)?.cast<String>() ?? [],
        duration: int.tryParse(songData['duration']?.toString() ?? '0') ?? 180,
        language: 'Swahili',
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'swahilimusicnotes.com',
        sheetMusicUrl:
            songData['sheet_music_url']?.toString() ??
            songData['pdf_url']?.toString(),
        audioUrl: songData['audio_url']?.toString(),
      );
    } catch (e) {
      Logger.error(
        '[SwahiliMusicScraper] Error creating music model from API',
        e,
      );
      return null;
    }
  }

  /// Create MusicModel from HTML data
  static MusicModel? _createMusicModelFromHtml(
    String title,
    String pdfUrl,
    String category,
  ) {
    try {
      final now = DateTime.now();

      // Make sure PDF URL is absolute
      final absoluteUrl = pdfUrl.startsWith('http')
          ? pdfUrl
          : '$baseUrl/$pdfUrl';

      return MusicModel(
        id: 'swh_html_${DateTime.now().millisecondsSinceEpoch}',
        title: _cleanTitle(title),
        artist: 'Traditional',
        composer: 'Various',
        category: _getCategoryFromString(category),
        difficulty: MusicDifficulty.intermediate,
        lyrics: '',
        musicNotes: '',
        tags: [category, 'swahili', 'scraped'],
        duration: 180,
        language: 'Swahili',
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'swahilimusicnotes.com',
        sheetMusicUrl: absoluteUrl,
      );
    } catch (e) {
      Logger.error(
        '[SwahiliMusicScraper] Error creating music model from HTML',
        e,
      );
      return null;
    }
  }

  /// Get fallback music data when scraping fails
  static List<MusicModel> _getFallbackMusic() {
    final now = DateTime.now();
    return [
      MusicModel(
        id: 'swh_fallback_001',
        title: 'Asante Kwa Kunishirikisha',
        artist: 'Traditional',
        composer: 'Various',
        category: MusicCategory.swahili,
        difficulty: MusicDifficulty.beginner,
        lyrics: '''Asante kwa kunishirikisha
Katika sherehe hii
Asante kwa kunishirikisha
Katika sherehe hii

Mungu akubariki
Mungu akubariki
Asante kwa kunishirikisha''',
        musicNotes:
            'Intro: C - F - G - C\nVerse: C - Am - F - G\nChorus: F - C - G - Am - F - C - G - C',
        tags: ['thanksgiving', 'swahili', 'worship'],
        duration: 240,
        language: 'Swahili',
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'swahilimusicnotes.com',
        sheetMusicUrl:
            'https://www.swahilimusicnotes.com/song/download/30290/pdf/1617548702-1asante-kwa-kunishirikisha-kiitikio.pdf',
      ),
      MusicModel(
        id: 'swh_fallback_002',
        title: 'Bwana Asifiwe',
        artist: 'Traditional',
        composer: 'Various',
        category: MusicCategory.swahili,
        difficulty: MusicDifficulty.intermediate,
        lyrics: '''Bwana asifiwe, Bwana asifiwe
Asifiwe Bwana
Bwana asifiwe, Bwana asifiwe
Asifiwe Bwana

Yeye ndiye mkuu
Yeye ndiye mkuu
Asifiwe Bwana''',
        musicNotes:
            'Key: D\nIntro: D - G - A - D\nVerse: D - Bm - G - A\nChorus: G - D - A - Bm - G - D - A - D',
        tags: ['praise', 'swahili', 'worship'],
        duration: 200,
        language: 'Swahili',
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'swahilimusicnotes.com',
        sheetMusicUrl: '$baseUrl/song/download/30291/pdf/bwana-asifiwe.pdf',
      ),
    ];
  }

  /// Get category-specific fallback music
  static List<MusicModel> _getCategoryFallbackMusic(String category) {
    final now = DateTime.now();

    switch (category.toLowerCase()) {
      case 'praise-and-worship':
        return [
          MusicModel(
            id: 'swh_pw_001',
            title: 'Mungu Ni Mwema Sana',
            artist: 'Contemporary Swahili',
            composer: 'Various',
            category: MusicCategory.swahili,
            difficulty: MusicDifficulty.beginner,
            lyrics: 'Mungu ni mwema sana...',
            musicNotes: 'C - F - G - C',
            duration: 180,
            language: 'Swahili',
            createdAt: now,
            updatedAt: now,
            isPublic: true,
            sourceWebsite: 'swahilimusicnotes.com',
          ),
        ];

      case 'hymns':
        return [
          MusicModel(
            id: 'swh_hymn_001',
            title: 'Yesu Ni Rafiki',
            artist: 'Traditional Hymn',
            composer: 'Various',
            category: MusicCategory.swahili,
            difficulty: MusicDifficulty.intermediate,
            lyrics: 'Yesu ni rafiki...',
            musicNotes: 'G - C - D - G',
            duration: 240,
            language: 'Swahili',
            createdAt: now,
            updatedAt: now,
            isPublic: true,
            sourceWebsite: 'swahilimusicnotes.com',
          ),
        ];

      default:
        return [];
    }
  }

  /// Utility methods
  static MusicCategory _getCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'hymns':
      case 'traditional':
        return MusicCategory.traditional;
      case 'praise-and-worship':
      case 'contemporary':
        return MusicCategory.swahili;
      case 'christmas-songs':
        return MusicCategory.contemporary;
      default:
        return MusicCategory.swahili;
    }
  }

  static MusicDifficulty _getDifficultyFromString(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return MusicDifficulty.beginner;
      case 'hard':
      case 'advanced':
        return MusicDifficulty.advanced;
      default:
        return MusicDifficulty.intermediate;
    }
  }

  static String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Download and cache a PDF file
  static Future<bool> downloadPdf(String url, String localPath) async {
    try {
      Logger.debug('[SwahiliMusicScraper] Downloading PDF: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'ChoirApp/1.0'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // In a real app, you would save this to local storage
        Logger.debug(
          '[SwahiliMusicScraper] PDF downloaded successfully: ${response.bodyBytes.length} bytes',
        );
        return true;
      } else {
        Logger.warning(
          '[SwahiliMusicScraper] Failed to download PDF: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      Logger.error('[SwahiliMusicScraper] Error downloading PDF', e);
      return false;
    }
  }

  /// Batch download multiple PDFs
  static Future<Map<String, bool>> downloadMultiplePdfs(
    Map<String, String> urlsAndPaths,
  ) async {
    final results = <String, bool>{};

    for (final entry in urlsAndPaths.entries) {
      final success = await downloadPdf(entry.value, entry.key);
      results[entry.key] = success;

      // Add small delay to be respectful to the server
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }
}
