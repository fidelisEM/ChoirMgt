-- Migrations 013/014 only let the choir's own admin_id/leader_id write payments
-- and attendance records, so an app-level admin/superAdmin who is not that
-- choir's admin or leader got "violates row-level security policy" (42501).
-- Global admins inherit the same rights, via is_users_table_admin() (012).

BEGIN;

DROP POLICY IF EXISTS "Members and choir staff can view payments" ON payments;
DROP POLICY IF EXISTS "Choir staff can insert payments" ON payments;
DROP POLICY IF EXISTS "Choir staff can update payments" ON payments;

CREATE POLICY "Members and choir staff can view payments" ON payments
  FOR SELECT USING (
    user_id = auth.uid() OR public.is_users_table_admin() OR
    EXISTS (SELECT 1 FROM choirs c WHERE c.id = payments.choir_id
            AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid()))
  );
CREATE POLICY "Choir staff can insert payments" ON payments
  FOR INSERT WITH CHECK (
    public.is_users_table_admin() OR
    EXISTS (SELECT 1 FROM choirs c WHERE c.id = payments.choir_id
            AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid()))
  );
CREATE POLICY "Choir staff can update payments" ON payments
  FOR UPDATE USING (
    public.is_users_table_admin() OR
    EXISTS (SELECT 1 FROM choirs c WHERE c.id = payments.choir_id
            AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid()))
  );

DROP POLICY IF EXISTS "Members and choir staff can view attendance records" ON attendance_records;
DROP POLICY IF EXISTS "Choir staff can insert attendance records" ON attendance_records;
DROP POLICY IF EXISTS "Choir staff can update attendance records" ON attendance_records;

CREATE POLICY "Members and choir staff can view attendance records" ON attendance_records
  FOR SELECT USING (
    user_id = auth.uid() OR public.is_users_table_admin() OR
    EXISTS (SELECT 1 FROM attendance_sessions s JOIN choirs c ON c.id = s.choir_id
            WHERE s.id = attendance_records.session_id
              AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid()))
  );
CREATE POLICY "Choir staff can insert attendance records" ON attendance_records
  FOR INSERT WITH CHECK (
    public.is_users_table_admin() OR
    EXISTS (SELECT 1 FROM attendance_sessions s JOIN choirs c ON c.id = s.choir_id
            WHERE s.id = attendance_records.session_id
              AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid()))
  );
CREATE POLICY "Choir staff can update attendance records" ON attendance_records
  FOR UPDATE USING (
    public.is_users_table_admin() OR
    EXISTS (SELECT 1 FROM attendance_sessions s JOIN choirs c ON c.id = s.choir_id
            WHERE s.id = attendance_records.session_id
              AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid()))
  );

COMMIT;
