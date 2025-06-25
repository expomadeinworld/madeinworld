-- Rollback Migration: Remove subcategories and mini-app types
-- This script rolls back the subcategories and mini-app types migration

-- Drop triggers first
DROP TRIGGER IF EXISTS update_subcategories_updated_at ON subcategories;
DROP FUNCTION IF EXISTS update_subcategories_updated_at();

-- Drop indexes
DROP INDEX IF EXISTS idx_subcategories_parent_category;
DROP INDEX IF EXISTS idx_subcategories_display_order;
DROP INDEX IF EXISTS idx_product_categories_mini_app;
DROP INDEX IF EXISTS idx_product_subcategory_mapping_product;
DROP INDEX IF EXISTS idx_product_subcategory_mapping_subcategory;

-- Drop tables (in reverse order of creation)
DROP TABLE IF EXISTS product_subcategory_mapping;
DROP TABLE IF EXISTS subcategories;

-- Remove mini_app_association column from product_categories
ALTER TABLE product_categories DROP COLUMN IF EXISTS mini_app_association;

-- Drop the mini_app_type enum
DROP TYPE IF EXISTS mini_app_type;

-- Remove the new categories that were added for Exhibition and Group Buying
DELETE FROM product_categories WHERE name IN ('展销商品', '团购商品', '特色产品', '限时优惠');
