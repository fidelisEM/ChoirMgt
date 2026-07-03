-- Same drift pattern as found on public.users (see 003_add_users_rls.sql):
-- "Allow authenticated insert" / "Allow authenticated update" policies with
-- qual/with_check = true and no role restriction (defaults to `public`,
-- i.e. anon + authenticated). These coexisted with the properly-scoped
-- policies the app actually relies on ("Choir admins and leaders can
-- update choirs", "Choir leaders and admins can insert/update choir
-- members", etc.) and, being independent permissive policies, silently
-- defeated them - Postgres RLS ORs all matching permissive policies
-- together. In practice this meant anyone with just the anon key could
-- create/edit arbitrary choirs, or insert/modify choir_members rows
-- (including setting their own membership role to admin/leader for any
-- choir).
--
-- Confirmed via the live pg_policies catalog (not present in any repo SQL
-- file - these tables' CREATE POLICY statements aren't tracked here at
-- all, only discovered by querying the linked project directly).

DROP POLICY IF EXISTS "Allow authenticated insert" ON public.choirs;
DROP POLICY IF EXISTS "Allow authenticated update" ON public.choirs;
DROP POLICY IF EXISTS "Allow authenticated insert" ON public.choir_members;
DROP POLICY IF EXISTS "Allow authenticated update" ON public.choir_members;
