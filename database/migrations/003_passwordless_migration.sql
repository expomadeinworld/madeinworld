-- Migration 003: Passwordless Authentication Implementation
-- This migration implements passwordless authentication by:
-- 1. Making password_hash nullable in users table (backward compatible)
-- 2. Creating user verification tables similar to admin verification system
-- 3. Adding proper indexes for performance
-- 4. Adding last_login tracking for user management

-- Start transaction
BEGIN;

-- 1. Make password_hash nullable in users table (backward compatible)
-- This allows existing users to keep their passwords while new users can be passwordless
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- 2. Add last_login timestamp to users table for admin panel user management
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP WITH TIME ZONE;

-- 3. Create user_verification_codes table (similar to admin_verification_codes)
CREATE TABLE IF NOT EXISTS user_verification_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    code_hash VARCHAR(255) NOT NULL,
    attempts INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT false,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. Create user_rate_limits table (similar to admin_rate_limits)
CREATE TABLE IF NOT EXISTS user_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address VARCHAR(45) NOT NULL,
    request_count INTEGER DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5. Create indexes for performance optimization
-- Index for email and expiration lookup (most common query)
CREATE INDEX IF NOT EXISTS idx_user_verification_email_expires
ON user_verification_codes(email, expires_at);

-- Index for IP address and creation time (security monitoring)
CREATE INDEX IF NOT EXISTS idx_user_verification_ip_created
ON user_verification_codes(ip_address, created_at);

-- Index for rate limiting by IP and time window
CREATE INDEX IF NOT EXISTS idx_user_rate_limits_ip_window
ON user_rate_limits(ip_address, window_start);

-- Index for user email lookup (frequently used)
CREATE INDEX IF NOT EXISTS idx_users_email_lookup
ON users(email) WHERE email IS NOT NULL;

-- Index for last_login tracking (admin panel user management)
CREATE INDEX IF NOT EXISTS idx_users_last_login
ON users(last_login) WHERE last_login IS NOT NULL;

-- 6. Add comments for documentation
COMMENT ON TABLE user_verification_codes IS 'Stores email verification codes for passwordless user authentication';
COMMENT ON TABLE user_rate_limits IS 'Rate limiting for user verification code requests by IP address';
COMMENT ON COLUMN users.password_hash IS 'Password hash - nullable for passwordless authentication (legacy users may still have passwords)';
COMMENT ON COLUMN users.last_login IS 'Timestamp of user last successful login for admin panel user management';

-- 7. Create cleanup function for expired user verification codes
CREATE OR REPLACE FUNCTION cleanup_expired_user_verification_codes()
RETURNS void AS $$
BEGIN
    -- Remove expired verification codes (older than 1 hour after expiration)
    DELETE FROM user_verification_codes
    WHERE expires_at < now() - interval '1 hour';
    
    -- Remove old rate limit records (older than 24 hours)
    DELETE FROM user_rate_limits
    WHERE window_start < now() - interval '24 hours';
    
    -- Log cleanup activity
    RAISE NOTICE 'Cleaned up expired user verification codes and old rate limits at %', now();
END;
$$ LANGUAGE plpgsql;

-- 8. Add constraint to ensure email uniqueness (if not already exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'users_email_key'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_email_key UNIQUE (email);
    END IF;
END $$;

-- 9. Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to users table if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_users_updated_at'
    ) THEN
        CREATE TRIGGER update_users_updated_at
            BEFORE UPDATE ON users
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- 10. Grant necessary permissions (adjust as needed for your setup)
-- These grants ensure the auth service can access the new tables
-- Note: Adjust the user name based on your database setup
DO $$
BEGIN
    -- Grant permissions to current user (usually the database owner)
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON user_verification_codes TO %I', current_user);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON user_rate_limits TO %I', current_user);

    -- Grant permissions to common database users if they exist
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
        GRANT SELECT, INSERT, UPDATE, DELETE ON user_verification_codes TO postgres;
        GRANT SELECT, INSERT, UPDATE, DELETE ON user_rate_limits TO postgres;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'madeinworld') THEN
        GRANT SELECT, INSERT, UPDATE, DELETE ON user_verification_codes TO madeinworld;
        GRANT SELECT, INSERT, UPDATE, DELETE ON user_rate_limits TO madeinworld;
    END IF;
END $$;

-- Commit transaction
COMMIT;

-- Verification queries to confirm migration success
-- (These are comments for manual verification after running migration)
/*
-- Verify password_hash is now nullable
SELECT column_name, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'password_hash';

-- Verify new tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('user_verification_codes', 'user_rate_limits');

-- Verify indexes were created
SELECT indexname FROM pg_indexes 
WHERE tablename IN ('user_verification_codes', 'user_rate_limits', 'users')
AND indexname LIKE '%user%';

-- Test cleanup function
SELECT cleanup_expired_user_verification_codes();
*/
