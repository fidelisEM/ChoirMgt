-- Fixes overly-permissive RLS policies that shipped in sql/fixed_music_table.sql
-- (USING (true) / WITH CHECK (true) on UPDATE/DELETE let any authenticated
-- user overwrite or delete any music record, regardless of ownership).
-- This migration only touches policies - it assumes the `music` table
-- (from sql/create_music_table.sql or sql/fixed_music_table.sql) already
-- exists, and is safe to re-run.

ALTER TABLE public.music ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can update music" ON public.music;
DROP POLICY IF EXISTS "Authenticated users can delete music" ON public.music;
DROP POLICY IF EXISTS "Music creators and choir admins can update music" ON public.music;
DROP POLICY IF EXISTS "Music creators and choir admins can delete music" ON public.music;

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
