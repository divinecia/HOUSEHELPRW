-- HouseHelp Complete Database Schema
-- Run this SQL in your Supabase SQL editor to set up the complete database

-- ===========================================
-- ENABLE EXTENSIONS
-- ===========================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===========================================
-- USER PROFILES AND ROLES
-- ===========================================

-- User profiles table (extends auth.users)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'house_helper', 'household')),
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    profile_completion INTEGER DEFAULT 0,
    avatar_url TEXT,
    date_of_birth DATE,
    gender VARCHAR(10),
    address TEXT,
    district VARCHAR(100),
    sector VARCHAR(100),
    cell VARCHAR(100),
    village VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- House Helper specific profiles
CREATE TABLE house_helper_profiles (
    id UUID REFERENCES profiles(id) PRIMARY KEY,
    skills TEXT[],
    experience_years INTEGER DEFAULT 0,
    hourly_rate DECIMAL(10,2),
    availability JSONB DEFAULT '{}',
    languages TEXT[] DEFAULT ARRAY['en', 'rw'],
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    national_id VARCHAR(20),
    references JSONB DEFAULT '[]',
    background_check_status VARCHAR(20) DEFAULT 'pending',
    rating DECIMAL(3,2) DEFAULT 0.0,
    total_jobs INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Household specific profiles
CREATE TABLE household_profiles (
    id UUID REFERENCES profiles(id) PRIMARY KEY,
    household_size INTEGER DEFAULT 1,
    children_count INTEGER DEFAULT 0,
    pets_count INTEGER DEFAULT 0,
    special_requirements TEXT,
    preferred_languages TEXT[] DEFAULT ARRAY['en', 'rw'],
    budget_range JSONB DEFAULT '{}',
    location_details TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================
-- HIRING AND JOBS
-- ===========================================

-- Hiring requests
CREATE TABLE hiring_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID REFERENCES profiles(id) NOT NULL,
    worker_id UUID REFERENCES profiles(id),
    service_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    location TEXT NOT NULL,
    district VARCHAR(100),
    sector VARCHAR(100),
    start_date DATE NOT NULL,
    end_date DATE,
    start_time TIME,
    end_time TIME,
    hourly_rate DECIMAL(10,2) NOT NULL,
    total_hours INTEGER,
    total_amount DECIMAL(10,2),
    special_requirements TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Job applications
CREATE TABLE job_applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    hiring_request_id UUID REFERENCES hiring_requests(id) NOT NULL,
    worker_id UUID REFERENCES profiles(id) NOT NULL,
    application_message TEXT,
    proposed_rate DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    UNIQUE(hiring_request_id, worker_id)
);

-- ===========================================
-- PAYMENTS
-- ===========================================

-- Payments table
CREATE TABLE payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    payer_id UUID REFERENCES profiles(id) NOT NULL,
    receiver_id UUID REFERENCES profiles(id) NOT NULL,
    hiring_request_id UUID REFERENCES hiring_requests(id),
    training_enrollment_id UUID,
    amount DECIMAL(10,2) NOT NULL,
    fee DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_reference VARCHAR(255),
    transaction_id VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('service', 'training', 'fee', 'refund')),
    purpose TEXT,
    paypack_ref VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- ===========================================
-- TRAINING SYSTEM
-- ===========================================

-- Training programs
CREATE TABLE training_programs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    level VARCHAR(20) DEFAULT 'beginner' CHECK (level IN ('beginner', 'intermediate', 'advanced')),
    duration_hours INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    instructor_name VARCHAR(255),
    instructor_bio TEXT,
    syllabus JSONB DEFAULT '[]',
    requirements TEXT[],
    certificates_issued BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    max_participants INTEGER,
    language VARCHAR(5) DEFAULT 'en',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Training enrollments
CREATE TABLE training_enrollments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    worker_id UUID REFERENCES profiles(id) NOT NULL,
    training_id UUID REFERENCES training_programs(id) NOT NULL,
    enrollment_type VARCHAR(20) DEFAULT 'self' CHECK (enrollment_type IN ('self', 'household_suggested', 'admin_suggested')),
    suggested_by_household_id UUID REFERENCES profiles(id),
    suggested_by_admin_id UUID REFERENCES profiles(id),
    status VARCHAR(20) DEFAULT 'enrolled' CHECK (status IN ('enrolled', 'in_progress', 'completed', 'dropped', 'failed')),
    progress INTEGER DEFAULT 0,
    score INTEGER,
    certificate_id VARCHAR(255),
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed')),
    UNIQUE(worker_id, training_id)
);

