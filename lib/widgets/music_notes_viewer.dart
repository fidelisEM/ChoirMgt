import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/music_model.dart';
import '../theme/app_colors.dart';

class MusicNotesViewer extends StatefulWidget {
  const MusicNotesViewer({
    super.key,
    required this.music,
    this.showFullScreen = false,
  });
  final MusicModel music;
  final bool showFullScreen;

  @override
  State<MusicNotesViewer> createState() => _MusicNotesViewerState();
}

class _MusicNotesViewerState extends State<MusicNotesViewer> {
  double _fontSize = 14.0;
  bool _isFullScreen = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isFullScreen = widget.showFullScreen;
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.music.title} - Music Notes'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.text_decrease),
              onPressed: _decreaseFontSize,
            ),
            IconButton(
              icon: const Icon(Icons.text_increase),
              onPressed: _increaseFontSize,
            ),
            IconButton(icon: const Icon(Icons.copy), onPressed: _copyNotes),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadNotes,
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('Print'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _buildNotesContent(),
      );
    } else {
      return _buildNotesContent();
    }
  }

  Widget _buildNotesContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        children: [
          if (!_isFullScreen) _buildHeader(),
          Expanded(child: _buildNotesDisplay()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.music.title} - Music Notes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'by ${widget.music.artist}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: _openFullScreen,
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: _copyNotes,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesDisplay() {
    final notesData = _parseNotesData(widget.music.musicNotes);

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Song Information
            _buildSongInfo(),
            const SizedBox(height: 24),

            // Key Signature and Time Info
            if (notesData.key.isNotEmpty || notesData.tempo.isNotEmpty)
              _buildKeyInfo(notesData),

            // Chord Progressions
            if (notesData.sections.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildChordProgressions(notesData),
            ],

            // Additional Notes
            if (notesData.additionalNotes.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildAdditionalNotes(notesData.additionalNotes),
            ],

            // Sheet Music Link
            if (widget.music.hasSheetMusic) ...[
              const SizedBox(height: 24),
              _buildSheetMusicSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Song Information',
                  style: TextStyle(
                    fontSize: _fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Title:', widget.music.title),
            _buildInfoRow('Artist:', widget.music.artist),
            _buildInfoRow('Composer:', widget.music.composer),
            _buildInfoRow('Category:', widget.music.displayCategory),
            _buildInfoRow('Difficulty:', widget.music.displayDifficulty),
            _buildInfoRow('Language:', widget.music.language),
            if (widget.music.duration > 0)
              _buildInfoRow('Duration:', widget.music.formattedDuration),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: _fontSize, color: AppColors.gray800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInfo(NotesData notesData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'Key & Timing Information',
                  style: TextStyle(
                    fontSize: _fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (notesData.key.isNotEmpty)
                  Expanded(child: _buildKeySignature(notesData.key)),
                if (notesData.tempo.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Expanded(child: _buildTempoInfo(notesData.tempo)),
                ],
              ],
            ),
            if (notesData.timeSignature.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTimeSignature(notesData.timeSignature),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeySignature(String key) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Key',
            style: TextStyle(
              fontSize: _fontSize - 2,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            key,
            style: TextStyle(
              fontSize: _fontSize + 4,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempoInfo(String tempo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Tempo',
            style: TextStyle(
              fontSize: _fontSize - 2,
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tempo,
            style: TextStyle(
              fontSize: _fontSize + 2,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSignature(String timeSignature) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Time Signature: ',
            style: TextStyle(
              fontSize: _fontSize,
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            timeSignature,
            style: TextStyle(
              fontSize: _fontSize + 2,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChordProgressions(NotesData notesData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.piano, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Chord Progressions',
                  style: TextStyle(
                    fontSize: _fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...notesData.sections.map(
              (section) => _buildChordSection(section.name, section.chords),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChordSection(String sectionName, List<String> chords) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sectionName,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chords.map((chord) => _buildChordBadge(chord)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChordBadge(String chord) {
    // Handle chord modifiers and extensions
    final isMinor =
        chord.toLowerCase().contains('m') &&
        !chord.toLowerCase().contains('maj');
    final isSeventeenth = chord.contains('7');
    final isMajorSeventh = chord.toLowerCase().contains('maj7');

    Color bgColor = AppColors.info;
    if (isMinor) bgColor = AppColors.warning;
    if (isSeventeenth) bgColor = AppColors.secondary;
    if (isMajorSeventh) bgColor = AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        chord,
        style: TextStyle(
          fontSize: _fontSize + 2,
          fontWeight: FontWeight.bold,
          color: bgColor,
          fontFamily: 'Courier',
        ),
      ),
    );
  }

  Widget _buildAdditionalNotes(String notes) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, color: AppColors.gray600),
                const SizedBox(width: 8),
                Text(
                  'Additional Notes',
                  style: TextStyle(
                    fontSize: _fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: _fontSize,
                  color: AppColors.gray700,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetMusicSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.library_music, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Sheet Music',
                  style: TextStyle(
                    fontSize: _fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sheet music available for download',
                    style: TextStyle(
                      fontSize: _fontSize,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _downloadSheetMusic,
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  NotesData _parseNotesData(String notes) {
    final lines = notes.split('\n');
    String key = '';
    String tempo = '';
    String timeSignature = '';
    final List<ChordSection> sections = [];
    String additionalNotes = '';

    String currentSection = '';
    final List<String> currentChords = [];
    bool inAdditionalNotes = false;

    for (String line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.toLowerCase().startsWith('key:')) {
        key = trimmed.substring(4).trim();
      } else if (trimmed.toLowerCase().startsWith('tempo:')) {
        tempo = trimmed.substring(6).trim();
      } else if (trimmed.toLowerCase().startsWith('time signature:')) {
        timeSignature = trimmed.substring(15).trim();
      } else if (trimmed.endsWith(':') && !trimmed.contains('-')) {
        // Section header
        if (currentSection.isNotEmpty && currentChords.isNotEmpty) {
          sections.add(ChordSection(currentSection, List.from(currentChords)));
        }
        currentSection = trimmed.substring(0, trimmed.length - 1);
        currentChords.clear();
        inAdditionalNotes = false;
      } else if (trimmed.contains('-') && !inAdditionalNotes) {
        // Chord progression line
        final chords = trimmed
            .split('-')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();
        currentChords.addAll(chords);
      } else {
        // Additional notes
        if (trimmed.toLowerCase().contains('arrangement') ||
            trimmed.toLowerCase().contains('features') ||
            trimmed.toLowerCase().contains('note') ||
            trimmed.toLowerCase().contains('recommended')) {
          inAdditionalNotes = true;
        }
        if (inAdditionalNotes) {
          additionalNotes += (additionalNotes.isEmpty ? '' : '\n') + trimmed;
        }
      }
    }

    // Add last section
    if (currentSection.isNotEmpty && currentChords.isNotEmpty) {
      sections.add(ChordSection(currentSection, currentChords));
    }

    return NotesData(
      key: key,
      tempo: tempo,
      timeSignature: timeSignature,
      sections: sections,
      additionalNotes: additionalNotes,
    );
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + 2).clamp(12.0, 24.0);
    });
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - 2).clamp(12.0, 24.0);
    });
  }

  void _openFullScreen() {
    Get.to(() => MusicNotesViewer(music: widget.music, showFullScreen: true));
  }

  void _copyNotes() {
    Clipboard.setData(ClipboardData(text: widget.music.musicNotes));
    Get.snackbar(
      'Copied',
      'Music notes copied to clipboard',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  void _downloadNotes() {
    Get.snackbar(
      'Download',
      'Music notes download feature coming soon',
      backgroundColor: AppColors.info,
      colorText: Colors.white,
    );
  }

  void _downloadSheetMusic() {
    if (widget.music.sheetMusicUrl != null) {
      Get.snackbar(
        'Opening Sheet Music',
        'Opening PDF sheet music...',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
      // In real implementation, open URL or download file
    } else {
      Get.snackbar(
        'No Sheet Music',
        'No sheet music URL available for this song',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'print':
        Get.snackbar(
          'Print',
          'Print functionality coming soon',
          backgroundColor: AppColors.info,
          colorText: Colors.white,
        );
        break;
      case 'share':
        Get.snackbar(
          'Share',
          'Share functionality coming soon',
          backgroundColor: AppColors.info,
          colorText: Colors.white,
        );
        break;
    }
  }
}

class NotesData {
  NotesData({
    required this.key,
    required this.tempo,
    required this.timeSignature,
    required this.sections,
    required this.additionalNotes,
  });
  final String key;
  final String tempo;
  final String timeSignature;
  final List<ChordSection> sections;
  final String additionalNotes;
}

class ChordSection {
  ChordSection(this.name, this.chords);
  final String name;
  final List<String> chords;
}
