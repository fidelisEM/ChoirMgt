-- Safe Database Setup Script for Choir Management System
-- This script handles existing tables and policies gracefully

-- Create choirs table (safe to run multiple times)
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
    tags TEXT[] DEFAULT '{}',
    country VARCHAR,
    diocese VARCHAR,
    parish VARCHAR
);

-- Create choir_members table (safe to run multiple times)
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

-- Create attendance_sessions table (safe to run multiple times)
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

-- Create attendance table (safe to run multiple times)
CREATE TABLE IF NOT EXISTS attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES attendance_sessions(id) ON DELETE CASCADE,
    member_id UUID REFERENCES choir_members(id) ON DELETE CASCADE,
    status VARCHAR NOT NULL CHECK (status IN ('present', 'absent', 'late', 'excused')),
    arrival_time TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE(session_id, member_id)
);

-- Create payments table (safe to run multiple times)
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    member_id UUID REFERENCES choir_members(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    payment_type VARCHAR NOT NULL CHECK (payment_type IN ('dues', 'fee', 'donation', 'other')),
    description TEXT,
    payment_method VARCHAR CHECK (payment_method IN ('cash', 'card', 'transfer', 'mobile', 'other')),
    reference_number VARCHAR,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create music table (safe to run multiple times)
CREATE TABLE IF NOT EXISTS music (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    artist VARCHAR NOT NULL,
    composer VARCHAR NOT NULL,
    category VARCHAR NOT NULL CHECK (category IN ('swahili', 'english', 'latin', 'traditional', 'contemporary', 'hymn', 'psalm', 'other')),
    difficulty VARCHAR NOT NULL CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    lyrics TEXT NOT NULL,
    music_notes TEXT DEFAULT '',
    audio_url TEXT,
    video_url TEXT,
    sheet_music_url TEXT,
    tags TEXT[] DEFAULT '{}',
    language VARCHAR NOT NULL,
    duration INTEGER DEFAULT 0,
    choir_id UUID REFERENCES choirs(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    is_public BOOLEAN DEFAULT true,
    source_website VARCHAR,
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Create message types enum (safe to run multiple times)
DO $$ 
BEGIN
    CREATE TYPE message_type AS ENUM ('announcement', 'discussion', 'reminder', 'urgent');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Create messages table (safe to run multiple times)
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    choir_id UUID REFERENCES choirs(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_name VARCHAR(255) NOT NULL,
    subject VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    type message_type NOT NULL DEFAULT 'discussion',
    recipients UUID[] DEFAULT '{}', -- Empty array means all members
    read_by UUID[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT subject_not_empty CHECK (length(trim(subject)) > 0),
    CONSTRAINT content_not_empty CHECK (length(trim(content)) > 0)
);

-- Enable RLS on all tables
ALTER TABLE choirs ENABLE ROW LEVEL SECURITY;
ALTER TABLE choir_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DO $$ 
BEGIN
    -- Drop choirs policies
    DROP POLICY IF EXISTS "Users can view choirs they are members or leaders of" ON choirs;
    DROP POLICY IF EXISTS "Leaders can update their choirs" ON choirs;
    DROP POLICY IF EXISTS "Authenticated users can create choirs" ON choirs;
    
    -- Drop choir_members policies
    DROP POLICY IF EXISTS "Users can view choir members of choirs they belong to" ON choir_members;
    DROP POLICY IF EXISTS "Leaders can manage choir members" ON choir_members;
    DROP POLICY IF EXISTS "Users can join choirs" ON choir_members;
    
    -- Drop attendance policies
    DROP POLICY IF EXISTS "Users can view attendance for their choirs" ON attendance_sessions;
    DROP POLICY IF EXISTS "Leaders can manage attendance sessions" ON attendance_sessions;
    DROP POLICY IF EXISTS "Users can view attendance records for their choirs" ON attendance;
    DROP POLICY IF EXISTS "Leaders can manage attendance records" ON attendance;
    
    -- Drop payment policies
    DROP POLICY IF EXISTS "Users can view payments for their choir memberships" ON payments;
    DROP POLICY IF EXISTS "Leaders can manage payments for their choirs" ON payments;
    
    -- Drop message policies
    DROP POLICY IF EXISTS "Users can view choir messages" ON messages;
    DROP POLICY IF EXISTS "Users can create messages in their choir" ON messages;
    DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
    DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create RLS policies for choirs table
CREATE POLICY "Users can view choirs they are members or leaders of" ON choirs
FOR SELECT 
TO authenticated
USING (
    id IN (
        SELECT choir_id FROM choir_members WHERE user_id = auth.uid()
    ) OR 
    leader_id = auth.uid() OR 
    admin_id = auth.uid()
);

CREATE POLICY "Leaders can update their choirs" ON choirs
FOR UPDATE 
TO authenticated
USING (leader_id = auth.uid() OR admin_id = auth.uid());

CREATE POLICY "Authenticated users can create choirs" ON choirs
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

-- Create RLS policies for choir_members table
CREATE POLICY "Users can view choir members of choirs they belong to" ON choir_members
FOR SELECT 
TO authenticated
USING (
    choir_id IN (
        SELECT choir_id FROM choir_members WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Leaders can manage choir members" ON choir_members
FOR ALL 
TO authenticated
USING (
    choir_id IN (
        SELECT id FROM choirs WHERE leader_id = auth.uid() OR admin_id = auth.uid()
    )
);

CREATE POLICY "Users can join choirs" ON choir_members
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

-- Create RLS policies for attendance_sessions table
CREATE POLICY "Users can view attendance for their choirs" ON attendance_sessions
FOR SELECT 
TO authenticated
USING (
    choir_id IN (
        SELECT choir_id FROM choir_members WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Leaders can manage attendance sessions" ON attendance_sessions
FOR ALL 
TO authenticated
USING (
    choir_id IN (
        SELECT id FROM choirs WHERE leader_id = auth.uid() OR admin_id = auth.uid()
    )
);

-- Create RLS policies for attendance table
CREATE POLICY "Users can view attendance records for their choirs" ON attendance
FOR SELECT 
TO authenticated
USING (
    session_id IN (
        SELECT id FROM attendance_sessions 
        WHERE choir_id IN (
            SELECT choir_id FROM choir_members WHERE user_id = auth.uid()
        )
    )
);

CREATE POLICY "Leaders can manage attendance records" ON attendance
FOR ALL 
TO authenticated
USING (
    session_id IN (
        SELECT id FROM attendance_sessions 
        WHERE choir_id IN (
            SELECT id FROM choirs WHERE leader_id = auth.uid() OR admin_id = auth.uid()
        )
    )
);

-- Create RLS policies for payments table
CREATE POLICY "Users can view payments for their choir memberships" ON payments
FOR SELECT 
TO authenticated
USING (
    member_id IN (
        SELECT id FROM choir_members WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Leaders can manage payments for their choirs" ON payments
FOR ALL 
TO authenticated
USING (
    member_id IN (
        SELECT cm.id FROM choir_members cm
        JOIN choirs c ON cm.choir_id = c.id
        WHERE c.leader_id = auth.uid() OR c.admin_id = auth.uid()
    )
);

-- Create RLS policies for messages table
CREATE POLICY "Users can view choir messages" ON messages
FOR SELECT 
TO authenticated
USING (
    choir_id IN (
        SELECT choir_id FROM choir_members WHERE user_id = auth.uid() AND status = 'active'
    )
);

CREATE POLICY "Users can create messages in their choir" ON messages
FOR INSERT 
TO authenticated
WITH CHECK (
    sender_id = auth.uid() AND
    choir_id IN (
        SELECT choir_id FROM choir_members WHERE user_id = auth.uid() AND status = 'active'
    )
);

CREATE POLICY "Users can update their own messages" ON messages
FOR UPDATE 
TO authenticated
USING (sender_id = auth.uid());

CREATE POLICY "Users can delete their own messages" ON messages
FOR DELETE 
TO authenticated
USING (sender_id = auth.uid());

-- Create RLS policies for music table
CREATE POLICY "Anyone can view public music" ON music
FOR SELECT 
TO authenticated
USING (is_public = true);

CREATE POLICY "Choir members can view choir-specific music" ON music
FOR SELECT 
TO authenticated
USING (
    choir_id IS NULL OR 
    choir_id IN (
        SELECT choir_id FROM choir_members WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Leaders can manage music for their choirs" ON music
FOR ALL 
TO authenticated
USING (
    choir_id IS NULL OR 
    choir_id IN (
        SELECT id FROM choirs WHERE leader_id = auth.uid() OR admin_id = auth.uid()
    )
);

CREATE POLICY "Users can add public music" ON music
FOR INSERT 
TO authenticated
WITH CHECK (
    (choir_id IS NULL AND is_public = true) OR
    choir_id IN (
        SELECT choir_id FROM choir_members WHERE user_id = auth.uid()
    )
);

-- Create useful indexes for better performance
CREATE INDEX IF NOT EXISTS idx_choir_members_user_id ON choir_members(user_id);
CREATE INDEX IF NOT EXISTS idx_choir_members_choir_id ON choir_members(choir_id);
CREATE INDEX IF NOT EXISTS idx_attendance_sessions_choir_id ON attendance_sessions(choir_id);
CREATE INDEX IF NOT EXISTS idx_attendance_session_id ON attendance(session_id);
CREATE INDEX IF NOT EXISTS idx_payments_member_id ON payments(member_id);
CREATE INDEX IF NOT EXISTS idx_messages_choir_id ON messages(choir_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(type);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_active ON messages(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_music_category ON music(category);
CREATE INDEX IF NOT EXISTS idx_music_language ON music(language);
CREATE INDEX IF NOT EXISTS idx_music_choir_id ON music(choir_id);
CREATE INDEX IF NOT EXISTS idx_music_is_public ON music(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_music_created_at ON music(created_at DESC);

-- Success message
SELECT 'Database setup completed successfully! All tables and policies are ready.' as status;