-- Adds ownership checks to storage RLS policies. storage_policies.sql and
-- avatars_bucket_setup.sql previously scoped UPDATE/DELETE only by
-- bucket_id, so any authenticated user could overwrite or delete any other
-- user's uploaded file in the choir-images / avatars buckets.
--
-- storage.objects.owner is set automatically by the Storage API to the
-- uploading user's auth.uid() - comparing against it is enough to restrict
-- writes to the original uploader without requiring any change to the
-- app's existing upload paths.

-- RLS is already enabled on storage.objects by default in Supabase, and
-- altering it requires table ownership the management API role doesn't
-- have - only the policy statements below are needed/possible here.

DROP POLICY IF EXISTS "Allow authenticated users to update choir images" ON storage.objects;
CREATE POLICY "Allow authenticated users to update choir images" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'choir-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'choir-images' AND owner = auth.uid());

DROP POLICY IF EXISTS "Allow authenticated users to delete choir images" ON storage.objects;
CREATE POLICY "Allow authenticated users to delete choir images" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'choir-images' AND owner = auth.uid());

DROP POLICY IF EXISTS "Allow authenticated users to update avatars" ON storage.objects;
CREATE POLICY "Allow authenticated users to update avatars" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars' AND owner = auth.uid())
WITH CHECK (bucket_id = 'avatars' AND owner = auth.uid());

DROP POLICY IF EXISTS "Allow authenticated users to delete avatars" ON storage.objects;
CREATE POLICY "Allow authenticated users to delete avatars" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'avatars' AND owner = auth.uid());
