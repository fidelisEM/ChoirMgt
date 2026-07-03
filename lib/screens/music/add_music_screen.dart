import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../controllers/music_controller.dart';
import '../../models/music_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_widgets.dart';

class AddMusicScreen extends StatefulWidget { // For editing existing music

  const AddMusicScreen({
    super.key,
    this.music,
  });
  final MusicModel? music;

  @override
  State<AddMusicScreen> createState() => _AddMusicScreenState();
}

class _AddMusicScreenState extends State<AddMusicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _composerController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _musicNotesController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _sheetMusicUrlController = TextEditingController();
  final _languageController = TextEditingController();
  final _durationController = TextEditingController();
  final _sourceWebsiteController = TextEditingController();
  final _tagsController = TextEditingController();

  MusicCategory _selectedCategory = MusicCategory.swahili;
  MusicDifficulty _selectedDifficulty = MusicDifficulty.beginner;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.music != null) {
      _loadExistingMusicData();
    } else {
      _languageController.text = 'Swahili'; // Default language
    }
  }

  void _loadExistingMusicData() {
    final music = widget.music!;
    _titleController.text = music.title;
    _artistController.text = music.artist;
    _composerController.text = music.composer;
    _lyricsController.text = music.lyrics;
    _musicNotesController.text = music.musicNotes;
    _audioUrlController.text = music.audioUrl ?? '';
    _videoUrlController.text = music.videoUrl ?? '';
    _sheetMusicUrlController.text = music.sheetMusicUrl ?? '';
    _languageController.text = music.language;
    _durationController.text = music.duration.toString();
    _sourceWebsiteController.text = music.sourceWebsite ?? '';
    _tagsController.text = music.tags.join(', ');
    _selectedCategory = music.category;
    _selectedDifficulty = music.difficulty;
    _isPublic = music.isPublic;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _composerController.dispose();
    _lyricsController.dispose();
    _musicNotesController.dispose();
    _audioUrlController.dispose();
    _videoUrlController.dispose();
    _sheetMusicUrlController.dispose();
    _languageController.dispose();
    _durationController.dispose();
    _sourceWebsiteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.music != null ? 'Edit Music' : 'Add Music',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.gray800,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveMusic,
              child: Text(
                widget.music != null ? 'Update' : 'Save',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildCategorySection(),
                const SizedBox(height: 24),
                _buildContentSection(),
                const SizedBox(height: 24),
                _buildMediaSection(),
                const SizedBox(height: 24),
                _buildSettingsSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Enter music title',
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _artistController,
            decoration: const InputDecoration(
              labelText: 'Artist',
              hintText: 'Enter artist name',
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter artist name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _composerController,
            decoration: const InputDecoration(
              labelText: 'Composer',
              hintText: 'Enter composer name',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _languageController,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    hintText: 'e.g., Swahili, English',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter language';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    hintText: 'e.g., 240',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category & Difficulty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MusicCategory>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: MusicCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category.toString().split('.').last.toUpperCase(),
                          ),
                        );
                      }).toList(),
                      onChanged: (category) {
                        setState(() {
                          _selectedCategory = category!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Difficulty',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MusicDifficulty>(
                      initialValue: _selectedDifficulty,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: MusicDifficulty.values.map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(
                            difficulty.toString().split('.').last.toUpperCase(),
                          ),
                        );
                      }).toList(),
                      onChanged: (difficulty) {
                        setState(() {
                          _selectedDifficulty = difficulty!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lyrics & Music Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lyricsController,
            decoration: const InputDecoration(
              labelText: 'Lyrics',
              hintText: 'Enter song lyrics...',
            ),
            maxLines: 8,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter lyrics';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _musicNotesController,
            decoration: const InputDecoration(
              labelText: 'Music Notes',
              hintText: 'Enter chord progressions, key signatures, etc...',
            ),
            maxLines: 6,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma-separated)',
              hintText: 'e.g., traditional, praise, worship',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Media Resources',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _audioUrlController,
            decoration: const InputDecoration(
              labelText: 'Audio URL (optional)',
              hintText: 'https://example.com/audio.mp3',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _videoUrlController,
            decoration: const InputDecoration(
              labelText: 'Video URL (optional)',
              hintText: 'https://youtube.com/watch?v=...',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sheetMusicUrlController,
            decoration: const InputDecoration(
              labelText: 'Sheet Music URL (optional)',
              hintText: 'https://example.com/sheet-music.pdf',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sourceWebsiteController,
            decoration: const InputDecoration(
              labelText: 'Source Website (optional)',
              hintText: 'Website where this music was found',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Make Public',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
            subtitle: const Text(
              'Other users will be able to view this music',
              style: TextStyle(
                color: AppColors.gray500,
                fontSize: 12,
              ),
            ),
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _saveMusic() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final music = MusicModel(
        id: widget.music?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        composer: _composerController.text.trim().isEmpty 
            ? _artistController.text.trim() 
            : _composerController.text.trim(),
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        lyrics: _lyricsController.text.trim(),
        musicNotes: _musicNotesController.text.trim(),
        audioUrl: _audioUrlController.text.trim().isEmpty 
            ? null 
            : _audioUrlController.text.trim(),
        videoUrl: _videoUrlController.text.trim().isEmpty 
            ? null 
            : _videoUrlController.text.trim(),
        sheetMusicUrl: _sheetMusicUrlController.text.trim().isEmpty 
            ? null 
            : _sheetMusicUrlController.text.trim(),
        tags: tags,
        language: _languageController.text.trim(),
        duration: int.tryParse(_durationController.text) ?? 0,
        createdAt: widget.music?.createdAt ?? now,
        updatedAt: now,
        isPublic: _isPublic,
        sourceWebsite: _sourceWebsiteController.text.trim().isEmpty 
            ? null 
            : _sourceWebsiteController.text.trim(),
      );

      final musicController = Provider.of<MusicController>(context, listen: false);
      final success = widget.music != null
          ? await musicController.updateMusic(music)
          : await musicController.addMusic(music);

      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          widget.music != null 
              ? 'Music updated successfully' 
              : 'Music added successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          widget.music != null 
              ? 'Failed to update music' 
              : 'Failed to add music',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}