-- Training suggestions (from households to workers)
CREATE TABLE training_suggestions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    worker_id UUID REFERENCES profiles(id) NOT NULL,
    worker_name VARCHAR(255) NOT NULL,
    training_id UUID REFERENCES training_programs(id) NOT NULL,
    training_title VARCHAR(255) NOT NULL,
    suggested_by_household_id UUID REFERENCES profiles(id),
    suggested_by_household_name VARCHAR(255),
    suggested_by_admin_id UUID REFERENCES profiles(id),
    suggested_by_admin_name VARCHAR(255),
    notes TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'admin_suggested')),
    processed_at TIMESTAMPTZ,
    processed_by UUID REFERENCES profiles(id),
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================
-- BEHAVIOR REPORTS
-- ===========================================

-- Behavior reports
CREATE TABLE behavior_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID REFERENCES profiles(id) NOT NULL,
    reported_user_id UUID REFERENCES profiles(id) NOT NULL,
    hiring_request_id UUID REFERENCES hiring_requests(id),
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT NOT NULL,
    evidence_urls TEXT[],
    location TEXT,
    incident_date TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    admin_notes TEXT,
    action_taken TEXT,
    resolved_by UUID REFERENCES profiles(id),
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    email_sent_to_isange BOOLEAN DEFAULT false,
    email_sent_at TIMESTAMPTZ
);

-- ===========================================
-- COMMUNICATION
-- ===========================================

-- Chat conversations
CREATE TABLE chat_conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID REFERENCES profiles(id) NOT NULL,
    worker_id UUID REFERENCES profiles(id) NOT NULL,
    hiring_request_id UUID REFERENCES hiring_requests(id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'archived', 'blocked')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(household_id, worker_id, hiring_request_id)
);

-- Chat messages
CREATE TABLE chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID REFERENCES chat_conversations(id) NOT NULL,
    sender_id UUID REFERENCES profiles(id) NOT NULL,
    message TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'location')),
    file_url TEXT,
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================
-- FIX MESSAGES (Bug Reports)
-- ===========================================

-- Fix messages for bug reports and feature requests
CREATE TABLE fix_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID REFERENCES profiles(id) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'closed')),
    assigned_to UUID REFERENCES profiles(id),
    assigned_at TIMESTAMPTZ,
    resolution TEXT,
    admin_notes TEXT,
    attachments TEXT[],
    device_info JSONB,
    app_version VARCHAR(20),
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- ===========================================
-- EMERGENCY SYSTEM
-- ===========================================

-- Emergency contacts
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
-- NOTIFICATION SYSTEM
-- ===========================================

-- FCM tokens for push notifications
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
-- SECURITY & AUDIT
-- ===========================================

-- Security logs
CREATE TABLE security_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    event_type VARCHAR(50) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User sessions
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
-- SYSTEM CONFIGURATION
-- ===========================================

-- System settings
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

