-- Storage Bucket Policies for Choir Management System
-- Run these commands in your Supabase SQL Editor

-- 1. Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2. Allow authenticated users to upload files to choir-images bucket
CREATE POLICY "Allow authenticated users to upload choir images" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (bucket_id = 'choir-images');

-- 3. Allow authenticated users to view choir images
CREATE POLICY "Allow authenticated users to view choir images" ON storage.objects
FOR SELECT 
TO authenticated
USING (bucket_id = 'choir-images');

-- 4. Allow users to update their own uploads (ownership-checked - `owner` is
--    set automatically by the Storage API to the uploader's auth.uid())
CREATE POLICY "Allow authenticated users to update choir images" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'choir-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'choir-images' AND owner = auth.uid());

-- 5. Allow users to delete their own uploads
CREATE POLICY "Allow authenticated users to delete choir images" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'choir-images' AND owner = auth.uid());

-- 6. Make sure the bucket allows public access for viewing
UPDATE storage.buckets 
SET public = true 
WHERE id = 'choir-images';

-- 7. Additional policy for public read access (for image display)
CREATE POLICY "Allow public to view choir images" ON storage.objects
FOR SELECT 
TO public
USING (bucket_id = 'choir-images');