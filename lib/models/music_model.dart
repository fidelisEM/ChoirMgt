enum MusicCategory {
  swahili,
  english,
  latin,
  traditional,
  contemporary,
  hymn,
  psalm,
  other
}

enum MusicDifficulty {
  beginner,
  intermediate,
  advanced
}

class MusicModel {

  const MusicModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.composer,
    required this.category,
    required this.difficulty,
    required this.lyrics,
    required this.musicNotes,
    this.audioUrl,
    this.videoUrl,
    this.sheetMusicUrl,
    this.tags = const [],
    required this.language,
    this.duration = 0,
    this.choirId,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = true,
    this.sourceWebsite,
    this.metadata,
  });

  factory MusicModel.fromJson(Map<String, dynamic> json) {
    return MusicModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      composer: json['composer'] ?? '',
      category: MusicCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => MusicCategory.other,
      ),
      difficulty: MusicDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty'],
        orElse: () => MusicDifficulty.beginner,
      ),
      lyrics: json['lyrics'] ?? '',
      musicNotes: json['musicNotes'] ?? '',
      audioUrl: json['audioUrl'],
      videoUrl: json['videoUrl'],
      sheetMusicUrl: json['sheetMusicUrl'],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      language: json['language'] ?? '',
      duration: json['duration'] ?? 0,
      choirId: json['choirId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isPublic: json['isPublic'] ?? true,
      sourceWebsite: json['sourceWebsite'],
      metadata: json['metadata']?.cast<String, dynamic>(),
    );
  }
  final String id;
  final String title;
  final String artist;
  final String composer;
  final MusicCategory category;
  final MusicDifficulty difficulty;
  final String lyrics;
  final String musicNotes;
  final String? audioUrl;
  final String? videoUrl;
  final String? sheetMusicUrl;
  final List<String> tags;
  final String language;
  final int duration; // in seconds
  final String? choirId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final String? sourceWebsite;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'composer': composer,
      'category': category.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'lyrics': lyrics,
      'musicNotes': musicNotes,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'sheetMusicUrl': sheetMusicUrl,
      'tags': tags,
      'language': language,
      'duration': duration,
      'choirId': choirId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPublic': isPublic,
      'sourceWebsite': sourceWebsite,
      'metadata': metadata,
    };
  }

  MusicModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? composer,
    MusicCategory? category,
    MusicDifficulty? difficulty,
    String? lyrics,
    String? musicNotes,
    String? audioUrl,
    String? videoUrl,
    String? sheetMusicUrl,
    List<String>? tags,
    String? language,
    int? duration,
    String? choirId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    String? sourceWebsite,
    Map<String, dynamic>? metadata,
  }) {
    return MusicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      composer: composer ?? this.composer,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      lyrics: lyrics ?? this.lyrics,
      musicNotes: musicNotes ?? this.musicNotes,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      sheetMusicUrl: sheetMusicUrl ?? this.sheetMusicUrl,
      tags: tags ?? this.tags,
      language: language ?? this.language,
      duration: duration ?? this.duration,
      choirId: choirId ?? this.choirId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      sourceWebsite: sourceWebsite ?? this.sourceWebsite,
      metadata: metadata ?? this.metadata,
    );
  }

  String get displayDifficulty {
    switch (difficulty) {
      case MusicDifficulty.beginner:
        return 'Beginner';
      case MusicDifficulty.intermediate:
        return 'Intermediate';
      case MusicDifficulty.advanced:
        return 'Advanced';
    }
  }

  String get displayCategory {
    switch (category) {
      case MusicCategory.swahili:
        return 'Swahili';
      case MusicCategory.english:
        return 'English';
      case MusicCategory.latin:
        return 'Latin';
      case MusicCategory.traditional:
        return 'Traditional';
      case MusicCategory.contemporary:
        return 'Contemporary';
      case MusicCategory.hymn:
        return 'Hymn';
      case MusicCategory.psalm:
        return 'Psalm';
      case MusicCategory.other:
        return 'Other';
    }
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get hasAudio => audioUrl?.isNotEmpty == true;
  bool get hasVideo => videoUrl?.isNotEmpty == true;
  bool get hasSheetMusic => sheetMusicUrl?.isNotEmpty == true;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MusicModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MusicModel(id: $id, title: $title, artist: $artist, category: $displayCategory)';
  }
}

