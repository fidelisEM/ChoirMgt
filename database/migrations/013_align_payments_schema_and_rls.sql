-- Align the payments table with the app's PaymentModel and add RLS policies.
--
-- database_setup.sql created payments with payment_type / payment_method /
-- reference_number columns and value sets that differ from the Dart enums, and
-- enabled RLS without any policy, so the app could not read or write payments.
-- Review, then run once in the Supabase SQL editor.

BEGIN;

-- Drop the old value constraints before rewriting values.
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_payment_type_check;
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_payment_method_check;
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_status_check;

-- Rename columns to the names the app uses (skipped if already renamed).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'payments' AND column_name = 'payment_type') THEN
    ALTER TABLE payments RENAME COLUMN payment_type TO type;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'payments' AND column_name = 'payment_method') THEN
    ALTER TABLE payments RENAME COLUMN payment_method TO method;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'payments' AND column_name = 'reference_number') THEN
    ALTER TABLE payments RENAME COLUMN reference_number TO reference;
  END IF;
END $$;

ALTER TABLE payments ADD COLUMN IF NOT EXISTS currency VARCHAR NOT NULL DEFAULT 'TZS';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS received_by TEXT;

-- Map old values onto the app's enums.
UPDATE payments SET type = CASE type
  WHEN 'membership' THEN 'monthly'
  WHEN 'event'      THEN 'special'
  WHEN 'uniform'    THEN 'special'
  ELSE type END;
UPDATE payments SET method = CASE method
  WHEN 'mobile'        THEN 'mobilePayment'
  WHEN 'bank_transfer' THEN 'bankTransfer'
  WHEN 'card'          THEN 'other'
  ELSE method END;
UPDATE payments SET status = CASE status
  WHEN 'overdue'   THEN 'pending'
  WHEN 'cancelled' THEN 'failed'
  ELSE status END;

ALTER TABLE payments
  ADD CONSTRAINT payments_type_check
  CHECK (type IN ('registration', 'monthly', 'quarterly', 'annual', 'special', 'other'));
ALTER TABLE payments
  ADD CONSTRAINT payments_method_check
  CHECK (method IN ('cash', 'bankTransfer', 'mobilePayment', 'other'));
ALTER TABLE payments
  ADD CONSTRAINT payments_status_check
  CHECK (status IN ('completed', 'pending', 'refunded', 'failed'));
ALTER TABLE payments ALTER COLUMN status SET DEFAULT 'completed';
ALTER TABLE payments ADD CONSTRAINT payments_amount_positive CHECK (amount > 0);

-- RLS: members see their own payments; the choir's admin/leader manage all.
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Remove policies from database_setup_safe.sql; they are superseded below.
DROP POLICY IF EXISTS "Users can view payments for their choir memberships" ON payments;
DROP POLICY IF EXISTS "Leaders can manage payments for their choirs" ON payments;
DROP POLICY IF EXISTS "Members and choir staff can view payments" ON payments;
DROP POLICY IF EXISTS "Choir staff can insert payments" ON payments;
DROP POLICY IF EXISTS "Choir staff can update payments" ON payments;

CREATE POLICY "Members and choir staff can view payments" ON payments
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM choirs c
      WHERE c.id = payments.choir_id
        AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid())
    )
  );

CREATE POLICY "Choir staff can insert payments" ON payments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM choirs c
      WHERE c.id = payments.choir_id
        AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid())
    )
  );

CREATE POLICY "Choir staff can update payments" ON payments
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM choirs c
      WHERE c.id = payments.choir_id
        AND (c.admin_id = auth.uid() OR c.leader_id = auth.uid())
    )
  );

COMMIT;
