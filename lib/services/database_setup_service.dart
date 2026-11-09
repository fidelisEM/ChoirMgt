import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class DatabaseSetupService {
  static final _supabase = Supabase.instance.client;

  /// Create the music table with all necessary columns and indexes
  static Future<bool> createMusicTable() async {
    try {
      Logger.info('Creating music table...');

      // First, check if the table already exists
      const checkTableQuery = '''
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = 'music'
        );
      ''';

      final checkResult = await _supabase
          .rpc('exec_sql', params: {'sql_query': checkTableQuery})
          .catchError((error) {
            Logger.error('Error checking if music table exists: $error');
            return null;
          });

      if (checkResult != null && checkResult == true) {
        Logger.info('Music table already exists');
        return true;
      }

      // Create the music table
      const createTableQuery = '''
        CREATE TABLE IF NOT EXISTS public.music (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          title TEXT NOT NULL,
          artist TEXT NOT NULL DEFAULT '',
          composer TEXT NOT NULL DEFAULT '',
          category TEXT NOT NULL DEFAULT 'other',
          difficulty TEXT NOT NULL DEFAULT 'beginner',
          lyrics TEXT NOT NULL DEFAULT '',
          music_notes TEXT NOT NULL DEFAULT '',
          audio_url TEXT,
          video_url TEXT,
          sheet_music_url TEXT,
          tags TEXT[] DEFAULT '{}',
          language TEXT NOT NULL DEFAULT 'English',
          duration INTEGER DEFAULT 0,
          choir_id UUID,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          is_public BOOLEAN DEFAULT true,
          source_website TEXT,
          metadata JSONB,
          
          CONSTRAINT music_title_not_empty CHECK (length(trim(title)) > 0)
        );
      ''';

      await _supabase.rpc('exec_sql', params: {'sql_query': createTableQuery});

      Logger.info('Music table created successfully');

      // Create indexes
      final indexes = [
        'CREATE INDEX IF NOT EXISTS idx_music_category ON public.music(category);',
        'CREATE INDEX IF NOT EXISTS idx_music_language ON public.music(language);',
        'CREATE INDEX IF NOT EXISTS idx_music_choir_id ON public.music(choir_id);',
        'CREATE INDEX IF NOT EXISTS idx_music_is_public ON public.music(is_public);',
        'CREATE INDEX IF NOT EXISTS idx_music_created_at ON public.music(created_at);',
      ];

      for (final indexSql in indexes) {
        try {
          await _supabase.rpc('exec_sql', params: {'sql_query': indexSql});
        } catch (e) {
          Logger.error('Error creating index: $e');
          // Continue with other indexes even if one fails
        }
      }

      Logger.info('Music table indexes created');

      // Enable RLS
      await _supabase.rpc(
        'exec_sql',
        params: {
          'sql_query': 'ALTER TABLE public.music ENABLE ROW LEVEL SECURITY;',
        },
      );

      // Create RLS policies
      final policies = [
        '''
        CREATE POLICY "Public music is readable by everyone" ON public.music
          FOR SELECT
          USING (is_public = true);
        ''',
        '''
        CREATE POLICY "Authenticated users can create music" ON public.music
          FOR INSERT
          TO authenticated
          WITH CHECK (true);
        ''',
        '''
        CREATE POLICY "Music creators can update their music" ON public.music
          FOR UPDATE
          TO authenticated
          USING (is_public = true);
        ''',
        '''
        CREATE POLICY "Music creators can delete their music" ON public.music
          FOR DELETE
          TO authenticated
          USING (is_public = true);
        ''',
      ];

      for (final policy in policies) {
        try {
          await _supabase.rpc('exec_sql', params: {'sql_query': policy});
        } catch (e) {
          Logger.error('Error creating policy: $e');
          // Continue with other policies even if one fails
        }
      }

      Logger.info('Music table RLS policies created');

      // Insert sample data
      await _insertSampleMusicData();

      Logger.info('Music table setup completed successfully');
      return true;
    } catch (e) {
      Logger.error('Error creating music table: $e');
      return false;
    }
  }

  /// Insert sample Swahili music data
  static Future<void> _insertSampleMusicData() async {
    try {
      Logger.info('Inserting sample music data...');

      final sampleMusic = [
        {
          'title': 'Asante Kwa Kunishirikisha',
          'artist': 'Swahili Music Notes',
          'composer': 'Traditional',
          'category': 'swahili',
          'difficulty': 'beginner',
          'lyrics': '''Asante kwa kunishirikisha
Katika mazuri yako
Asante kwa kunipa furaha
Na amani moyoni mwangu

Chorus:
Bwana wewe ni mwema
Huruma yako ni milele
Asante kwa kunishirikisha
Katika upendo wako''',
          'music_notes': '''**ASANTE KWA KUNISHIRIKISHA**
*Key: C Major*
*Time: 4/4*
*BPM: 80*

**Verse 1:**
C       F        G      C
Asante kwa kunishirikisha
F        G        Am    G
Katika mazuri yako
C        F       G      C
Asante kwa kunipa furaha
F      G         C
Na amani moyoni mwangu

**Chorus:**
F        G       C      Am
Bwana wewe ni mwema
F         G        C
Huruma yako ni milele
F        G        C     Am
Asante kwa kunishirikisha
F      G         C
Katika upendo wako''',
          'language': 'Swahili',
          'is_public': true,
          'source_website': 'https://www.swahilimusicnotes.com',
          'tags': ['thanksgiving', 'gratitude', 'swahili', 'traditional'],
          'sheet_music_url':
              'https://www.swahilimusicnotes.com/song/download/30290/pdf/1617548702-1asante-kwa-kunishirikisha-kiitikio.pdf',
        },
        {
          'title': 'Nimshukuru Mwenyezi',
          'artist': 'African Church Music',
          'composer': 'Traditional Swahili',
          'category': 'swahili',
          'difficulty': 'intermediate',
          'lyrics': '''Nimshukuru Mwenyezi
Kwa yote aliyofanya
Amependeza sana
Roho yangu na moyoni

Chorus:
Mwenyezi ni mwema
Huruma yake ni kubwa
Tuimbe kwa furaha
Tusifu jina lake''',
          'music_notes': '''**NIMSHUKURU MWENYEZI**
*Key: G Major*
*Time: 3/4*
*BPM: 90*

**Verse:**
G         C        D      G
Nimshukuru Mwenyezi
C         D        Em   D
Kwa yote aliyofanya
G         C       D      G
Amependeza sana
C       D         G
Roho yangu na moyoni

**Chorus:**
C        D       G      Em
Mwenyezi ni mwema
C         D        G
Huruma yake ni kubwa
C        D        G     Em
Tuimbe kwa furaha
C      D         G
Tusifu jina lake''',
          'language': 'Swahili',
          'is_public': true,
          'source_website': 'https://www.swahilimusicnotes.com',
          'tags': ['praise', 'worship', 'swahili', 'traditional'],
        },
        {
          'title': 'Bwana Ni Mchungaji Wangu',
          'artist': 'Swahili Psalms',
          'composer': 'Psalm 23',
          'category': 'psalm',
          'difficulty': 'beginner',
          'lyrics': '''Bwana ni mchungaji wangu
Sitapungua kitu
Ananilaza majani mabichi
Na aniongoza maji ya utulivu

Chorus:
Hata nikipita bondeni
La kivuli cha mauti
Sitoogopa ubaya wowote
Kwa kuwa wewe u pamoja nami''',
          'music_notes': '''**BWANA NI MCHUNGAJI WANGU**
*Key: D Major*
*Time: 4/4*
*BPM: 75*

**Verse:**
D        G        A      D
Bwana ni mchungaji wangu
G        A        Bm   A
Sitapungua kitu
D        G       A      D
Ananilaza majani mabichi
G      A         D
Na aniongoza maji ya utulivu

**Chorus:**
G        A       D      Bm
Hata nikipita bondeni
G         A        D
La kivuli cha mauti
G        A        D     Bm
Sitoogopa ubaya wowote
G      A         D
Kwa kuwa wewe u pamoja nami''',
          'language': 'Swahili',
          'is_public': true,
          'source_website': 'Traditional',
          'tags': ['psalm', 'comfort', 'swahili', 'traditional'],
        },
      ];

      for (final music in sampleMusic) {
        try {
          await _supabase.from('music').insert(music);
        } catch (e) {
          Logger.error('Error inserting sample music ${music['title']}: $e');
        }
      }

      Logger.info('Sample music data inserted successfully');
    } catch (e) {
      Logger.error('Error inserting sample music data: $e');
    }
  }

  /// Check if music table exists
  static Future<bool> musicTableExists() async {
    try {
      // Try to query the music table
      await _supabase.from('music').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize the database if needed
  static Future<void> initializeDatabase() async {
    try {
      Logger.info('Initializing database...');

      final tableExists = await musicTableExists();
      if (!tableExists) {
        Logger.info('Music table does not exist, creating...');
        final success = await createMusicTable();
        if (success) {
          Logger.info('Database initialized successfully');
        } else {
          Logger.error('Failed to initialize database');
        }
      } else {
        Logger.info('Music table already exists, skipping creation');
      }
    } catch (e) {
      Logger.error('Error initializing database: $e');
    }
  }
}