// Extension for creating sample data
extension MusicModelSample on MusicModel {
  static List<MusicModel> getSampleSwahiliMusic() {
    final now = DateTime.now();
    return [
      MusicModel(
        id: 'swh_001',
        title: 'Mungu Ni Mwema',
        artist: 'Traditional',
        composer: 'Unknown',
        category: MusicCategory.swahili,
        difficulty: MusicDifficulty.beginner,
        lyrics: '''
Mungu ni mwema, Mungu ni mwema
Hakuna kama yeye, hakuna kama yeye
Milele na milele
Mungu ni mwema

Chorus:
Hallelujah, hallelujah
Mungu ni mwema
Hallelujah, hallelujah  
Mungu ni mwema

Verse 2:
Yeye ni mfalme, yeye ni mfalme
Anasimamia, anasimamia
Maisha yetu yote
Yeye ni mfalme
        '''.trim(),
        musicNotes: '''
Key: G Major
Tempo: 120 BPM
Time Signature: 4/4

Verse:
G - D - Em - C
G - D - Em - C - G

Chorus:
C - G - D - G
C - G - D - G

Bridge:
Em - C - G - D
Em - C - G - D - G
        '''.trim(),
        tags: ['traditional', 'praise', 'swahili', 'beginner'],
        language: 'Swahili',
        duration: 240,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'swahilimusic.com',
      ),
      MusicModel(
        id: 'swh_002',
        title: 'Bwana Asifiwe',
        artist: 'East African Traditional',
        composer: 'Traditional Arrangement',
        category: MusicCategory.swahili,
        difficulty: MusicDifficulty.intermediate,
        lyrics: '''
Bwana asifiwe, Bwana asifiwe
Jina lake takatifu
Bwana asifiwe, Bwana asifiwe
Milele na milele

Verse:
Yeye ndiye mfalme
Wa milele na milele
Hakuna mwingine
Kama Bwana wetu

Chorus:
Bwana asifiwe, Bwana asifiwe
Jina lake takatifu
Bwana asifiwe, Bwana asifiwe
Milele na milele
        '''.trim(),
        musicNotes: '''
Key: F Major
Tempo: 108 BPM
Time Signature: 4/4

Intro:
F - C - Dm - Bb - F

Verse:
F - Bb - F - C
Dm - Bb - F - C - F

Chorus:
Bb - F - C - F
Bb - F - C - Dm
Bb - F - C - F
        '''.trim(),
        tags: ['traditional', 'worship', 'swahili', 'intermediate'],
        language: 'Swahili',
        duration: 300,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'africanmusic.org',
      ),
      MusicModel(
        id: 'swh_003',
        title: 'Yesu Ni Mfalme',
        artist: 'Contemporary Swahili',
        composer: 'Modern Arrangement',
        category: MusicCategory.contemporary,
        difficulty: MusicDifficulty.intermediate,
        lyrics: '''
Yesu ni mfalme, mfalme wa amani
Yeye ndiye njia, ukweli na uzima
Hakuna jina lingine
Chini ya anga lililotolewa

Chorus:
Yesu, Yesu, jina la Yesu
Lina nguvu, lina baraka
Yesu, Yesu, jina la Yesu
Tunaliimba kwa shangwe

Verse 2:
Alituweka huru, kutoka dhambi zetu
Alitupatia maisha, maisha ya milele
Sasa tunaimba, tunamsifu
Yeye ndiye bwana wetu
        '''.trim(),
        musicNotes: '''
Key: D Major
Tempo: 132 BPM
Time Signature: 4/4

Verse:
D - A - Bm - G
D - A - Bm - G - D

Chorus:
G - D - A - Bm
G - D - A - D
G - D - A - Bm
G - A - D

Bridge:
Bm - G - D - A
Bm - G - A - D
        '''.trim(),
        tags: ['contemporary', 'praise', 'worship', 'modern'],
        language: 'Swahili',
        duration: 285,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'swahilimusicnotes.com',
        sheetMusicUrl: 'https://www.swahilimusicnotes.com/song/download/30290/pdf/1617548702-1asante-kwa-kunishirikisha-kiitikio.pdf',
      ),
      MusicModel(
        id: 'swh_004',
        title: 'Nimekuita Yesu',
        artist: 'Traditional Gospel',
        composer: 'African Gospel',
        category: MusicCategory.hymn,
        difficulty: MusicDifficulty.beginner,
        lyrics: '''
Nimekuita Yesu, wewe ndiwe rafiki yangu
Nimekuita Yesu, wewe ndiwe mfalme wangu
Hautatuacha, hautatutupa
Wewe ni Mungu wa kweli

Chorus:
Yesu, Yesu, rafiki wa dhati
Yesu, Yesu, mfalme wa milele
Yesu, Yesu, hautatuacha
Wewe ni Mungu wa kweli

Verse 2:
Wakati wa shida, naita jina lako
Wakati wa furaha, nakushukuru
Kila wakati, wewe upo pamoja nami
Wewe ni Mungu wa kweli
        '''.trim(),
        musicNotes: '''
Key: C Major
Tempo: 96 BPM
Time Signature: 4/4

Verse:
C - G - Am - F
C - G - F - G - C

Chorus:
F - C - G - Am
F - C - G - C
F - C - G - Am
F - G - C

Bridge:
Am - F - C - G
Am - F - G - C
        '''.trim(),
        tags: ['traditional', 'gospel', 'hymn', 'call-response'],
        language: 'Swahili',
        duration: 220,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'swahilimusicnotes.com',
      ),
      MusicModel(
        id: 'swh_005',
        title: 'Tuimbe Hosana',
        artist: 'East African Choir',
        composer: 'Traditional/Contemporary Mix',
        category: MusicCategory.contemporary,
        difficulty: MusicDifficulty.advanced,
        lyrics: '''
Tuimbe hosana, hosana juu
Tuimbe hosana, kwa mfalme wetu
Aliyeingia Yerusalemu
Akiwa amepanda punda

Chorus:
Hosana, hosana, hosana juu
Hosana, hosana, kwa mfalme wetu
Hosana, hosana, hosana juu
Mbarikiwa aliyekuja

Verse 2:
Matawi ya mitende, walizitanda njiani
Mavazi yao, walizitandika
Wakiimba kwa furaha
Hosana, mwana wa Daudi

Bridge:
Mfalme wa amani
Mfalme wa haki
Yeye ndiye aliyetuokoa
Mbarikiwa jina lake
        '''.trim(),
        musicNotes: '''
Key: E Major
Tempo: 140 BPM
Time Signature: 4/4

Verse:
E - B - C#m - A
E - B - A - B - E

Chorus:
A - E - B - C#m
A - E - B - E
A - E - B - C#m
A - B - E

Bridge:
C#m - A - E - B
C#m - A - B - E
F#m - A - E - B
A - B - E

Advanced Harmonies:
Soprano: Main melody
Alto: Third harmony
Tenor: Fifth harmony
Bass: Root and leading tones
        '''.trim(),
        tags: ['contemporary', 'celebration', 'palm-sunday', 'advanced', 'harmony'],
        language: 'Swahili',
        duration: 320,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'swahilimusicnotes.com',
        sheetMusicUrl: 'https://example.com/sheet-music/tuimbe-hosana.pdf',
      ),
      MusicModel(
        id: 'swh_006',
        title: 'Mwanga wa Ulimwengu',
        artist: 'Modern Swahili Worship',
        composer: 'Contemporary Gospel',
        category: MusicCategory.contemporary,
        difficulty: MusicDifficulty.intermediate,
        lyrics: '''
Yesu wewe ni mwanga wa ulimwengu
Wewe ni njia, ukweli na uzima
Bila wewe hatuwezi kuona
Wewe ni mwanga wa ulimwengu

Chorus:
Mwanga, mwanga, mwanga wa ulimwengu
Wewe ni mwanga wa ulimwengu
Mwanga, mwanga, mwanga wa ulimwengu
Tunaomba uangaze

Verse 2:
Katika giza, wewe ni taa yetu
Katika hofu, wewe ni amani yetu
Katika shida, wewe ni msaada wetu
Wewe ni mwanga wa ulimwengu

Bridge:
Tuangaze, tuangaze
Mwanga wako utuongoze
Tuangaze, tuangaze
Njiani kwako
        '''.trim(),
        musicNotes: '''
Key: A Major
Tempo: 126 BPM
Time Signature: 4/4

Verse:
A - E - F#m - D
A - E - D - E - A

Chorus:
D - A - E - F#m
D - A - E - A
D - A - E - F#m
D - E - A

Bridge:
F#m - D - A - E
F#m - D - E - A
Bm - D - A - E
D - E - A

Modern arrangement with:
- Acoustic guitar fingerpicking
- Light percussion
- Vocal harmonies in thirds
        '''.trim(),
        tags: ['contemporary', 'worship', 'modern', 'light'],
        language: 'Swahili',
        duration: 275,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'swahilimusicnotes.com',
      ),
    ];
  }

