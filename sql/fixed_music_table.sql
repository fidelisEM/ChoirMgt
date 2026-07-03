-- Create music table for Choir Management System
CREATE TABLE IF NOT EXISTS public.music (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    artist TEXT NOT NULL DEFAULT '',
    composer TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT 'other', -- swahili, english, latin, traditional, contemporary, hymn, psalm, other
    difficulty TEXT NOT NULL DEFAULT 'beginner', -- beginner, intermediate, advanced
    lyrics TEXT NOT NULL DEFAULT '',
    music_notes TEXT NOT NULL DEFAULT '',
    audio_url TEXT,
    video_url TEXT,
    sheet_music_url TEXT,
    sheet_music_data BYTEA, -- Store PDF binary data
    tags TEXT[] DEFAULT '{}',
    language TEXT NOT NULL DEFAULT 'English',
    duration INTEGER DEFAULT 0, -- in seconds
    choir_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_public BOOLEAN DEFAULT true,
    source_website TEXT,
    metadata JSONB,
    
    -- Indexes for better performance
    CONSTRAINT music_title_not_empty CHECK (length(trim(title)) > 0)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_music_category ON public.music(category);
CREATE INDEX IF NOT EXISTS idx_music_language ON public.music(language);
CREATE INDEX IF NOT EXISTS idx_music_choir_id ON public.music(choir_id);
CREATE INDEX IF NOT EXISTS idx_music_is_public ON public.music(is_public);
CREATE INDEX IF NOT EXISTS idx_music_created_at ON public.music(created_at);

-- Enable Row Level Security
ALTER TABLE public.music ENABLE ROW LEVEL SECURITY;

-- RLS Policies for music table

-- Policy for public music (everyone can read)
CREATE POLICY "Public music is readable by everyone" ON public.music
    FOR SELECT
    USING (is_public = true);

-- Policy for music creation (authenticated users can create)
CREATE POLICY "Authenticated users can create music" ON public.music
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy for music updates (choir admins/leaders, or system admins for public music)
-- NOTE: kept in sync with database/migrations/002_fix_music_rls_policies.sql -
-- do not reintroduce USING (true) here, it lets any authenticated user
-- overwrite or delete any music record.
CREATE POLICY "Music creators and choir admins can update music" ON public.music
    FOR UPDATE
    TO authenticated
    USING (
        (choir_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.choir_members cm
            WHERE cm.choir_id = music.choir_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('admin', 'leader')
        ))
        OR (is_public = true AND EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid()
            AND u.role = 'admin'
        ))
    );

-- Policy for music deletion (choir admins/leaders, or system admins for public music)
CREATE POLICY "Music creators and choir admins can delete music" ON public.music
    FOR DELETE
    TO authenticated
    USING (
        (choir_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.choir_members cm
            WHERE cm.choir_id = music.choir_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('admin', 'leader')
        ))
        OR (is_public = true AND EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid()
            AND u.role = 'admin'
        ))
    );

-- Grant permissions
GRANT ALL ON public.music TO authenticated;
GRANT SELECT ON public.music TO anon;

-- Insert sample Swahili music data with all columns properly matched
INSERT INTO public.music (
    title, artist, composer, category, difficulty, 
    lyrics, music_notes, language, is_public, 
    source_website, tags, sheet_music_url
) VALUES 
(
    'Asante Kwa Kunishirikisha', 
    'Swahili Music Notes', 
    'Traditional', 
    'swahili', 
    'beginner', 
    'Asante kwa kunishirikisha
Katika mazuri yako
Asante kwa kunipa furaha
Na amani moyoni mwangu

Chorus:
Bwana wewe ni mwema
Huruma yako ni milele
Asante kwa kunishirikisha
Katika upendo wako',
    '**ASANTE KWA KUNISHIRIKISHA**
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
Katika upendo wako',
    'Swahili', 
    true, 
    'https://www.swahilimusicnotes.com', 
    ARRAY['thanksgiving', 'gratitude', 'swahili', 'traditional'],
    'https://www.swahilimusicnotes.com/song/download/30290/pdf/1617548702-1asante-kwa-kunishirikisha-kiitikio.pdf'
),
(
    'Nimshukuru Mwenyezi', 
    'African Church Music', 
    'Traditional Swahili', 
    'swahili', 
    'intermediate',
    'Nimshukuru Mwenyezi
Kwa yote aliyofanya
Amependeza sana
Roho yangu na moyoni

Chorus:
Mwenyezi ni mwema
Huruma yake ni kubwa
Tuimbe kwa furaha
Tusifu jina lake',
    '**NIMSHUKURU MWENYEZI**
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
Tusifu jina lake',
    'Swahili', 
    true, 
    'https://www.swahilimusicnotes.com', 
    ARRAY['praise', 'worship', 'swahili', 'traditional'],
    NULL
),
(
    'Bwana Ni Mchungaji Wangu', 
    'Swahili Psalms', 
    'Psalm 23', 
    'psalm', 
    'beginner',
    'Bwana ni mchungaji wangu
Sitapungua kitu
Ananilaza majani mabichi
Na aniongoza maji ya utulivu

Chorus:
Hata nikipita bondeni
La kivuli cha mauti
Sitoogopa ubaya wowote
Kwa kuwa wewe u pamoja nami',
    '**BWANA NI MCHUNGAJI WANGU**
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
Kwa kuwa wewe u pamoja nami',
    'Swahili', 
    true, 
    'Traditional', 
    ARRAY['psalm', 'comfort', 'swahili', 'traditional'],
    NULL
);

-- Add comment to table
COMMENT ON TABLE public.music IS 'Stores music notes, lyrics, and sheet music for church choirs';
COMMENT ON COLUMN public.music.sheet_music_url IS 'URL to PDF sheet music document';
COMMENT ON COLUMN public.music.sheet_music_data IS 'Binary PDF data for offline access';
COMMENT ON COLUMN public.music.metadata IS 'Additional metadata like tempo, key signature, etc.';