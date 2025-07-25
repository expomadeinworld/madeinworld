-- Migration: Revert to store-specific cart isolation
-- Date: 2025-07-24
-- Description: This migration reverts the multi-store cart implementation back to
--              store-specific cart isolation where each store maintains separate carts

-- First, we need to handle the existing multi-store cart data
-- For location-based mini-apps, we'll keep only the most recent entry per store
-- and remove duplicates that violate the store-specific constraint

-- Create a temporary table to identify records to keep
CREATE TEMP TABLE cart_records_to_keep AS
SELECT DISTINCT ON (user_id, product_id, mini_app_type, store_id)
    id,
    user_id,
    product_id,
    mini_app_type,
    store_id,
    quantity,
    created_at
FROM carts
ORDER BY user_id, product_id, mini_app_type, store_id, created_at DESC;

-- Delete all cart records
DELETE FROM carts;

-- Insert back only the records we want to keep
INSERT INTO carts (id, user_id, product_id, mini_app_type, store_id, quantity, created_at, updated_at)
SELECT 
    id,
    user_id,
    product_id,
    mini_app_type,
    store_id,
    quantity,
    created_at,
    now() as updated_at
FROM cart_records_to_keep;

-- Drop the current multi-store constraint
ALTER TABLE carts DROP CONSTRAINT IF EXISTS carts_user_product_miniapp_key;

-- Add the original store-specific constraint
ALTER TABLE carts ADD CONSTRAINT carts_user_product_miniapp_store_key 
UNIQUE (user_id, product_id, mini_app_type, store_id);

-- Add comment to document the original behavior
COMMENT ON CONSTRAINT carts_user_product_miniapp_store_key ON carts IS 
'Ensures unique cart items per user, product, mini-app, and store combination. Maintains store-specific cart isolation for location-based mini-apps.';
