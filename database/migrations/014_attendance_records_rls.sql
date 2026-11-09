-- attendance_records has RLS enabled but no policies (database_setup_safe.sql
-- created policies on a table named "attendance", which does not exist), so
-- every read and write from the app is rejected. The app swallows that error
-- and falls back to SharedPreferences, so attendance never reaches the server.

BEGIN;

ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members and choir staff can view attendance records" ON attendance_records;
DROP POLICY IF EXISTS "Choir staff can insert attendance records" ON attendance_records;
DROP POLICY IF EXISTS "Choir staff can update attendance records" ON attendance_records;

CREATE POLICY "Members and choir staff can view attendance records" ON attendance_records
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM attendance_sessions s
      JOIN choirs c ON c.id = s.choir_id
      WHERE s.id = attendance_records.session_id
        AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid())
    )
  );

CREATE POLICY "Choir staff can insert attendance records" ON attendance_records
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM attendance_sessions s
      JOIN choirs c ON c.id = s.choir_id
      WHERE s.id = attendance_records.session_id
        AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid())
    )
  );

-- Upserts from the app need UPDATE as well as INSERT.
CREATE POLICY "Choir staff can update attendance records" ON attendance_records
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM attendance_sessions s
      JOIN choirs c ON c.id = s.choir_id
      WHERE s.id = attendance_records.session_id
        AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid())
    )
  );

COMMIT;
