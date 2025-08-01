-- HOUSEHELP Admin Panel Database Schema
-- Run these commands in your Supabase SQL editor to set up the enhanced admin features

-- 1. Trainings table for training management
CREATE TABLE trainings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(255) NOT NULL,
    is_mandatory BOOLEAN DEFAULT FALSE,
    is_paid BOOLEAN DEFAULT FALSE,
    cost DECIMAL(10,2),
    max_participants INTEGER DEFAULT 20,
    instructor_id UUID,
    instructor_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'scheduled',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    prerequisites TEXT[],
    category VARCHAR(100),
    
    CONSTRAINT valid_status CHECK (status IN ('scheduled', 'inProgress', 'completed', 'cancelled', 'postponed')),
    CONSTRAINT valid_cost CHECK (cost IS NULL OR cost >= 0),
    CONSTRAINT valid_participants CHECK (max_participants > 0)
);

-- 2. Training participations table
CREATE TABLE training_participations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    training_id UUID REFERENCES trainings(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL,
    worker_name VARCHAR(255) NOT NULL,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'requested',
    completed_at TIMESTAMP WITH TIME ZONE,
    score DECIMAL(5,2),
    certificate_issued BOOLEAN DEFAULT FALSE,
    feedback TEXT,
    payment_required BOOLEAN DEFAULT FALSE,
    payment_completed BOOLEAN DEFAULT FALSE,
    payment_id UUID,
    
    CONSTRAINT valid_participation_status CHECK (status IN ('requested', 'approved', 'rejected', 'inProgress', 'completed', 'failed', 'cancelled')),
    CONSTRAINT valid_score CHECK (score IS NULL OR (score >= 0 AND score <= 100)),
    UNIQUE(training_id, worker_id)
);

-- 3. Behavior reports table
CREATE TABLE behavior_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reported_worker_id UUID NOT NULL,
    reported_worker_name VARCHAR(255) NOT NULL,
    reporter_household_id UUID NOT NULL,
    reporter_household_name VARCHAR(255) NOT NULL,
    incident_description TEXT NOT NULL,
    severity VARCHAR(50) NOT NULL,
    incident_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(255) NOT NULL,
    evidence_urls TEXT[],
    status VARCHAR(50) DEFAULT 'pending',
    reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    admin_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by VARCHAR(255),
    email_sent_to_isange BOOLEAN DEFAULT FALSE,
    email_sent_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_severity CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT valid_report_status CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed', 'escalated'))
);

-- 4. Fix messages table for system issues
CREATE TABLE fix_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID NOT NULL,
    reporter_name VARCHAR(255) NOT NULL,
    reporter_role VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    priority VARCHAR(50) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'pending',
    reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_to VARCHAR(255),
    assigned_at TIMESTAMP WITH TIME ZONE,
    admin_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution TEXT,
    attachments TEXT[],
    
    CONSTRAINT valid_reporter_role CHECK (reporter_role IN ('admin', 'house_helper', 'house_holder')),
    CONSTRAINT valid_fix_type CHECK (type IN ('bug', 'featureRequest', 'improvement', 'question', 'other')),
    CONSTRAINT valid_priority CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    CONSTRAINT valid_fix_status CHECK (status IN ('pending', 'inProgress', 'resolved', 'dismissed', 'needsMoreInfo'))
);

-- 5. System settings table
CREATE TABLE system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    default_language VARCHAR(10) DEFAULT 'en',
    tax_rate DECIMAL(5,4) DEFAULT 0.18,
    service_fee_percentage DECIMAL(5,4) DEFAULT 0.05,
    benefits_options JSONB DEFAULT '{}',
    notification_settings JSONB DEFAULT '{}',
    payment_settings JSONB DEFAULT '{}',
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by VARCHAR(255) NOT NULL,
    
    CONSTRAINT valid_tax_rate CHECK (tax_rate >= 0 AND tax_rate <= 1),
    CONSTRAINT valid_service_fee CHECK (service_fee_percentage >= 0 AND service_fee_percentage <= 1)
);

-- 6. Enhanced payments table (if not exists, modify existing)
-- Add payment_type column to distinguish service vs training payments
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS payment_type VARCHAR(50) DEFAULT 'service',
ADD CONSTRAINT valid_payment_type CHECK (payment_type IN ('service', 'training'));

-- 7. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_trainings_status ON trainings(status);
CREATE INDEX IF NOT EXISTS idx_trainings_start_date ON trainings(start_date);
CREATE INDEX IF NOT EXISTS idx_training_participations_training_id ON training_participations(training_id);
CREATE INDEX IF NOT EXISTS idx_training_participations_worker_id ON training_participations(worker_id);
CREATE INDEX IF NOT EXISTS idx_training_participations_status ON training_participations(status);
CREATE INDEX IF NOT EXISTS idx_behavior_reports_status ON behavior_reports(status);
CREATE INDEX IF NOT EXISTS idx_behavior_reports_severity ON behavior_reports(severity);
CREATE INDEX IF NOT EXISTS idx_behavior_reports_reported_at ON behavior_reports(reported_at);
CREATE INDEX IF NOT EXISTS idx_fix_messages_status ON fix_messages(status);
CREATE INDEX IF NOT EXISTS idx_fix_messages_priority ON fix_messages(priority);
CREATE INDEX IF NOT EXISTS idx_fix_messages_reported_at ON fix_messages(reported_at);

