-- Migration: Add User Management Fields to Users Table
-- Date: 2025-08-07
-- Description: This migration adds the missing fields (role, status, last_login) 
--              to the main users table to support complete CRUD functionality
--              in the admin panel user management system.

-- Add role field to users table
ALTER TABLE users 
ADD COLUMN role public.user_role DEFAULT 'Customer' NOT NULL;

-- Add status field to users table (using varchar for flexibility)
ALTER TABLE users 
ADD COLUMN status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- Add last_login field to users table
ALTER TABLE users 
ADD COLUMN last_login TIMESTAMP WITH TIME ZONE;

-- Add constraint to ensure valid status values
ALTER TABLE users 
ADD CONSTRAINT users_status_check 
CHECK (status IN ('active', 'deactivated'));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_last_login ON users(last_login);

-- Update existing users to have proper default values
UPDATE users 
SET role = 'Customer', status = 'active' 
WHERE role IS NULL OR status IS NULL;

-- Add comment to document the changes
COMMENT ON COLUMN users.role IS 'User role: Customer, Admin, Manufacturer, 3PL, Partner';
COMMENT ON COLUMN users.status IS 'User account status: active, deactivated';
COMMENT ON COLUMN users.last_login IS 'Timestamp of user last login';
