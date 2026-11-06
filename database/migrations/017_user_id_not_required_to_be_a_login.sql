-- attendance_records.user_id and payments.user_id were created as
--   REFERENCES auth.users(id) ON DELETE CASCADE
-- Members added by a leader may have no login account, so their records were
-- rejected (23503 foreign key violation). Worse, deleting a login would also
-- delete that person's attendance and payment history.
--
-- member_id (-> choir_members) already identifies the person on both tables,
-- so user_id becomes an optional, unconstrained reference.

BEGIN;

DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT c.conrelid::regclass AS tbl, c.conname
    FROM pg_constraint c
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
    WHERE c.contype = 'f'
      AND c.confrelid = 'auth.users'::regclass
      AND a.attname = 'user_id'
      AND c.conrelid IN ('public.attendance_records'::regclass, 'public.payments'::regclass)
  LOOP
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', r.tbl, r.conname);
    RAISE NOTICE 'dropped % on %', r.conname, r.tbl;
  END LOOP;
END $$;

ALTER TABLE public.attendance_records ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.payments           ALTER COLUMN user_id DROP NOT NULL;

COMMIT;
