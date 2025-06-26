-- Migration: Restructure for Mini-App Location Management
-- This migration updates the schema to support location-based categorization for mini-apps

-- Update store_type enum to include the 4 specific store types
ALTER TYPE store_type RENAME TO store_type_old;
CREATE TYPE store_type AS ENUM ('无人门店', '无人仓店', '展销商店', '展销商城');

-- Add image_url to stores table for storefront images
ALTER TABLE stores 
ADD COLUMN image_url VARCHAR(500);

-- Update products table first to avoid dependency issues
ALTER TABLE products
ALTER COLUMN store_type TYPE text;

-- Update existing stores to use new enum values (temporary mapping)
-- This preserves existing data while transitioning to new structure
ALTER TABLE stores
ALTER COLUMN type TYPE store_type USING
  CASE
    WHEN type::text = 'Unmanned' THEN '无人门店'::store_type
    WHEN type::text = 'Warehouse' THEN '无人仓店'::store_type
    WHEN type::text = 'Retail' THEN '展销商店'::store_type
    ELSE '无人门店'::store_type
  END;

-- Update products to use new store type values
UPDATE products
SET store_type =
  CASE
    WHEN store_type = 'Unmanned' THEN '无人门店'
    WHEN store_type = 'Warehouse' THEN '无人仓店'
    WHEN store_type = 'Retail' THEN '展销商店'
    ELSE '无人门店'
  END;

-- Now update products column to use new enum
ALTER TABLE products
ALTER COLUMN store_type TYPE store_type USING store_type::store_type;

-- Drop old enum
DROP TYPE IF EXISTS store_type_old;

-- Add mini_app_type to products table
ALTER TABLE products 
ADD COLUMN mini_app_type mini_app_type;

-- Update existing products to have mini_app_type based on current store_type
UPDATE products 
SET mini_app_type = 
  CASE 
    WHEN store_type::text IN ('无人门店', '无人仓店') THEN 'UnmannedStore'::mini_app_type
    WHEN store_type::text IN ('展销商店', '展销商城') THEN 'ExhibitionSales'::mini_app_type
    ELSE 'RetailStore'::mini_app_type
  END;

-- Make mini_app_type NOT NULL after populating
ALTER TABLE products 
ALTER COLUMN mini_app_type SET NOT NULL;

-- Add store_id to product_categories for location-based scoping
-- This allows categories to be scoped to specific store locations
ALTER TABLE product_categories 
ADD COLUMN store_id INTEGER REFERENCES stores(store_id) ON DELETE CASCADE;

-- Add is_active column to product_categories for visibility control
ALTER TABLE product_categories 
ADD COLUMN is_active BOOLEAN DEFAULT TRUE;

-- Create indexes for performance (with IF NOT EXISTS to avoid conflicts)
CREATE INDEX IF NOT EXISTS idx_product_categories_mini_app ON product_categories USING GIN (mini_app_association);
CREATE INDEX IF NOT EXISTS idx_product_categories_store_id ON product_categories (store_id);
CREATE INDEX IF NOT EXISTS idx_products_mini_app_type ON products (mini_app_type);
CREATE INDEX IF NOT EXISTS idx_stores_type ON stores (type);
CREATE INDEX IF NOT EXISTS idx_stores_active ON stores (is_active);

-- Update subcategories to support file upload (change image_url to allow local files)
ALTER TABLE subcategories 
ALTER COLUMN image_url TYPE VARCHAR(500);

-- Add comment to clarify the new structure
COMMENT ON COLUMN product_categories.store_id IS 'For location-based categories (无人商店, 展销展消). NULL for global categories (零售门店, 团购团批)';
COMMENT ON COLUMN products.mini_app_type IS 'Determines which mini-app this product belongs to';
COMMENT ON COLUMN stores.image_url IS 'Storefront image for display in admin panel and app';

-- Create a view for easier querying of location-based categories
CREATE VIEW location_based_categories AS
SELECT 
    c.*,
    s.name as store_name,
    s.city as store_city,
    s.latitude,
    s.longitude,
    s.type as store_type
FROM product_categories c
JOIN stores s ON c.store_id = s.store_id
WHERE c.store_id IS NOT NULL AND c.is_active = TRUE AND s.is_active = TRUE;

-- Create a view for global categories (not location-based)
CREATE VIEW global_categories AS
SELECT *
FROM product_categories
WHERE store_id IS NULL AND is_active = TRUE;
