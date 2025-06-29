-- Migration: Add Product Management Enhancements
-- This migration adds stock management and mini-app recommendation features

-- Add stock_left field to products table for inventory management
ALTER TABLE products 
ADD COLUMN stock_left INTEGER DEFAULT 0;

-- Add mini_app_recommendation field for mini-app specific recommendations
ALTER TABLE products 
ADD COLUMN is_mini_app_recommendation BOOLEAN DEFAULT FALSE;

-- Add store_id field to products for location-based products (无人商店, 展销展消)
ALTER TABLE products 
ADD COLUMN store_id INTEGER REFERENCES stores(store_id) ON DELETE SET NULL;

-- Add comments to clarify the new fields
COMMENT ON COLUMN products.stock_left IS 'Current stock quantity available for this product';
COMMENT ON COLUMN products.is_mini_app_recommendation IS 'Whether this product appears in mini-app recommendation section';
COMMENT ON COLUMN products.store_id IS 'Store location for 无人商店 and 展销展消 products. NULL for 零售门店 and 团购团批';

-- Create index for better performance on new fields
CREATE INDEX idx_products_stock_left ON products(stock_left);
CREATE INDEX idx_products_mini_app_recommendation ON products(is_mini_app_recommendation);
CREATE INDEX idx_products_store_id ON products(store_id);
CREATE INDEX idx_products_mini_app_type ON products(mini_app_type);

-- Update existing products with default stock values
-- Set stock_left to 50 for unmanned stores and warehouses, 0 for others
UPDATE products 
SET stock_left = CASE 
    WHEN store_type IN ('无人门店', '无人仓店') THEN 50
    ELSE 0
END;

-- Create a view for easier querying of location-based products
CREATE VIEW location_based_products AS
SELECT 
    p.*,
    s.name as store_name,
    s.city as store_city,
    s.address as store_address,
    s.latitude as store_latitude,
    s.longitude as store_longitude,
    s.type as store_type_detail
FROM products p
JOIN stores s ON p.store_id = s.store_id
WHERE p.store_id IS NOT NULL AND p.is_active = TRUE AND s.is_active = TRUE;

-- Add trigger to update updated_at timestamp when stock_left changes
CREATE OR REPLACE FUNCTION update_products_stock_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update timestamp if stock_left actually changed
    IF OLD.stock_left IS DISTINCT FROM NEW.stock_left THEN
        NEW.updated_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_products_stock_timestamp
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_products_stock_timestamp();

-- Insert sample data to test the new functionality
-- Update some existing products to have mini-app recommendations
UPDATE products 
SET is_mini_app_recommendation = TRUE 
WHERE product_id IN (1, 3, 4) AND mini_app_type = 'UnmannedStore';

-- Set store_id for unmanned store products (assuming store_id 1 exists)
UPDATE products 
SET store_id = 1 
WHERE mini_app_type = 'UnmannedStore' AND store_id IS NULL;

-- Set store_id for exhibition products (assuming store_id 3 exists for exhibition)
UPDATE products 
SET store_id = 3 
WHERE mini_app_type = 'ExhibitionSales' AND store_id IS NULL;