  static List<MusicModel> getSampleEnglishMusic() {
    final now = DateTime.now();
    return [
      MusicModel(
        id: 'eng_001',
        title: 'Amazing Grace',
        artist: 'Traditional',
        composer: 'John Newton',
        category: MusicCategory.hymn,
        difficulty: MusicDifficulty.beginner,
        lyrics: '''
Amazing grace, how sweet the sound
That saved a wretch like me
I once was lost, but now I'm found
Was blind, but now I see

'Twas grace that taught my heart to fear
And grace my fears relieved
How precious did that grace appear
The hour I first believed

Through many dangers, toils and snares
I have already come
'Tis grace hath brought me safe thus far
And grace will lead me home
        '''.trim(),
        musicNotes: '''
Key: G Major
Tempo: 72 BPM
Time Signature: 3/4

Verse:
G - G - C - G
G - G - D - D
G - G - C - G
G - D - G - G

Standard hymn arrangement
Melody in soprano
Simple four-part harmony
        '''.trim(),
        tags: ['hymn', 'traditional', 'english', 'classic'],
        language: 'English',
        duration: 180,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        sourceWebsite: 'hymnal.net',
        sheetMusicUrl: 'https://example.com/sheet-music/amazing-grace.pdf',
      ),
    ];
  }

  static List<MusicModel> getAllSampleMusic() {
    return [
      ...getSampleSwahiliMusic(),
      ...getSampleEnglishMusic(),
    ];
  }
}