-- Migration: Add mini_app_type to carts and orders tables for mini-app isolation
-- Date: 2025-07-11
-- Description: This migration adds mini_app_type field to carts and orders tables
--              to enable proper isolation between different mini-apps as required
--              for the Made in World app cart and order system.

-- Add mini_app_type to carts table
ALTER TABLE carts 
ADD COLUMN mini_app_type VARCHAR(50) NOT NULL DEFAULT 'RetailStore';

-- Add mini_app_type to orders table  
ALTER TABLE orders
ADD COLUMN mini_app_type VARCHAR(50) NOT NULL DEFAULT 'RetailStore';

-- Update existing carts to have proper mini_app_type (if any exist)
-- This ensures backward compatibility
UPDATE carts SET mini_app_type = 'RetailStore' WHERE mini_app_type = 'RetailStore';

-- Update existing orders to have proper mini_app_type (if any exist)
-- This ensures backward compatibility
UPDATE orders SET mini_app_type = 'RetailStore' WHERE mini_app_type = 'RetailStore';

-- Create indexes for efficient querying by user_id + mini_app_type
CREATE INDEX idx_carts_user_mini_app ON carts(user_id, mini_app_type);
CREATE INDEX idx_orders_user_mini_app ON orders(user_id, mini_app_type);

-- Create index for orders by user_id + mini_app_type + store_id (for location-based mini-apps)
CREATE INDEX idx_orders_user_mini_app_store ON orders(user_id, mini_app_type, store_id);

-- Add constraints to ensure valid mini_app_type values
ALTER TABLE carts 
ADD CONSTRAINT chk_carts_mini_app_type 
CHECK (mini_app_type IN ('RetailStore', 'UnmannedStore', 'ExhibitionSales', 'GroupBuying'));

ALTER TABLE orders 
ADD CONSTRAINT chk_orders_mini_app_type 
CHECK (mini_app_type IN ('RetailStore', 'UnmannedStore', 'ExhibitionSales', 'GroupBuying'));

-- For location-based mini-apps, store_id should not be null
-- Note: We don't enforce this as a constraint since RetailStore and GroupBuying don't need store_id
-- The application logic will handle this validation

-- Update the updated_at trigger to include the new column
-- (The trigger should already exist from init.sql, this ensures it works with new column)
