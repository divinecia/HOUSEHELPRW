-- Enhanced HouseHelp Database Schema for Shared Functionalities
-- This file extends the existing database with tables for shared features

-- ===========================================
-- EMERGENCY SYSTEM TABLES
-- ===========================================

-- Emergency contacts table
CREATE TABLE emergency_contacts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    number VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'General',
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Emergency call logs
CREATE TABLE emergency_call_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    contact_id UUID REFERENCES emergency_contacts(id),
    user_id UUID REFERENCES auth.users(id),
    user_role VARCHAR(20),
    notes TEXT,
    called_at TIMESTAMPTZ DEFAULT NOW()
);

-- Emergency reports
CREATE TABLE emergency_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    user_role VARCHAR(20) NOT NULL,
    emergency_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    contact_used VARCHAR(20),
    location TEXT,
    evidence_urls TEXT[],
    status VARCHAR(20) DEFAULT 'submitted',
    admin_notes TEXT,
    reviewed_by UUID REFERENCES auth.users(id),
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ
);

-- ===========================================
-- NOTIFICATION SYSTEM TABLES
-- ===========================================

-- FCM tokens table for push notifications
CREATE TABLE fcm_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    token TEXT NOT NULL UNIQUE,
    device_type VARCHAR(20) NOT NULL,
    device_id VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification history
CREATE TABLE notification_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'general',
    data JSONB,
    status VARCHAR(20) DEFAULT 'sent',
    read_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- Topic subscriptions for FCM
CREATE TABLE topic_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    topic VARCHAR(100) NOT NULL,
    subscribed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, topic)
);

-- ===========================================
-- SECURITY & AUDIT TABLES
-- ===========================================

-- Security logs for route guard and access control
CREATE TABLE security_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    event_type VARCHAR(50) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Session tracking
CREATE TABLE user_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    session_token TEXT NOT NULL,
    device_info JSONB,
    ip_address INET,
    location_info JSONB,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    last_activity TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true
);

-- ===========================================
-- SYSTEM CONFIGURATION TABLES
-- ===========================================

-- System settings for admin configuration
CREATE TABLE system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value JSONB NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'general',
    is_public BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User preferences for localization and notifications
CREATE TABLE user_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL UNIQUE,
    language VARCHAR(5) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'Africa/Kigali',
    notification_settings JSONB DEFAULT '{}',
    privacy_settings JSONB DEFAULT '{}',
    accessibility_settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================
-- INDEXES FOR PERFORMANCE
-- ===========================================

-- Emergency system indexes
CREATE INDEX idx_emergency_contacts_category ON emergency_contacts(category);
CREATE INDEX idx_emergency_contacts_active ON emergency_contacts(is_active);
CREATE INDEX idx_emergency_call_logs_user ON emergency_call_logs(user_id);
CREATE INDEX idx_emergency_call_logs_date ON emergency_call_logs(called_at);
CREATE INDEX idx_emergency_reports_user ON emergency_reports(user_id);
CREATE INDEX idx_emergency_reports_status ON emergency_reports(status);
CREATE INDEX idx_emergency_reports_date ON emergency_reports(reported_at);

-- Notification system indexes
CREATE INDEX idx_fcm_tokens_user ON fcm_tokens(user_id);
CREATE INDEX idx_fcm_tokens_active ON fcm_tokens(is_active);
CREATE INDEX idx_notification_history_user ON notification_history(user_id);
CREATE INDEX idx_notification_history_type ON notification_history(type);
CREATE INDEX idx_notification_history_date ON notification_history(sent_at);
CREATE INDEX idx_topic_subscriptions_user ON topic_subscriptions(user_id);
CREATE INDEX idx_topic_subscriptions_topic ON topic_subscriptions(topic);

-- Security system indexes
CREATE INDEX idx_security_logs_user ON security_logs(user_id);
CREATE INDEX idx_security_logs_event ON security_logs(event_type);
CREATE INDEX idx_security_logs_date ON security_logs(created_at);
CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active);
CREATE INDEX idx_user_sessions_activity ON user_sessions(last_activity);

