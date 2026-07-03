import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_model.dart';
import '../services/music_service.dart';
import '../utils/logger.dart';

/// Advanced website cloning service for SwahiliMusicNotes.com
class WebsiteClonerService {
  static const String targetUrl = 'https://www.swahilimusicnotes.com';
  static const String cacheKeyPrefix = 'cloned_content_';
  static const Duration cacheExpiry = Duration(hours: 6);
  
  /// Clone the entire website structure and content
  static Future<CloneResult> cloneWebsite({
    bool includeImages = true,
    bool includePDFs = true,
    bool cacheContent = true,
    Function(String)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    onProgress?.call('Starting website clone...');
    
    try {
      // Step 1: Discover all pages and content
      onProgress?.call('Discovering website structure...');
      final siteMap = await _discoverSiteStructure();
      
      // Step 2: Clone music catalog
      onProgress?.call('Cloning music catalog...');
      final musicResults = await _cloneMusicCatalog(siteMap, onProgress);
      
      // Step 3: Download PDFs if requested
      List<String> downloadedPDFs = [];
      if (includePDFs) {
        onProgress?.call('Downloading PDF documents...');
        downloadedPDFs = await _downloadAllPDFs(musicResults.music, onProgress);
      }
      
      // Step 4: Cache website assets if requested
      Map<String, String> cachedAssets = {};
      if (cacheContent) {
        onProgress?.call('Caching website assets...');
        cachedAssets = await _cacheWebsiteAssets(siteMap, includeImages);
      }
      
      // Step 5: Update database
      onProgress?.call('Updating database...');
      await _updateDatabase(musicResults.music);
      
      stopwatch.stop();
      
      final result = CloneResult(
        success: true,
        message: 'Website cloned successfully',
        duration: stopwatch.elapsed,
        totalPages: siteMap.pages.length,
        songsCloned: musicResults.music.length,
        pdfsDownloaded: downloadedPDFs.length,
        assetsCache: cachedAssets.length,
        music: musicResults.music,
        downloadedPDFs: downloadedPDFs,
        cachedAssets: cachedAssets,
      );
      
      onProgress?.call('Clone complete: ${result.songsCloned} songs, ${result.pdfsDownloaded} PDFs');
      Logger.info('Website clone completed: $result');
      
      return result;
    } catch (e) {
      Logger.error('Website clone failed: $e');
      return CloneResult(
        success: false,
        message: 'Clone failed: $e',
        duration: stopwatch.elapsed,
        totalPages: 0,
        songsCloned: 0,
        pdfsDownloaded: 0,
        assetsCache: 0,
        music: [],
        downloadedPDFs: [],
        cachedAssets: {},
      );
    }
  }
  
  /// Discover the complete site structure
  static Future<SiteMap> _discoverSiteStructure() async {
    try {
      final pages = <WebPage>[];
      final visited = <String>{};
      final toVisit = <String>[targetUrl];
      
      // Common page patterns for SwahiliMusicNotes.com
      final additionalPages = [
        '$targetUrl/songs',
        '$targetUrl/categories/praise-worship',
        '$targetUrl/categories/hymns',
        '$targetUrl/categories/traditional',
        '$targetUrl/categories/contemporary',
        '$targetUrl/search',
        '$targetUrl/latest',
        '$targetUrl/popular',
      ];
      toVisit.addAll(additionalPages);
      
      while (toVisit.isNotEmpty && visited.length < 50) {
        final url = toVisit.removeAt(0);
        if (visited.contains(url)) continue;
        
        try {
          visited.add(url);
          final page = await _scrapePage(url);
          if (page != null) {
            pages.add(page);
            
            // Extract new links to visit
            final newLinks = _extractLinks(page.content, targetUrl);
            for (final link in newLinks) {
              if (!visited.contains(link) && !toVisit.contains(link)) {
                toVisit.add(link);
              }
            }
          }
        } catch (e) {
          Logger.warning('Failed to scrape page $url: $e');
        }
        
        // Rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      return SiteMap(
        baseUrl: targetUrl,
        pages: pages,
        totalPages: pages.length,
        discoveredAt: DateTime.now(),
      );
    } catch (e) {
      Logger.error('Site structure discovery failed: $e');
      return SiteMap(
        baseUrl: targetUrl,
        pages: [],
        totalPages: 0,
        discoveredAt: DateTime.now(),
      );
    }
  }
  
  /// Scrape a single page
  static Future<WebPage?> _scrapePage(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (ChoirApp/1.0) Music Archiver',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return WebPage(
          url: url,
          title: _extractTitle(response.body),
          content: response.body,
          lastModified: _extractLastModified(response.headers),
          contentType: response.headers['content-type'] ?? 'text/html',
          size: response.bodyBytes.length,
        );
      }
    } catch (e) {
      Logger.warning('Failed to scrape $url: $e');
    }
    return null;
  }
  
  /// Clone the entire music catalog
  static Future<MusicCatalogResult> _cloneMusicCatalog(
    SiteMap siteMap, 
    Function(String)? onProgress
  ) async {
    final allMusic = <MusicModel>[];
    final errors = <String>[];
    
    for (int i = 0; i < siteMap.pages.length; i++) {
      final page = siteMap.pages[i];
      onProgress?.call('Processing page ${i + 1}/${siteMap.pages.length}: ${page.title}');
      
      try {
        final songs = await _extractMusicFromPage(page);
        allMusic.addAll(songs);
        
        if (songs.isNotEmpty) {
          Logger.info('Extracted ${songs.length} songs from ${page.url}');
        }
      } catch (e) {
        final error = 'Failed to extract music from ${page.url}: $e';
        errors.add(error);
        Logger.warning(error);
      }
      
      // Rate limiting
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    // Remove duplicates
    final uniqueMusic = _deduplicateMusic(allMusic);
    
    return MusicCatalogResult(
      music: uniqueMusic,
      errors: errors,
      pagesProcessed: siteMap.pages.length,
    );
  }
  
  /// Extract music information from a web page
  static Future<List<MusicModel>> _extractMusicFromPage(WebPage page) async {
    final music = <MusicModel>[];
    final content = page.content;
    
    try {
      // Pattern 1: Look for song cards/containers
      final songPatterns = [
        RegExp(r'<div[^>]*class="[^"]*song[^"]*"[^>]*>(.*?)</div>', dotAll: true),
        RegExp(r'<article[^>]*class="[^"]*song[^"]*"[^>]*>(.*?)</article>', dotAll: true),
        RegExp(r'<li[^>]*class="[^"]*song[^"]*"[^>]*>(.*?)</li>', dotAll: true),
      ];
      
      for (final pattern in songPatterns) {
        final matches = pattern.allMatches(content);
        for (final match in matches) {
          final songHtml = match.group(1) ?? '';
          final song = _parseSongFromHtml(songHtml, page.url);
          if (song != null) {
            music.add(song);
          }
        }
      }
      
      // Pattern 2: Look for direct PDF links
      final pdfPattern = RegExp(r'href="([^"]*\.pdf)"[^>]*>([^<]+)', caseSensitive: true);
      final pdfMatches = pdfPattern.allMatches(content);
      
      for (final match in pdfMatches) {
        final pdfUrl = match.group(1) ?? '';
        final title = match.group(2)?.trim() ?? '';
        
        if (title.isNotEmpty && pdfUrl.isNotEmpty) {
          final song = _createSongFromPdfLink(title, pdfUrl, page.url);
          music.add(song);
        }
      }
      
      // Pattern 3: Look for structured data (JSON-LD)
      final jsonLdPattern = RegExp(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>', dotAll: true);
      final jsonMatches = jsonLdPattern.allMatches(content);
      
      for (final match in jsonMatches) {
        try {
          final jsonText = match.group(1) ?? '';
          final data = json.decode(jsonText);
          final structuredSongs = _extractMusicFromStructuredData(data, page.url);
          music.addAll(structuredSongs);
        } catch (e) {
          // Ignore JSON parsing errors
        }
      }
      
    } catch (e) {
      Logger.warning('Error extracting music from ${page.url}: $e');
    }
    
    return music;
  }
  
  /// Parse song information from HTML fragment
  static MusicModel? _parseSongFromHtml(String html, String pageUrl) {
    try {
      // Extract title
      final titlePattern = RegExp(r'<h[1-6][^>]*>([^<]+)</h[1-6]>');
      final titleMatch = titlePattern.firstMatch(html);
      final title = titleMatch?.group(1)?.trim() ?? '';
      
      if (title.isEmpty) return null;
      
      // Extract artist/composer
      final artistPattern = RegExp(r'(?:by|artist|composer)[:\s]*([^<\n]+)', caseSensitive: true);
      final artistMatch = artistPattern.firstMatch(html);
      final artist = artistMatch?.group(1)?.trim() ?? 'Traditional';
      
      // Extract PDF link
      final pdfPattern = RegExp(r'href="([^"]*\.pdf)"');
      final pdfMatch = pdfPattern.firstMatch(html);
      final pdfUrl = pdfMatch?.group(1);
      
      // Extract category/genre
      final categoryPattern = RegExp(r'(?:category|genre|type)[:\s]*([^<\n]+)', caseSensitive: true);
      final categoryMatch = categoryPattern.firstMatch(html);
      final categoryText = categoryMatch?.group(1)?.trim().toLowerCase() ?? '';
      
      final now = DateTime.now();
      return MusicModel(
        id: 'cloned_${DateTime.now().millisecondsSinceEpoch}',
        title: _cleanText(title),
        artist: _cleanText(artist),
        composer: _cleanText(artist),
        category: _getCategoryFromText(categoryText),
        difficulty: MusicDifficulty.intermediate,
        lyrics: '',
        musicNotes: '',
        language: 'Swahili',
        sheetMusicUrl: pdfUrl?.startsWith('http') == true ? pdfUrl : '$targetUrl/$pdfUrl',
        sourceWebsite: 'swahilimusicnotes.com',
        tags: ['cloned', 'swahili', categoryText].where((t) => t.isNotEmpty).toList(),
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        metadata: {
          'source_page': pageUrl,
          'extraction_method': 'html_parsing',
          'cloned_at': now.toIso8601String(),
        },
      );
    } catch (e) {
      Logger.warning('Error parsing song HTML: $e');
      return null;
    }
  }
  
  /// Download all PDFs from the music collection
  static Future<List<String>> _downloadAllPDFs(
    List<MusicModel> music,
    Function(String)? onProgress,
  ) async {
    final downloaded = <String>[];
    final songsWithPdfs = music.where((s) => s.sheetMusicUrl?.isNotEmpty == true).toList();
    
    for (int i = 0; i < songsWithPdfs.length; i++) {
      final song = songsWithPdfs[i];
      onProgress?.call('Downloading PDF ${i + 1}/${songsWithPdfs.length}: ${song.title}');
      
      try {
        final success = await _downloadPdf(song.sheetMusicUrl!, song.id);
        if (success) {
          downloaded.add(song.id);
          Logger.info('Downloaded PDF for: ${song.title}');
        }
      } catch (e) {
        Logger.warning('Failed to download PDF for ${song.title}: $e');
      }
      
      // Rate limiting to be respectful to the server
      await Future.delayed(const Duration(seconds: 1));
    }
    
    return downloaded;
  }
  
  /// Download and cache a single PDF
  static Future<bool> _downloadPdf(String url, String songId) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'ChoirApp/1.0 PDF Archiver'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // In a real implementation, you would save to local storage
        // For now, we'll cache the PDF data in memory/preferences
        final prefs = await SharedPreferences.getInstance();
        final pdfKey = 'pdf_$songId';
        
        // Store PDF metadata
        await prefs.setString('${pdfKey}_url', url);
        await prefs.setInt('${pdfKey}_size', response.bodyBytes.length);
        await prefs.setString('${pdfKey}_cached_at', DateTime.now().toIso8601String());
        
        Logger.info('Cached PDF for song $songId (${response.bodyBytes.length} bytes)');
        return true;
      }
    } catch (e) {
      Logger.warning('PDF download failed for $url: $e');
    }
    return false;
  }
  
  /// Cache website assets (CSS, JS, images)
  static Future<Map<String, String>> _cacheWebsiteAssets(
    SiteMap siteMap,
    bool includeImages,
  ) async {
    final cached = <String, String>{};
    final assetUrls = <String>[];
    
    // Extract asset URLs from all pages
    for (final page in siteMap.pages) {
      final urls = _extractAssetUrls(page.content, targetUrl, includeImages);
      assetUrls.addAll(urls);
    }
    
    // Remove duplicates
    final uniqueUrls = assetUrls.toSet().toList();
    
    // Download and cache assets
    for (final url in uniqueUrls.take(50)) { // Limit to 50 assets
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'ChoirApp/1.0 Asset Archiver'},
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          // Cache asset content
          final prefs = await SharedPreferences.getInstance();
          final assetKey = 'asset_${url.hashCode}';
          await prefs.setString(assetKey, response.body);
          cached[url] = assetKey;
        }
      } catch (e) {
        Logger.warning('Failed to cache asset $url: $e');
      }
      
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    Logger.info('Cached ${cached.length} website assets');
    return cached;
  }
  
  /// Update the database with cloned music
  static Future<void> _updateDatabase(List<MusicModel> music) async {
    final musicService = MusicService();
    int added = 0;
    
    for (final song in music) {
      try {
        final success = await musicService.addMusic(song);
        if (success) {
          added++;
        }
      } catch (e) {
        Logger.warning('Failed to add song ${song.title} to database: $e');
      }
    }
    
    Logger.info('Added $added/${music.length} songs to database');
  }
  
  /// Helper methods
  static String _extractTitle(String html) {
    final pattern = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: true);
    return pattern.firstMatch(html)?.group(1)?.trim() ?? '';
  }
  
  static DateTime? _extractLastModified(Map<String, String> headers) {
    final lastModified = headers['last-modified'];
    if (lastModified != null) {
      try {
        return DateTime.parse(lastModified);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    return null;
  }
  
  static List<String> _extractLinks(String html, String baseUrl) {
    final links = <String>[];
    final pattern = RegExp(r'href="([^"]+)"');
    final matches = pattern.allMatches(html);
    
    for (final match in matches) {
      final link = match.group(1) ?? '';
      if (link.startsWith('/')) {
        links.add('$baseUrl$link');
      } else if (link.startsWith(baseUrl)) {
        links.add(link);
      }
    }
    
    return links;
  }
  
  static List<String> _extractAssetUrls(String html, String baseUrl, bool includeImages) {
    final assets = <String>[];
    
    // CSS files
    final cssPattern = RegExp(r'href="([^"]+\.css)"');
    assets.addAll(_extractUrls(html, cssPattern, baseUrl));
    
    // JS files
    final jsPattern = RegExp(r'src="([^"]+\.js)"');
    assets.addAll(_extractUrls(html, jsPattern, baseUrl));
    
    // Images
    if (includeImages) {
      final imgPattern = RegExp(r'src="([^"]+\.(jpg|jpeg|png|gif|webp))"');
      assets.addAll(_extractUrls(html, imgPattern, baseUrl));
    }
    
    return assets;
  }
  
  static List<String> _extractUrls(String html, RegExp pattern, String baseUrl) {
    final urls = <String>[];
    final matches = pattern.allMatches(html);
    
    for (final match in matches) {
      final url = match.group(1) ?? '';
      if (url.startsWith('/')) {
        urls.add('$baseUrl$url');
      } else if (url.startsWith('http')) {
        urls.add(url);
      }
    }
    
    return urls;
  }
  
  static List<MusicModel> _extractMusicFromStructuredData(dynamic data, String pageUrl) {
    // Implementation for extracting music from JSON-LD structured data
    // This would parse schema.org MusicRecording or similar structures
    return [];
  }
  
  static MusicModel _createSongFromPdfLink(String title, String pdfUrl, String pageUrl) {
    final now = DateTime.now();
    return MusicModel(
      id: 'pdf_${DateTime.now().millisecondsSinceEpoch}',
      title: _cleanText(title),
      artist: 'Traditional',
      composer: 'Various',
      category: MusicCategory.swahili,
      difficulty: MusicDifficulty.intermediate,
      lyrics: '',
      musicNotes: '',
      language: 'Swahili',
      sheetMusicUrl: pdfUrl.startsWith('http') ? pdfUrl : '$targetUrl/$pdfUrl',
      sourceWebsite: 'swahilimusicnotes.com',
      tags: ['pdf', 'swahili', 'cloned'],
      createdAt: now,
      updatedAt: now,
      isPublic: true,
      metadata: {
        'source_page': pageUrl,
        'extraction_method': 'pdf_link',
        'cloned_at': now.toIso8601String(),
      },
    );
  }
  
  static List<MusicModel> _deduplicateMusic(List<MusicModel> music) {
    final seen = <String>{};
    final unique = <MusicModel>[];
    
    for (final song in music) {
      final key = '${song.title.toLowerCase()}_${song.artist.toLowerCase()}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(song);
      }
    }
    
    return unique;
  }
  
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }
  
  static MusicCategory _getCategoryFromText(String text) {
    switch (text.toLowerCase()) {
      case 'hymns':
      case 'hymn':
        return MusicCategory.hymn;
      case 'traditional':
        return MusicCategory.traditional;
      case 'contemporary':
      case 'modern':
        return MusicCategory.contemporary;
      case 'psalm':
      case 'psalms':
        return MusicCategory.psalm;
      default:
        return MusicCategory.swahili;
    }
  }
}

