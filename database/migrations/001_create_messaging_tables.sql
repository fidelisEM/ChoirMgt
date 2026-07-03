-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum for message types
CREATE TYPE message_type AS ENUM ('announcement', 'discussion', 'reminder', 'urgent');

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  choir_id UUID NOT NULL REFERENCES choirs(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_name VARCHAR(255) NOT NULL,
  subject VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  type message_type NOT NULL DEFAULT 'discussion',
  recipients UUID[], -- Empty array means all members
  read_by UUID[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  CONSTRAINT subject_not_empty CHECK (length(trim(subject)) > 0),
  CONSTRAINT content_not_empty CHECK (length(trim(content)) > 0)
);

-- Create message replies table for threading
CREATE TABLE IF NOT EXISTS message_replies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  parent_reply_id UUID REFERENCES message_replies(id) ON DELETE CASCADE, -- For nested replies
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_name VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  read_by UUID[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  CONSTRAINT content_not_empty CHECK (length(trim(content)) > 0)
);

-- Create message attachments table (for future use)
CREATE TABLE IF NOT EXISTS message_attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  reply_id UUID REFERENCES message_replies(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  file_size INTEGER NOT NULL,
  file_type VARCHAR(100) NOT NULL,
  uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure attachment belongs to either message or reply, not both
  CONSTRAINT attachment_parent_check CHECK (
    (message_id IS NOT NULL AND reply_id IS NULL) OR 
    (message_id IS NULL AND reply_id IS NOT NULL)
  )
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_choir_id ON messages(choir_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(type);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_active ON messages(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_message_replies_message_id ON message_replies(message_id);
CREATE INDEX IF NOT EXISTS idx_message_replies_sender_id ON message_replies(sender_id);
CREATE INDEX IF NOT EXISTS idx_message_replies_created_at ON message_replies(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_message_replies_parent ON message_replies(parent_reply_id);

CREATE INDEX IF NOT EXISTS idx_message_attachments_message_id ON message_attachments(message_id);
CREATE INDEX IF NOT EXISTS idx_message_attachments_reply_id ON message_attachments(reply_id);

-- Create functions for message operations
CREATE OR REPLACE FUNCTION update_message_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_messages_updated_at ON messages;
CREATE TRIGGER trigger_messages_updated_at
  BEFORE UPDATE ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_message_timestamp();

DROP TRIGGER IF EXISTS trigger_message_replies_updated_at ON message_replies;
CREATE TRIGGER trigger_message_replies_updated_at
  BEFORE UPDATE ON message_replies
  FOR EACH ROW
  EXECUTE FUNCTION update_message_timestamp();

-- Create function to mark message as read
CREATE OR REPLACE FUNCTION mark_message_as_read(
  message_uuid UUID,
  user_uuid UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE messages 
  SET read_by = array_append(read_by, user_uuid)
  WHERE id = message_uuid 
    AND NOT (user_uuid = ANY(read_by))
    AND is_active = true;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to mark reply as read
CREATE OR REPLACE FUNCTION mark_reply_as_read(
  reply_uuid UUID,
  user_uuid UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE message_replies 
  SET read_by = array_append(read_by, user_uuid)
  WHERE id = reply_uuid 
    AND NOT (user_uuid = ANY(read_by))
    AND is_active = true;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get unread message count for a user
CREATE OR REPLACE FUNCTION get_unread_message_count(
  choir_uuid UUID,
  user_uuid UUID
)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM messages m
    WHERE m.choir_id = choir_uuid
      AND m.is_active = true
      AND m.sender_id != user_uuid
      AND NOT (user_uuid = ANY(m.read_by))
      AND (
        array_length(m.recipients, 1) IS NULL -- All members
        OR user_uuid = ANY(m.recipients) -- Specific recipients
      )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create Row Level Security policies
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_attachments ENABLE ROW LEVEL SECURITY;

-- Messages RLS policies
DROP POLICY IF EXISTS "Users can view choir messages" ON messages;
CREATE POLICY "Users can view choir messages" ON messages
  FOR SELECT USING (
    auth.uid() IN (
      SELECT cm.user_id 
      FROM choir_members cm 
      WHERE cm.choir_id = messages.choir_id 
        AND cm.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Users can create messages in their choir" ON messages;
CREATE POLICY "Users can create messages in their choir" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    auth.uid() IN (
      SELECT cm.user_id 
      FROM choir_members cm 
      WHERE cm.choir_id = messages.choir_id 
        AND cm.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
CREATE POLICY "Users can update their own messages" ON messages
  FOR UPDATE USING (
    auth.uid() = sender_id
  );

DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;
CREATE POLICY "Users can delete their own messages" ON messages
  FOR DELETE USING (
    auth.uid() = sender_id
  );

-- Message replies RLS policies
DROP POLICY IF EXISTS "Users can view message replies" ON message_replies;
CREATE POLICY "Users can view message replies" ON message_replies
  FOR SELECT USING (
    auth.uid() IN (
      SELECT cm.user_id 
      FROM choir_members cm 
      JOIN messages m ON m.choir_id = cm.choir_id
      WHERE m.id = message_replies.message_id 
        AND cm.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Users can create replies" ON message_replies;
CREATE POLICY "Users can create replies" ON message_replies
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    auth.uid() IN (
      SELECT cm.user_id 
      FROM choir_members cm 
      JOIN messages m ON m.choir_id = cm.choir_id
      WHERE m.id = message_replies.message_id 
        AND cm.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Users can update their own replies" ON message_replies;
CREATE POLICY "Users can update their own replies" ON message_replies
  FOR UPDATE USING (
    auth.uid() = sender_id
  );

DROP POLICY IF EXISTS "Users can delete their own replies" ON message_replies;
CREATE POLICY "Users can delete their own replies" ON message_replies
  FOR DELETE USING (
    auth.uid() = sender_id
  );

-- Message attachments RLS policies
DROP POLICY IF EXISTS "Users can view attachments" ON message_attachments;
CREATE POLICY "Users can view attachments" ON message_attachments
  FOR SELECT USING (
    auth.uid() IN (
      SELECT cm.user_id 
      FROM choir_members cm 
      JOIN messages m ON m.choir_id = cm.choir_id
      WHERE (m.id = message_attachments.message_id OR 
             m.id IN (SELECT mr.message_id FROM message_replies mr WHERE mr.id = message_attachments.reply_id))
        AND cm.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Users can upload attachments" ON message_attachments;
CREATE POLICY "Users can upload attachments" ON message_attachments
  FOR INSERT WITH CHECK (
    auth.uid() = uploaded_by
  );

DROP POLICY IF EXISTS "Users can delete their own attachments" ON message_attachments;
CREATE POLICY "Users can delete their own attachments" ON message_attachments
  FOR DELETE USING (
    auth.uid() = uploaded_by
  );

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON message_replies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON message_attachments TO authenticated;
GRANT EXECUTE ON FUNCTION mark_message_as_read(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_reply_as_read(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_message_count(UUID, UUID) TO authenticated;