-- Create choirs table
CREATE TABLE IF NOT EXISTS choirs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    leader_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    admin_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    is_active BOOLEAN DEFAULT true,
    member_count INTEGER DEFAULT 0,
    image_url TEXT,
    tags TEXT[] DEFAULT '{}'
);

-- Create choir_members table
CREATE TABLE IF NOT EXISTS choir_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    choir_id UUID REFERENCES choirs(id) ON DELETE CASCADE,
    registration_number VARCHAR UNIQUE NOT NULL,
    join_date TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    status VARCHAR DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    role VARCHAR DEFAULT 'choir' CHECK (role IN ('leader', 'committee', 'board', 'choir', 'patron', 'trainer')),
    level VARCHAR DEFAULT 'choir' CHECK (level IN ('national', 'diocese', 'parish', 'choir')),
    last_attendance TIMESTAMP WITH TIME ZONE,
    total_attendances INTEGER DEFAULT 0,
    total_absences INTEGER DEFAULT 0,
    total_late_arrivals INTEGER DEFAULT 0,
    outstanding_fees DECIMAL(10,2) DEFAULT 0.00,
    total_paid DECIMAL(10,2) DEFAULT 0.00,
    qr_code VARCHAR,
    metadata JSONB DEFAULT '{}'::JSONB,
    UNIQUE(user_id, choir_id)
);

-- Create attendance_sessions table
CREATE TABLE IF NOT EXISTS attendance_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    choir_id UUID REFERENCES choirs(id) ON DELETE CASCADE,
    leader_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    event_type VARCHAR NOT NULL CHECK (event_type IN ('rehearsal', 'service', 'meeting', 'other')),
    title VARCHAR NOT NULL,
    description TEXT,
    grace_minutes INTEGER DEFAULT 15,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create attendance_records table
CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES attendance_sessions(id) ON DELETE CASCADE,
    member_id UUID REFERENCES choir_members(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR NOT NULL CHECK (status IN ('present', 'late', 'absent')),
    check_in_time TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    recorded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    UNIQUE(session_id, member_id)
);

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    member_id UUID REFERENCES choir_members(id) ON DELETE CASCADE,
    choir_id UUID REFERENCES choirs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_type VARCHAR NOT NULL CHECK (payment_type IN ('membership', 'event', 'uniform', 'other')),
    description TEXT,
    payment_method VARCHAR CHECK (payment_method IN ('cash', 'card', 'mobile', 'bank_transfer', 'other')),
    reference_number VARCHAR,
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    due_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'overdue', 'cancelled')),
    recorded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    choir_id UUID REFERENCES choirs(id) ON DELETE CASCADE,
    type VARCHAR NOT NULL CHECK (type IN ('payment_due', 'attendance_reminder', 'event_announcement', 'system_update', 'other')),
    title VARCHAR NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    priority VARCHAR DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    read_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_choirs_admin_id ON choirs(admin_id);
CREATE INDEX IF NOT EXISTS idx_choirs_leader_id ON choirs(leader_id);
CREATE INDEX IF NOT EXISTS idx_choirs_active ON choirs(is_active);

CREATE INDEX IF NOT EXISTS idx_choir_members_user_id ON choir_members(user_id);
CREATE INDEX IF NOT EXISTS idx_choir_members_choir_id ON choir_members(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_members_status ON choir_members(status);

CREATE INDEX IF NOT EXISTS idx_attendance_sessions_choir_id ON attendance_sessions(choir_id);
CREATE INDEX IF NOT EXISTS idx_attendance_sessions_date ON attendance_sessions(date);

CREATE INDEX IF NOT EXISTS idx_attendance_records_session_id ON attendance_records(session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_member_id ON attendance_records(member_id);

CREATE INDEX IF NOT EXISTS idx_payments_member_id ON payments(member_id);
CREATE INDEX IF NOT EXISTS idx_payments_choir_id ON payments(choir_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_due_date ON payments(due_date);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);

-- Enable Row Level Security (RLS)
ALTER TABLE choirs ENABLE ROW LEVEL SECURITY;
ALTER TABLE choir_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for choirs
CREATE POLICY "Users can view choirs they are members or leaders of" ON choirs
    FOR SELECT USING (
        leader_id = auth.uid() OR 
        admin_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM choir_members 
            WHERE choir_id = choirs.id 
            AND user_id = auth.uid()
            AND status = 'active'
        )
    );

CREATE POLICY "Admins can insert choirs" ON choirs
    FOR INSERT WITH CHECK (
        admin_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'choirLeader')
        )
    );

