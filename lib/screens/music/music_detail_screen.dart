import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
import '../../models/music_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/music_notes_viewer.dart';
import '../../widgets/pdf_document_viewer.dart';

class MusicDetailScreen extends StatefulWidget {
  const MusicDetailScreen({super.key, required this.music});
  final MusicModel music;

  @override
  State<MusicDetailScreen> createState() => _MusicDetailScreenState();
}

class _MusicDetailScreenState extends State<MusicDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: Column(
                children: [
                  _buildMusicHeader(),
                  _buildTabBar(),
                  _buildTabBarView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.music.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: _getCategoryGradient(widget.music.category),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareMusic,
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          onPressed: _favoriteMusic,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMusicHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: _getCategoryGradient(widget.music.category),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getCategoryGradient(
                        widget.music.category,
                      ).colors.first.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(widget.music.category),
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.music.artist,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.music.composer,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoChip(
                          widget.music.displayCategory,
                          AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          widget.music.displayDifficulty,
                          _getDifficultyColor(widget.music.difficulty),
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          widget.music.language,
                          AppColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.music.hasAudio) _buildAudioControls(),
          if (widget.music.duration > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.gray500,
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${widget.music.formattedDuration}',
                  style: const TextStyle(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 32),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.skip_next, size: 32),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.gray500,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Lyrics'),
          Tab(text: 'Music Notes'),
          Tab(text: 'Info'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return SizedBox(
      height: 520, // Increased height to prevent overflow
      child: TabBarView(
        controller: _tabController,
        children: [_buildLyricsTab(), _buildNotesTab(), _buildInfoTab()],
      ),
    );
  }

  Widget _buildLyricsTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lyrics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.text_increase, size: 20),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copyToClipboard(widget.music.lyrics),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.music.lyrics.isNotEmpty
                      ? widget.music.lyrics
                      : 'No lyrics available for this song.',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: AppColors.gray700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // PDF Sheet Music Viewer
          if (widget.music.sheetMusicUrl != null &&
              widget.music.sheetMusicUrl!.isNotEmpty)
            Expanded(
              flex: 3,
              child: PdfDocumentViewer(
                music: widget.music,
                showFullScreen: false,
              ),
            ),

          // Spacing between PDF and chord progressions
          if (widget.music.sheetMusicUrl != null &&
              widget.music.sheetMusicUrl!.isNotEmpty &&
              widget.music.musicNotes.isNotEmpty)
            const SizedBox(height: 16),

          // Music Notes/Chord Progressions Viewer
          if (widget.music.musicNotes.isNotEmpty)
            Expanded(flex: 2, child: MusicNotesViewer(music: widget.music)),

          // No content message
          if ((widget.music.sheetMusicUrl == null ||
                  widget.music.sheetMusicUrl!.isEmpty) &&
              widget.music.musicNotes.isEmpty)
            const Expanded(
              child: GlassCard(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 64,
                        color: AppColors.gray400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No music notes available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sheet music PDFs and chord progressions will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildInfoCard('General Information', [
              _buildInfoRow('Title', widget.music.title),
              _buildInfoRow('Artist', widget.music.artist),
              _buildInfoRow('Composer', widget.music.composer),
              _buildInfoRow('Category', widget.music.displayCategory),
              _buildInfoRow('Difficulty', widget.music.displayDifficulty),
              _buildInfoRow('Language', widget.music.language),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Media & Resources', [
              _buildInfoRow(
                'Audio Available',
                widget.music.hasAudio ? 'Yes' : 'No',
                icon: widget.music.hasAudio ? Icons.check_circle : Icons.cancel,
                iconColor: widget.music.hasAudio
                    ? AppColors.success
                    : AppColors.error,
              ),
              _buildInfoRow(
                'Sheet Music',
                widget.music.hasSheetMusic ? 'Available' : 'Not Available',
                icon: widget.music.hasSheetMusic
                    ? Icons.check_circle
                    : Icons.cancel,
                iconColor: widget.music.hasSheetMusic
                    ? AppColors.success
                    : AppColors.error,
              ),
              if (widget.music.sourceWebsite != null)
                _buildInfoRow('Source', widget.music.sourceWebsite!),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Tags & Metadata', [
              if (widget.music.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.music.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                const Text(
                  'No tags available',
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: iconColor ?? AppColors.gray600),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray800,
                    ),
                  ),
                ),
              ],
            ),
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
        return AppColors.primaryGradient;
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

  Color _getDifficultyColor(MusicDifficulty difficulty) {
    switch (difficulty) {
      case MusicDifficulty.beginner:
        return AppColors.success;
      case MusicDifficulty.intermediate:
        return AppColors.warning;
      case MusicDifficulty.advanced:
        return AppColors.error;
    }
  }

  // Event handlers
  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    Get.snackbar(
      _isPlaying ? 'Playing' : 'Paused',
      '${widget.music.title} by ${widget.music.artist}',
      backgroundColor: AppColors.info,
      colorText: Colors.white,
    );
  }

  void _shareMusic() {
    Get.snackbar(
      'Share Music',
      'Sharing: ${widget.music.title} by ${widget.music.artist}',
      backgroundColor: AppColors.info,
      colorText: Colors.white,
    );
  }

  void _favoriteMusic() {
    Get.snackbar(
      'Favorite',
      'Added ${widget.music.title} to favorites',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      'Content copied to clipboard',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        Get.snackbar(
          'Edit',
          'Edit functionality coming soon',
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Music'),
        content: Text(
          'Are you sure you want to delete "${widget.music.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final musicController = Provider.of<MusicController>(
                context,
                listen: false,
              );
              final success = await musicController.deleteMusic(
                widget.music.id,
              );

              if (success) {
                Get.back(); // Go back to music list
                Get.snackbar(
                  'Deleted',
                  'Music deleted successfully',
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