-- User preferences
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
-- FUNCTIONS
-- ===========================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', ''));
    
    INSERT INTO public.user_preferences (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_house_helper_profiles_updated_at BEFORE UPDATE ON house_helper_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_household_profiles_updated_at BEFORE UPDATE ON household_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_hiring_requests_updated_at BEFORE UPDATE ON hiring_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_training_programs_updated_at BEFORE UPDATE ON training_programs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chat_conversations_updated_at BEFORE UPDATE ON chat_conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_emergency_contacts_updated_at BEFORE UPDATE ON emergency_contacts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- INDEXES FOR PERFORMANCE
-- ===========================================

-- Profile indexes
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_verification ON profiles(verification_status);
CREATE INDEX idx_profiles_email ON profiles(email);

-- House helper indexes
CREATE INDEX idx_house_helper_available ON house_helper_profiles(is_available);
CREATE INDEX idx_house_helper_rating ON house_helper_profiles(rating);
CREATE INDEX idx_house_helper_location ON house_helper_profiles USING GIN ((SELECT array_agg(skill) FROM unnest(skills) AS skill));

-- Hiring request indexes
CREATE INDEX idx_hiring_requests_household ON hiring_requests(household_id);
CREATE INDEX idx_hiring_requests_worker ON hiring_requests(worker_id);
CREATE INDEX idx_hiring_requests_status ON hiring_requests(status);
CREATE INDEX idx_hiring_requests_date ON hiring_requests(start_date);

-- Payment indexes
CREATE INDEX idx_payments_payer ON payments(payer_id);
CREATE INDEX idx_payments_receiver ON payments(receiver_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_type ON payments(payment_type);

-- Training indexes
CREATE INDEX idx_training_enrollments_worker ON training_enrollments(worker_id);
CREATE INDEX idx_training_enrollments_training ON training_enrollments(training_id);
CREATE INDEX idx_training_enrollments_status ON training_enrollments(status);

-- Chat indexes
CREATE INDEX idx_chat_conversations_household ON chat_conversations(household_id);
CREATE INDEX idx_chat_conversations_worker ON chat_conversations(worker_id);
CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id);
CREATE INDEX idx_chat_messages_sender ON chat_messages(sender_id);

-- Behavior report indexes
CREATE INDEX idx_behavior_reports_reporter ON behavior_reports(reporter_id);
CREATE INDEX idx_behavior_reports_reported ON behavior_reports(reported_user_id);
CREATE INDEX idx_behavior_reports_status ON behavior_reports(status);

-- Emergency indexes
CREATE INDEX idx_emergency_contacts_category ON emergency_contacts(category);
CREATE INDEX idx_emergency_reports_user ON emergency_reports(user_id);
CREATE INDEX idx_emergency_reports_status ON emergency_reports(status);

-- Notification indexes
CREATE INDEX idx_fcm_tokens_user ON fcm_tokens(user_id);
CREATE INDEX idx_notification_history_user ON notification_history(user_id);
CREATE INDEX idx_notification_history_type ON notification_history(type);

-- ===========================================
-- ROW LEVEL SECURITY POLICIES
-- ===========================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE house_helper_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE hiring_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE fix_messages ENABLE ROW LEVEL SECURITY;
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

-- Profiles: Users can view and edit their own profile, admins can view all
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON profiles FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- House helper profiles: Public read for basic info, own edit
CREATE POLICY "House helper profiles viewable by all" ON house_helper_profiles FOR SELECT USING (true);
CREATE POLICY "House helpers can update own profile" ON house_helper_profiles FOR ALL USING (auth.uid() = id);

-- Household profiles: Own access only
CREATE POLICY "Household profiles own access" ON household_profiles FOR ALL USING (auth.uid() = id);

-- Hiring requests: Household can manage own, workers can view relevant, admins can view all
CREATE POLICY "Households can manage own hiring requests" ON hiring_requests FOR ALL USING (auth.uid() = household_id);
CREATE POLICY "Workers can view relevant hiring requests" ON hiring_requests FOR SELECT USING (
    worker_id IS NULL OR auth.uid() = worker_id
);
CREATE POLICY "Admins can view all hiring requests" ON hiring_requests FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Job applications: Workers can manage own, households can view for their requests
CREATE POLICY "Workers can manage own applications" ON job_applications FOR ALL USING (auth.uid() = worker_id);
CREATE POLICY "Households can view applications for own requests" ON job_applications FOR SELECT USING (
    EXISTS (SELECT 1 FROM hiring_requests WHERE hiring_requests.id = hiring_request_id AND hiring_requests.household_id = auth.uid())
);

-- Payments: Users can view own payments, admins can view all
CREATE POLICY "Users can view own payments" ON payments FOR SELECT USING (auth.uid() = payer_id OR auth.uid() = receiver_id);
CREATE POLICY "Admins can view all payments" ON payments FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Training programs: Public read, admin write
CREATE POLICY "Training programs public read" ON training_programs FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage training programs" ON training_programs FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Training enrollments: Workers can manage own, admins can view all
CREATE POLICY "Workers can manage own enrollments" ON training_enrollments FOR ALL USING (auth.uid() = worker_id);
CREATE POLICY "Admins can view all enrollments" ON training_enrollments FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Training suggestions: Various access patterns
CREATE POLICY "Workers can view own suggestions" ON training_suggestions FOR SELECT USING (auth.uid() = worker_id);
CREATE POLICY "Households can manage own suggestions" ON training_suggestions FOR ALL USING (auth.uid() = suggested_by_household_id);
CREATE POLICY "Admins can manage all suggestions" ON training_suggestions FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Behavior reports: Reporters can view own, reported users can view about them, admins can view all
CREATE POLICY "Users can view own reports" ON behavior_reports FOR SELECT USING (
    auth.uid() = reporter_id OR auth.uid() = reported_user_id
);
CREATE POLICY "Users can create reports" ON behavior_reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Admins can manage all reports" ON behavior_reports FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Chat conversations: Participants only
CREATE POLICY "Chat participants can access conversations" ON chat_conversations FOR ALL USING (
    auth.uid() = household_id OR auth.uid() = worker_id
);

-- Chat messages: Conversation participants only
CREATE POLICY "Chat participants can access messages" ON chat_messages FOR ALL USING (
    EXISTS (
        SELECT 1 FROM chat_conversations 
        WHERE chat_conversations.id = conversation_id 
        AND (chat_conversations.household_id = auth.uid() OR chat_conversations.worker_id = auth.uid())
    )
);

-- Fix messages: Own access and admin access
CREATE POLICY "Users can manage own fix messages" ON fix_messages FOR ALL USING (auth.uid() = reporter_id);
CREATE POLICY "Admins can manage all fix messages" ON fix_messages FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Emergency contacts: Public read, admin write
CREATE POLICY "Emergency contacts public read" ON emergency_contacts FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage emergency contacts" ON emergency_contacts FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Emergency call logs: Own access and admin access
CREATE POLICY "Users can view own emergency calls" ON emergency_call_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can log emergency calls" ON emergency_call_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can view all emergency calls" ON emergency_call_logs FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Emergency reports: Own access and admin access
CREATE POLICY "Users can manage own emergency reports" ON emergency_reports FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage all emergency reports" ON emergency_reports FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- FCM tokens: Own access only
CREATE POLICY "Users can manage own FCM tokens" ON fcm_tokens FOR ALL USING (auth.uid() = user_id);

-- Notification history: Own access only
CREATE POLICY "Users can view own notifications" ON notification_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can create notifications" ON notification_history FOR INSERT WITH CHECK (true);

-- Topic subscriptions: Own access only
CREATE POLICY "Users can manage own subscriptions" ON topic_subscriptions FOR ALL USING (auth.uid() = user_id);

-- Security logs: Admin only
CREATE POLICY "Admins can view security logs" ON security_logs FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);
CREATE POLICY "System can create security logs" ON security_logs FOR INSERT WITH CHECK (true);

