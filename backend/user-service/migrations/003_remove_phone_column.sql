-- Migration: Remove phone column from users table
-- This migration removes the phone column as it's no longer needed in the admin panel

-- Remove the phone column
ALTER TABLE users DROP COLUMN IF EXISTS phone;
