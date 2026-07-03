-- storage_policies.sql / avatars_bucket_setup.sql had evidently been run
-- multiple times by hand against the live project over time (via the
-- Supabase SQL editor), leaving duplicate storage.objects policies -
-- several with mangled whitespace in their names from copy/paste, and
-- critically, some still carrying the OLD unrestricted definitions:
--   - UPDATE/DELETE on avatars scoped only by bucket_id, no owner check
--     (independent permissive policy, so it coexisted with and defeated
--     the ownership-scoped policy from 004_fix_storage_ownership.sql -
--     Postgres RLS ORs all matching permissive policies together)
--   - INSERT on choir-images scoped to the `public` role instead of
--     `authenticated`, meaning unauthenticated clients could upload files
--
-- This was only discoverable by querying the live pg_policies catalog -
-- none of it was reflected in this repo's SQL files. Cleans it up by
-- matching on the dangerous qualifier/role rather than by name, since the
-- duplicate names contain literal embedded whitespace/newlines that are
-- awkward to hardcode reliably.

DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname, cmd
        FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND cmd IN ('UPDATE', 'DELETE')
          AND qual LIKE '%avatars%'
          AND qual NOT LIKE '%owner%'
    LOOP
        EXECUTE format('DROP POLICY %I ON storage.objects', pol.policyname);
    END LOOP;

    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND cmd = 'INSERT'
          AND 'public' = ANY(roles)
          AND with_check LIKE '%choir-images%'
    LOOP
        EXECUTE format('DROP POLICY %I ON storage.objects', pol.policyname);
    END LOOP;
END $$;

DROP POLICY IF EXISTS "Allow authenticated users to upload choir images (fixed)" ON storage.objects;
CREATE POLICY "Allow authenticated users to upload choir images (fixed)" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'choir-images');