/// Result of website cloning operation
class CloneResult {

  const CloneResult({
    required this.success,
    required this.message,
    required this.duration,
    required this.totalPages,
    required this.songsCloned,
    required this.pdfsDownloaded,
    required this.assetsCache,
    required this.music,
    required this.downloadedPDFs,
    required this.cachedAssets,
  });
  final bool success;
  final String message;
  final Duration duration;
  final int totalPages;
  final int songsCloned;
  final int pdfsDownloaded;
  final int assetsCache;
  final List<MusicModel> music;
  final List<String> downloadedPDFs;
  final Map<String, String> cachedAssets;

  @override
  String toString() {
    return 'CloneResult(success: $success, pages: $totalPages, songs: $songsCloned, PDFs: $pdfsDownloaded)';
  }
}

/// Website structure map
class SiteMap {

  const SiteMap({
    required this.baseUrl,
    required this.pages,
    required this.totalPages,
    required this.discoveredAt,
  });
  final String baseUrl;
  final List<WebPage> pages;
  final int totalPages;
  final DateTime discoveredAt;
}

/// Individual web page data
class WebPage {

  const WebPage({
    required this.url,
    required this.title,
    required this.content,
    this.lastModified,
    required this.contentType,
    required this.size,
  });
  final String url;
  final String title;
  final String content;
  final DateTime? lastModified;
  final String contentType;
  final int size;
}

/// Music catalog extraction result
class MusicCatalogResult {

  const MusicCatalogResult({
    required this.music,
    required this.errors,
    required this.pagesProcessed,
  });
  final List<MusicModel> music;
  final List<String> errors;
  final int pagesProcessed;
}