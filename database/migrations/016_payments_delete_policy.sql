-- Lets choir staff (the choir's admin/leader) and global admins delete a
-- payment, e.g. to remove an accidental duplicate. Members cannot.

DROP POLICY IF EXISTS "Choir staff can delete payments" ON payments;

CREATE POLICY "Choir staff can delete payments" ON payments
  FOR DELETE USING (
    public.is_users_table_admin() OR
    EXISTS (SELECT 1 FROM choirs c WHERE c.id = payments.choir_id
            AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid()))
  );