-- User sessions: Own access and admin access
CREATE POLICY "Users can view own sessions" ON user_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all sessions" ON user_sessions FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);
CREATE POLICY "System can manage sessions" ON user_sessions FOR ALL USING (true);

-- System settings: Public read for public settings, admin write
CREATE POLICY "Public settings readable by all" ON system_settings FOR SELECT USING (is_public = true);
CREATE POLICY "Admins can view all settings" ON system_settings FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);
CREATE POLICY "Admins can manage settings" ON system_settings FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- User preferences: Own access only
CREATE POLICY "Users can manage own preferences" ON user_preferences FOR ALL USING (auth.uid() = user_id);

-- ===========================================
-- DEFAULT DATA
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

-- Insert sample training programs
INSERT INTO training_programs (title, description, category, level, duration_hours, price, instructor_name) VALUES
('Basic House Cleaning', 'Learn fundamental house cleaning techniques and safety protocols', 'Cleaning', 'beginner', 8, 15000, 'Sarah Mukamana'),
('Advanced Cooking Skills', 'Master cooking techniques for various cuisines', 'Cooking', 'intermediate', 12, 25000, 'Jean Baptiste'),
('Child Care Basics', 'Essential skills for caring for children safely', 'Childcare', 'beginner', 16, 30000, 'Grace Uwimana'),
('Elderly Care', 'Specialized care techniques for elderly individuals', 'Healthcare', 'intermediate', 20, 35000, 'Dr. Paul Kagame'),
('Garden Maintenance', 'Learn proper garden care and maintenance', 'Gardening', 'beginner', 6, 12000, 'Marie Nyirahabimana');

-- ===========================================
-- COMPLETION MESSAGE
-- ===========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 HouseHelp database setup completed successfully!';
    RAISE NOTICE '✅ All tables, indexes, and policies have been created';
    RAISE NOTICE '✅ Default data has been inserted';
    RAISE NOTICE '✅ Row Level Security is enabled';
    RAISE NOTICE '🚀 Your HouseHelp app is ready to use!';
END $$;