-- System configuration indexes
CREATE INDEX idx_system_settings_key ON system_settings(setting_key);
CREATE INDEX idx_system_settings_category ON system_settings(category);
CREATE INDEX idx_user_preferences_user ON user_preferences(user_id);

-- ===========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ===========================================

-- Enable RLS on all tables
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Emergency contacts: Public read, admin write
CREATE POLICY "Emergency contacts are viewable by all authenticated users"
    ON emergency_contacts FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Emergency contacts are manageable by admins"
    ON emergency_contacts FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Emergency call logs: Users can view their own, admins can view all
CREATE POLICY "Users can view their own emergency call logs"
    ON emergency_call_logs FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Admins can view all emergency call logs"
    ON emergency_call_logs FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Users can insert their own emergency call logs"
    ON emergency_call_logs FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Emergency reports: Users can manage their own, admins can manage all
CREATE POLICY "Users can manage their own emergency reports"
    ON emergency_reports FOR ALL
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all emergency reports"
    ON emergency_reports FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- FCM tokens: Users can manage their own
CREATE POLICY "Users can manage their own FCM tokens"
    ON fcm_tokens FOR ALL
    TO authenticated
    USING (user_id = auth.uid());

-- Notification history: Users can view their own
CREATE POLICY "Users can view their own notification history"
    ON notification_history FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "System can insert notifications"
    ON notification_history FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Topic subscriptions: Users can manage their own
CREATE POLICY "Users can manage their own topic subscriptions"
    ON topic_subscriptions FOR ALL
    TO authenticated
    USING (user_id = auth.uid());

-- Security logs: Admins only
CREATE POLICY "Admins can view all security logs"
    ON security_logs FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "System can insert security logs"
    ON security_logs FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- User sessions: Users can view their own, admins can view all
CREATE POLICY "Users can view their own sessions"
    ON user_sessions FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Admins can view all sessions"
    ON user_sessions FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "System can manage user sessions"
    ON user_sessions FOR ALL
    TO authenticated
    USING (true);

-- System settings: Public read for public settings, admin write
CREATE POLICY "Public system settings are viewable by all"
    ON system_settings FOR SELECT
    TO authenticated
    USING (is_public = true);

CREATE POLICY "Admins can view all system settings"
    ON system_settings FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can manage system settings"
    ON system_settings FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- User preferences: Users can manage their own
CREATE POLICY "Users can manage their own preferences"
    ON user_preferences FOR ALL
    TO authenticated
    USING (user_id = auth.uid());

-- ===========================================
-- FUNCTIONS AND TRIGGERS
-- ===========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_emergency_contacts_updated_at BEFORE UPDATE ON emergency_contacts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to clean up old notification history (keep last 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
    DELETE FROM notification_history 
    WHERE sent_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Function to clean up inactive FCM tokens
CREATE OR REPLACE FUNCTION cleanup_inactive_fcm_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM fcm_tokens 
    WHERE is_active = false 
    AND last_used_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- DEFAULT DATA INSERTION
-- ===========================================

-- Insert default emergency contacts
INSERT INTO emergency_contacts (name, number, category, description) VALUES
('General Emergency', '112', 'General', 'Universal access for life-threatening emergencies'),
('RIB - Crime Info', '166', 'Crime', 'Report threats, harassment, or criminal acts'),
('Gender-Based Violence', '3512', 'Violence', 'Report abuse, GBV, or exploitation at workplace/home'),
('Child Help Line', '116', 'Support', 'For households involving child workers or abuse cases'),
('Isange One Stop Center', '3029', 'Support', 'For physical or psychological abuse (trauma care)'),
('Abuse by Police Officer', '3511', 'Crime', 'In case of intimidation or misconduct during verification'),
('RIB Dissatisfaction', '2040', 'Support', 'If user feels RIB handled a case poorly'),
('Traffic Police', '118', 'Traffic', 'Report incidents while in transit to jobs'),
('Anti-Corruption', '997', 'Crime', 'Report bribery in hiring, training, or app moderation'),
('REG – Customer Service', '2727', 'Utility', 'Report utility issues when tied to job conditions'),
('Traffic Accident', '113', 'Traffic', 'Report while commuting for work');

-- Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, description, category, is_public) VALUES
('app_version', '"1.0.0"', 'Current app version', 'general', true),
('maintenance_mode', 'false', 'Enable maintenance mode', 'general', true),
('supported_languages', '["en", "rw", "fr", "sw"]', 'Supported application languages', 'localization', true),
('default_language', '"en"', 'Default application language', 'localization', true),
('notification_enabled', 'true', 'Enable push notifications', 'notifications', false),
('max_file_upload_size', '10485760', 'Maximum file upload size in bytes (10MB)', 'uploads', false),
('emergency_auto_initialize', 'true', 'Auto-initialize emergency contacts on first run', 'emergency', false);

