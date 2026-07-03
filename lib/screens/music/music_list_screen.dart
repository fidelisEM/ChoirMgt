import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
import '../../models/music_model.dart';
import 'add_music_screen.dart';
import 'music_detail_screen.dart';

class MusicListScreen extends StatefulWidget {
  const MusicListScreen({super.key});

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final musicController = Provider.of<MusicController>(context, listen: false);
    await musicController.loadPublicMusic();
    await musicController.loadFeaturedMusic();
    await musicController.loadPopularMusic();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D7D52), // Sea Green from SwahiliMusicNotes.com
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF212528), // Shark color
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SMN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF88C4FF), // Anakiwa blue
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Swahili Music Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<MusicController>(
            builder: (context, musicController, child) {
              return IconButton(
                icon: musicController.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF88C4FF)),
                        ),
                      )
                    : const Icon(Icons.sync, color: Colors.white),
                onPressed: musicController.isSyncing ? null : () => _syncFromSwahiliNotes(),
                tooltip: 'Sync from SwahiliMusicNotes.com',
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'clone_website':
                  _cloneEntireWebsite();
                  break;
                case 'add_music':
                  _showAddMusicScreen();
                  break;
                case 'settings':
                  _showSyncSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clone_website',
                child: ListTile(
                  leading: Icon(Icons.web),
                  title: Text('Clone Website'),
                  subtitle: Text('Mirror SwahiliMusicNotes.com'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'add_music',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Add Music'),
                  subtitle: Text('Create new song'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Sync Settings'),
                  subtitle: Text('Configure auto-sync'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWebsiteHeader(),
          _buildNavigationBar(),
          _buildSearchAndFilters(),
          Expanded(
            child: Consumer<MusicController>(
              builder: (context, musicController, child) {
                if (musicController.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7D52)),
                    ),
                  );
                }

                if (musicController.errorMessage != null) {
                  return _buildErrorState(musicController.errorMessage!);
                }

                final musicList = _getFilteredMusic(musicController);
                
                if (musicList.isEmpty) {
                  return _buildEmptyState('No music found');
                }

                return RefreshIndicator(
                  onRefresh: () => musicController.refreshData(),
                  child: _isGridView 
                    ? _buildMusicGrid(musicList)
                    : _buildMusicList(musicList),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _fetchFromWeb(),
        backgroundColor: const Color(0xFF2D7D52),
        child: const Icon(Icons.cloud_download, color: Colors.white),
      ),
    );
  }

  Widget _buildWebsiteHeader() {
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Home',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2D7D52),
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(' > ', style: TextStyle(color: Color(0xFF212528))),
          const Text(
            'Music Library',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF212528),
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Consumer<MusicController>(
            builder: (context, musicController, child) {
              return Row(
                children: [
                  Text(
                    '${_getFilteredMusic(musicController).length} songs',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: const Color(0xFF2B7CE9),
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    tooltip: _isGridView ? 'List View' : 'Grid View',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    final categories = ['All', 'Swahili', 'English', 'Hymns', 'Traditional', 'Contemporary'];
    
    return Container(
      color: const Color(0xFF2D7D52), // Sea Green
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              _filterByCategory(category);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF2D7D52) : Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search songs, artists, or lyrics...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _syncFromSwahiliNotes(),
            icon: Consumer<MusicController>(
              builder: (context, musicController, child) {
                return musicController.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.sync, size: 18);
              },
            ),
            label: const Text('Sync'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D7D52),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  // Filter helper methods
  List<MusicModel> _getFilteredMusic(MusicController musicController) {
    List<MusicModel> music = musicController.filteredMusic;
    
    if (_selectedCategory != 'All') {
      switch (_selectedCategory) {
        case 'Swahili':
          music = music.where((m) => m.category == MusicCategory.swahili).toList();
          break;
        case 'English':
          music = music.where((m) => m.category == MusicCategory.english).toList();
          break;
        case 'Hymns':
          music = music.where((m) => m.category == MusicCategory.hymn).toList();
          break;
        case 'Traditional':
          music = music.where((m) => m.category == MusicCategory.psalm).toList();
          break;
        case 'Contemporary':
          music = music.where((m) => m.category == MusicCategory.contemporary).toList();
          break;
      }
    }
    
    return music;
  }

  void _filterByCategory(String category) {
    final musicController = Provider.of<MusicController>(context, listen: false);
    
    if (category == 'All') {
      musicController.clearFilters();
    } else {
      MusicCategory? musicCategory;
      switch (category) {
        case 'Swahili':
          musicCategory = MusicCategory.swahili;
          break;
        case 'English':
          musicCategory = MusicCategory.english;
          break;
        case 'Hymns':
          musicCategory = MusicCategory.hymn;
          break;
        case 'Traditional':
          musicCategory = MusicCategory.psalm;
          break;
        case 'Contemporary':
          musicCategory = MusicCategory.contemporary;
          break;
      }
      if (musicCategory != null) {
        musicController.filterByCategory(musicCategory);
      }
    }
  }

  Widget _buildMusicGrid(List<MusicModel> musicList) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 :
                       MediaQuery.of(context).size.width > 800 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: musicList.length,
      itemBuilder: (context, index) {
        final music = musicList[index];
        return _buildWebsiteMusicCard(music);
      },
    );
  }

  Widget _buildMusicList(List<MusicModel> musicList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: musicList.length,
      itemBuilder: (context, index) {
        final music = musicList[index];
        return _buildWebsiteListCard(music);
      },
    );
  }

  Widget _buildWebsiteMusicCard(MusicModel music) {
    return GestureDetector(
      onTap: () => _showMusicDetail(music),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail/Cover
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: _getCategoryGradient(music.category),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getCategoryIcon(music.category),
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        music.displayCategory.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (music.hasSheetMusic)
                    const Positioned(
                      bottom: 8,
                      right: 8,
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      music.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212528),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${music.artist}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF88C4FF).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            music.language,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2D7D52),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (music.hasAudio)
                          const Icon(
                            Icons.play_circle_outline,
                            size: 16,
                            color: Color(0xFF27AE60),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.visibility,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '1.2k',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.star_border,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebsiteListCard(MusicModel music) {
    return GestureDetector(
      onTap: () => _showMusicDetail(music),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: _getCategoryGradient(music.category),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(music.category),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    music.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${music.artist} • ${music.language}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B7CE9).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          music.displayCategory,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2B7CE9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (music.hasSheetMusic)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PDF',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFE74C3C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (music.hasAudio)
                        const Icon(
                          Icons.play_circle_outline,
                          size: 16,
                          color: Color(0xFF27AE60),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  onPressed: () => _downloadMusic(music),
                  color: const Color(0xFF2B7CE9),
                ),
                const Text(
                  '1.2k views',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _downloadMusic(MusicModel music) {
    if (music.hasSheetMusic && music.sheetMusicUrl != null) {
      Get.snackbar(
        'Download Started',
        'Downloading ${music.title} sheet music...',
        backgroundColor: const Color(0xFF27AE60),
        colorText: Colors.white,
        icon: const Icon(Icons.download, color: Colors.white),
      );
    } else {
      Get.snackbar(
        'No PDF Available',
        'Sheet music not available for ${music.title}',
        backgroundColor: const Color(0xFFE74C3C),
        colorText: Colors.white,
      );
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add music or fetch from online sources',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Music',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Gradient _getCategoryGradient(MusicCategory category) {
    switch (category) {
      case MusicCategory.swahili:
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        );
      case MusicCategory.english:
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        );
      case MusicCategory.hymn:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF2B7CE9), Color(0xFF1E5DBC)],
        );
    }
  }

  IconData _getCategoryIcon(MusicCategory category) {
    switch (category) {
      case MusicCategory.swahili:
        return Icons.language;
      case MusicCategory.english:
        return Icons.translate;
      case MusicCategory.hymn:
        return Icons.church;
      case MusicCategory.psalm:
        return Icons.auto_stories;
      default:
        return Icons.music_note;
    }
  }

  // Event handlers
  void _onSearchChanged(String query) {
    final musicController = Provider.of<MusicController>(context, listen: false);
    musicController.searchMusic(query);
  }

  void _showMusicDetail(MusicModel music) {
    Get.to(() => MusicDetailScreen(music: music));
  }

  void _showAddMusicScreen() {
    Get.to(() => const AddMusicScreen());
  }

  void _fetchFromWeb() async {
    final musicController = Provider.of<MusicController>(context, listen: false);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Fetch Music from Web'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will fetch Swahili music and lyrics from online sources including:',
            ),
            SizedBox(height: 12),
            Text(
              '• SwahiliMusicNotes.com\n'
              '• EastAfricanMusic.org\n'
              '• AfricanGospel.net\n'
              '• SwahiliSongs.com',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 12),
            Text(
              'This may take a few moments. Continue?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              // Show loading indicator
              Get.dialog(
                const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Fetching music from web sources...'),
                      ),
                    ],
                  ),
                ),
                barrierDismissible: false,
              );
              
              try {
                await musicController.fetchSwahiliMusicFromWeb();
                Get.back(); // Close loading dialog
                Get.snackbar(
                  'Success',
                  'Successfully fetched music from Swahili websites',
                  backgroundColor: const Color(0xFF27AE60),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              } catch (e) {
                Get.back(); // Close loading dialog
                Get.snackbar(
                  'Error',
                  'Failed to fetch music: ${e.toString()}',
                  backgroundColor: const Color(0xFFE74C3C),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            child: const Text('Fetch Now'),
          ),
        ],
      ),
    );
  }

  void _syncFromSwahiliNotes() async {
    final musicController = Provider.of<MusicController>(context, listen: false);
    
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync, color: Color(0xFF2B7CE9)),
            SizedBox(width: 8),
            Text('Sync Music'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will automatically download the latest Swahili music notes from SwahiliMusicNotes.com including:',
            ),
            const SizedBox(height: 12),
            const Text(
              '• New song PDFs and sheet music\n'
              '• Updated lyrics and chord progressions\n'
              '• Traditional and contemporary hymns\n'
              '• Praise and worship songs',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2B7CE9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2B7CE9).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF2B7CE9)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This process runs automatically every 24 hours, but you can sync manually anytime.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2B7CE9)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Continue with sync?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              
              try {
                final result = await musicController.forceSyncNow();
                
                if (result.success) {
                  Get.snackbar(
                    'Sync Complete',
                    '${result.newSongs} new songs, ${result.updatedSongs} updated',
                    backgroundColor: const Color(0xFF27AE60),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                  );
                } else {
                  Get.snackbar(
                    'Sync Failed',
                    result.message,
                    backgroundColor: const Color(0xFFE74C3C),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                    icon: const Icon(Icons.error, color: Colors.white),
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to sync: ${e.toString()}',
                  backgroundColor: const Color(0xFFE74C3C),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 4),
                );
              }
            },
            icon: const Icon(Icons.sync),
            label: const Text('Sync Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B7CE9),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _cloneEntireWebsite() async {
    final musicController = Provider.of<MusicController>(context, listen: false);
    
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.web, color: Color(0xFF2B7CE9)),
            SizedBox(width: 8),
            Text('Clone Website'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will create a complete mirror of SwahiliMusicNotes.com in your app including:',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2B7CE9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✓ Complete website structure', style: TextStyle(fontSize: 12)),
                  Text('✓ All music pages and categories', style: TextStyle(fontSize: 12)),
                  Text('✓ Sheet music PDF downloads', style: TextStyle(fontSize: 12)),
                  Text('✓ Lyrics and chord progressions', style: TextStyle(fontSize: 12)),
                  Text('✓ Images and styling assets', style: TextStyle(fontSize: 12)),
                  Text('✓ Cached offline access', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF39C12).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Color(0xFFF39C12)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This process may take 5-10 minutes and will use significant bandwidth.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFF39C12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Continue with website cloning?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              
              // Show progress dialog
              Get.dialog(
                const AlertDialog(
                  title: Text('Cloning Website...'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(),
                      SizedBox(height: 16),
                      Text('This may take several minutes...'),
                      SizedBox(height: 8),
                      Text(
                        'Discovering pages, downloading content, and building database.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                barrierDismissible: false,
              );
              
              try {
                final result = await musicController.cloneWebsite(
                  includeImages: true,
                  includePDFs: true,
                  cacheContent: true,
                );
                
                Get.back(); // Close progress dialog
                
                if (result.success) {
                  Get.dialog(
                    AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF27AE60)),
                          SizedBox(width: 8),
                          Text('Clone Complete'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Successfully cloned SwahiliMusicNotes.com!'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📄 Pages processed: ${result.totalPages}'),
                                Text('🎵 Songs cloned: ${result.songsCloned}'),
                                Text('📑 PDFs downloaded: ${result.pdfsDownloaded}'),
                                Text('⚡ Assets cached: ${result.assetsCache}'),
                                Text('⏱️ Time taken: ${result.duration.inMinutes}m ${result.duration.inSeconds % 60}s'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your app now has a complete offline copy of SwahiliMusicNotes.com!',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Get.back(),
                          child: const Text('Awesome!'),
                        ),
                      ],
                    ),
                  );
                } else {
                  Get.snackbar(
                    'Clone Failed',
                    result.message,
                    backgroundColor: const Color(0xFFE74C3C),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 5),
                    icon: const Icon(Icons.error, color: Colors.white),
                  );
                }
              } catch (e) {
                Get.back(); // Close progress dialog
                Get.snackbar(
                  'Error',
                  'Failed to clone website: ${e.toString()}',
                  backgroundColor: const Color(0xFFE74C3C),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 5),
                );
              }
            },
            icon: const Icon(Icons.web),
            label: const Text('Start Clone'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B7CE9),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncSettings() async {
    final musicController = Provider.of<MusicController>(context, listen: false);
    await musicController.loadSyncStats();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Sync Settings'),
        content: Consumer<MusicController>(
          builder: (context, controller, child) {
            final stats = controller.syncStats;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stats != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B7CE9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${stats.statusMessage}'),
                        if (stats.nextSyncTime != null)
                          Text('Next sync: ${_formatDateTime(stats.nextSyncTime!)}'),
                        Text('Auto-sync: ${stats.syncEnabled ? 'Enabled' : 'Disabled'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Configure automatic music sync:'),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Enable Auto-Sync'),
                  subtitle: const Text('Download new music every 24 hours'),
                  value: stats?.syncEnabled ?? true,
                  onChanged: (value) {
                    controller.setSyncEnabled(value);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              musicController.forceSyncNow();
              Get.back();
            },
            child: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return 'in ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minutes';
    } else {
      return 'soon';
    }
  }

}