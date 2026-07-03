-- Avatars Bucket Setup for User Profile Images
-- Run these commands in your Supabase SQL Editor

-- 1. Create avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Make sure the bucket is public
UPDATE storage.buckets 
SET public = true 
WHERE id = 'avatars';

-- 3. Create RLS policies for avatars bucket
CREATE POLICY "Allow authenticated users to upload avatars" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Allow authenticated users to view avatars" ON storage.objects
FOR SELECT 
TO authenticated
USING (bucket_id = 'avatars');

-- Ownership-checked: `owner` is set automatically by the Storage API to the
-- uploader's auth.uid(), so this restricts writes to the original uploader.
CREATE POLICY "Allow authenticated users to update avatars" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars' AND owner = auth.uid())
WITH CHECK (bucket_id = 'avatars' AND owner = auth.uid());

CREATE POLICY "Allow authenticated users to delete avatars" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'avatars' AND owner = auth.uid());

CREATE POLICY "Allow public to view avatars" ON storage.objects
FOR SELECT 
TO public
USING (bucket_id = 'avatars');