-- ===========================================
-- VIEWS FOR REPORTING
-- ===========================================

-- Emergency statistics view
CREATE VIEW emergency_statistics AS
SELECT 
    COUNT(*) as total_reports,
    COUNT(CASE WHEN status = 'submitted' THEN 1 END) as pending_reports,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_reports,
    COUNT(CASE WHEN reported_at >= NOW() - INTERVAL '24 hours' THEN 1 END) as reports_last_24h,
    COUNT(CASE WHEN reported_at >= NOW() - INTERVAL '7 days' THEN 1 END) as reports_last_week
FROM emergency_reports;

-- Notification statistics view
CREATE VIEW notification_statistics AS
SELECT 
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN read_at IS NOT NULL THEN 1 END) as read_notifications,
    COUNT(CASE WHEN sent_at >= NOW() - INTERVAL '24 hours' THEN 1 END) as sent_last_24h,
    type,
    COUNT(*) as count_by_type
FROM notification_history
GROUP BY type;

-- Security events view
CREATE VIEW security_events AS
SELECT 
    event_type,
    COUNT(*) as event_count,
    COUNT(CASE WHEN created_at >= NOW() - INTERVAL '24 hours' THEN 1 END) as events_last_24h,
    MAX(created_at) as last_occurrence
FROM security_logs
GROUP BY event_type
ORDER BY event_count DESC;

-- ===========================================
-- SCHEDULED CLEANUP (requires pg_cron extension)
-- ===========================================

-- Note: These require the pg_cron extension to be enabled
-- Uncomment if pg_cron is available:

-- Clean up old notifications daily at 2 AM
-- SELECT cron.schedule('cleanup-notifications', '0 2 * * *', 'SELECT cleanup_old_notifications();');

-- Clean up inactive FCM tokens weekly
-- SELECT cron.schedule('cleanup-fcm-tokens', '0 3 * * 0', 'SELECT cleanup_inactive_fcm_tokens();');

-- ===========================================
-- COMMENTS
-- ===========================================

COMMENT ON TABLE emergency_contacts IS 'Rwanda emergency contact numbers for the HouseHelp app';
COMMENT ON TABLE emergency_call_logs IS 'Log of emergency calls made by users';
COMMENT ON TABLE emergency_reports IS 'Emergency reports submitted by users';
COMMENT ON TABLE fcm_tokens IS 'Firebase Cloud Messaging tokens for push notifications';
COMMENT ON TABLE notification_history IS 'History of all notifications sent to users';
COMMENT ON TABLE topic_subscriptions IS 'FCM topic subscriptions for users';
COMMENT ON TABLE security_logs IS 'Security and audit logs for the application';
COMMENT ON TABLE user_sessions IS 'Active and historical user sessions';
COMMENT ON TABLE system_settings IS 'System-wide configuration settings';
COMMENT ON TABLE user_preferences IS 'User-specific preferences and settings';
