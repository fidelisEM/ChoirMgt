-- Both public.choirs and public.choir_members had an "Allow public read
-- access" policy (qual = true, no role restriction) - same drift template
-- as the one removed from public.users, giving anonymous/unauthenticated
-- clients full read access to every choir's data and every choir's
-- complete membership roster.
--
-- Confirmed intended behavior with the app owner: a new user should be
-- able to browse/select any choir to request joining (pending leader
-- confirmation via the existing "Choir leaders and admins can update choir
-- members" policy), but should only ever see the member roster of a choir
-- they actually belong to.
--
--   - choirs: replace the open policy with an authenticated-only "browse
--     all choirs" policy, so joining still works, but anonymous requests
--     are cut off.
--   - choir_members: just drop the open policy - "Users can view choir
--     members of choirs they belong to" (already existed, scoped to
--     auth.uid() membership) fully covers the intended behavior with no
--     replacement needed.

DROP POLICY IF EXISTS "Allow public read access" ON public.choirs;
CREATE POLICY "Authenticated users can browse choirs" ON public.choirs
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow public read access" ON public.choir_members;
