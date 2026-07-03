-- Adds Row Level Security to public.users. No RLS policy for this table
-- existed anywhere in the repo, meaning any authenticated client (and
-- possibly anon, depending on grants) could read/update/delete arbitrary
-- user rows directly via the Supabase client SDK - the app's role/permission
-- checks in lib/services/auth_service.dart are enforced only in Dart and do
-- nothing to stop a client that talks to Postgres directly.
--
-- Columns referenced below (id, email, role, is_active, ...) match
-- lib/models/user_model.dart's toJson()/fromJson().

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- SECURITY DEFINER helpers used by the policies below. A policy on
-- public.users that queries public.users directly (e.g.
-- "EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role =
-- 'admin')") triggers Postgres error 42P17 "infinite recursion detected in
-- policy for relation users" - evaluating the policy re-triggers RLS on the
-- same table, which re-evaluates the policy, forever. A SECURITY DEFINER
-- function's internal query bypasses RLS (it runs as the function's owner,
-- not the calling role), so it can safely look up the row without
-- re-entering these policies.
CREATE OR REPLACE FUNCTION public.is_users_table_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.current_users_table_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

DROP POLICY IF EXISTS "Authenticated users can read all users" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile (not role)" ON public.users;
DROP POLICY IF EXISTS "Admins can manage all users" ON public.users;

-- Directory-style read access: the app shows member names/emails to other
-- signed-in members (choir rosters, admin/leader email lookup on the edit
-- choir screen) so this intentionally isn't restricted to "own row only".
-- It does require authentication, unlike the previous no-RLS-at-all state.
CREATE POLICY "Authenticated users can read all users" ON public.users
    FOR SELECT
    TO authenticated
    USING (true);

-- Self-registration: a user may only ever insert their own row, and can
-- never insert themselves with an elevated role - new accounts always start
-- as choirMember. Promotions must go through the admin policy below.
CREATE POLICY "Users can insert their own profile" ON public.users
    FOR INSERT
    TO authenticated
    WITH CHECK (
        id = auth.uid()
        AND role = 'choirMember'
    );

-- Self-service profile edits, but the role column is frozen: WITH CHECK
-- compares the new row's role against the row's current (pre-update) role,
-- read via the non-recursive helper above, so a user cannot smuggle a role
-- change into an otherwise-legitimate profile update. Only the admin
-- policy below can change role.
CREATE POLICY "Users can update their own profile (not role)" ON public.users
    FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (
        id = auth.uid()
        AND role = public.current_users_table_role()
    );

-- Admins can read/update/delete any user, including changing roles.
CREATE POLICY "Admins can manage all users" ON public.users
    FOR ALL
    TO authenticated
    USING (public.is_users_table_admin())
    WITH CHECK (public.is_users_table_admin());