CREATE POLICY "Choir admins and leaders can update choirs" ON choirs
    FOR UPDATE USING (
        admin_id = auth.uid() OR leader_id = auth.uid()
    );

CREATE POLICY "Only admins can delete choirs" ON choirs
    FOR DELETE USING (
        admin_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- RLS Policies for choir_members
CREATE POLICY "Users can view choir members of choirs they belong to" ON choir_members
    FOR SELECT USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM choirs 
            WHERE id = choir_members.choir_id 
            AND (leader_id = auth.uid() OR admin_id = auth.uid())
        ) OR
        EXISTS (
            SELECT 1 FROM choir_members cm2 
            WHERE cm2.choir_id = choir_members.choir_id 
            AND cm2.user_id = auth.uid()
            AND cm2.status = 'active'
        )
    );

CREATE POLICY "Choir leaders and admins can insert choir members" ON choir_members
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM choirs 
            WHERE id = choir_id 
            AND (leader_id = auth.uid() OR admin_id = auth.uid())
        )
    );

CREATE POLICY "Choir leaders and admins can update choir members" ON choir_members
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM choirs 
            WHERE id = choir_id 
            AND (leader_id = auth.uid() OR admin_id = auth.uid())
        )
    );

CREATE POLICY "Choir leaders and admins can delete choir members" ON choir_members
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM choirs 
            WHERE id = choir_id 
            AND (leader_id = auth.uid() OR admin_id = auth.uid())
        )
    );

-- Additional policies for attendance and payments would follow similar patterns...
-- (Simplified for brevity, but following the same security model)

-- Functions to update attendance counts
CREATE OR REPLACE FUNCTION update_member_attendance()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE choir_members SET
            total_attendances = (
                SELECT COUNT(*) FROM attendance_records 
                WHERE member_id = NEW.member_id AND status = 'present'
            ),
            total_absences = (
                SELECT COUNT(*) FROM attendance_records 
                WHERE member_id = NEW.member_id AND status = 'absent'
            ),
            total_late_arrivals = (
                SELECT COUNT(*) FROM attendance_records 
                WHERE member_id = NEW.member_id AND status = 'late'
            ),
            last_attendance = CASE 
                WHEN NEW.status IN ('present', 'late') THEN NEW.recorded_at 
                ELSE last_attendance 
            END
        WHERE id = NEW.member_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE choir_members SET
            total_attendances = (
                SELECT COUNT(*) FROM attendance_records 
                WHERE member_id = OLD.member_id AND status = 'present'
            ),
            total_absences = (
                SELECT COUNT(*) FROM attendance_records 
                WHERE member_id = OLD.member_id AND status = 'absent'
            ),
            total_late_arrivals = (
                SELECT COUNT(*) FROM attendance_records 
                WHERE member_id = OLD.member_id AND status = 'late'
            )
        WHERE id = OLD.member_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update attendance counts
CREATE TRIGGER trigger_update_member_attendance
    AFTER INSERT OR UPDATE OR DELETE ON attendance_records
    FOR EACH ROW EXECUTE FUNCTION update_member_attendance();

-- Function to update choir member count
CREATE OR REPLACE FUNCTION update_choir_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE choirs SET
            member_count = (
                SELECT COUNT(*) FROM choir_members 
                WHERE choir_id = NEW.choir_id AND status = 'active'
            )
        WHERE id = NEW.choir_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE choirs SET
            member_count = (
                SELECT COUNT(*) FROM choir_members 
                WHERE choir_id = OLD.choir_id AND status = 'active'
            )
        WHERE id = OLD.choir_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update choir member count
CREATE TRIGGER trigger_update_choir_member_count
    AFTER INSERT OR UPDATE OR DELETE ON choir_members
    FOR EACH ROW EXECUTE FUNCTION update_choir_member_count();