-- 8. Row Level Security (RLS) Policies

-- Enable RLS on all new tables
ALTER TABLE trainings ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE fix_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Admin-only access to trainings management
CREATE POLICY "Admin full access to trainings" ON trainings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Workers can view trainings and request participation
CREATE POLICY "Workers can view trainings" ON trainings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'house_helper'
        )
    );

-- Training participations: workers can create, admins can manage
CREATE POLICY "Workers can request training participation" ON training_participations
    FOR INSERT WITH CHECK (
        worker_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'house_helper'
        )
    );

CREATE POLICY "Admin and worker can view their participations" ON training_participations
    FOR SELECT USING (
        worker_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admin can update participations" ON training_participations
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Behavior reports: households can create, admins can manage
CREATE POLICY "Households can create behavior reports" ON behavior_reports
    FOR INSERT WITH CHECK (
        reporter_household_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'house_holder'
        )
    );

CREATE POLICY "Admin and reporter can view reports" ON behavior_reports
    FOR SELECT USING (
        reporter_household_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admin can update behavior reports" ON behavior_reports
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Fix messages: all users can create, admins can manage
CREATE POLICY "Users can create fix messages" ON fix_messages
    FOR INSERT WITH CHECK (
        reporter_id = auth.uid()
    );

CREATE POLICY "Users can view their own fix messages" ON fix_messages
    FOR SELECT USING (
        reporter_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admin can update fix messages" ON fix_messages
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- System settings: Admin only
CREATE POLICY "Admin only access to system settings" ON system_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 9. Functions for analytics (optional - can be implemented in app logic)

-- Function to get monthly training statistics
CREATE OR REPLACE FUNCTION get_monthly_training_stats()
RETURNS TABLE (
    month_year TEXT,
    total_trainings BIGINT,
    completed_trainings BIGINT,
    total_participants BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(t.start_date, 'YYYY-MM') as month_year,
        COUNT(t.id) as total_trainings,
        COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_trainings,
        COUNT(tp.id) as total_participants
    FROM trainings t
    LEFT JOIN training_participations tp ON t.id = tp.training_id
    WHERE t.start_date >= NOW() - INTERVAL '12 months'
    GROUP BY TO_CHAR(t.start_date, 'YYYY-MM')
    ORDER BY month_year;
END;
$$;

-- Function to get revenue analytics
CREATE OR REPLACE FUNCTION get_revenue_analytics()
RETURNS TABLE (
    month_year TEXT,
    service_revenue DECIMAL,
    training_revenue DECIMAL,
    total_revenue DECIMAL
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(p.created_at, 'YYYY-MM') as month_year,
        SUM(CASE WHEN p.payment_type = 'service' THEN p.amount ELSE 0 END) as service_revenue,
        SUM(CASE WHEN p.payment_type = 'training' THEN p.amount ELSE 0 END) as training_revenue,
        SUM(p.amount) as total_revenue
    FROM payments p
    WHERE p.created_at >= NOW() - INTERVAL '12 months'
    AND p.status = 'completed'
    GROUP BY TO_CHAR(p.created_at, 'YYYY-MM')
    ORDER BY month_year;
END;
$$;

-- 10. Insert default system settings
INSERT INTO system_settings (
    default_language,
    tax_rate,
    service_fee_percentage,
    benefits_options,
    notification_settings,
    payment_settings,
    updated_by
) VALUES (
    'en',
    0.18,
    0.05,
    '{"ejo_heza": false, "insurance": false}',
    '{"email": true, "push": true, "sms": false}',
    '{"minimum_payment": 1000, "maximum_payment": 500000, "supported_providers": ["MTN", "Airtel"]}',
    'System'
) ON CONFLICT DO NOTHING;

-- 11. Create triggers for updated_at fields
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_trainings_updated_at BEFORE UPDATE ON trainings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 12. Grant necessary permissions (adjust based on your Supabase setup)
-- These are typically handled by Supabase automatically, but you can run them if needed

-- GRANT USAGE ON SCHEMA public TO authenticated;
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

COMMENT ON TABLE trainings IS 'Training sessions management for house helpers';
COMMENT ON TABLE training_participations IS 'Worker participation in training sessions';
COMMENT ON TABLE behavior_reports IS 'Reports submitted by households about worker behavior';
COMMENT ON TABLE fix_messages IS 'System issues and feature requests from users';
COMMENT ON TABLE system_settings IS 'Global application configuration settings';
