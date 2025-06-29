-- Migration: Add Cost Price and Minimum Order Quantity
-- This migration adds cost price (manufacturer price) and minimum order quantity fields

-- Add cost_price field (manufacturer price - should not be exposed to public API)
ALTER TABLE products 
ADD COLUMN cost_price DECIMAL(10, 2);

-- Add minimum_order_quantity field with default value of 1
ALTER TABLE products 
ADD COLUMN minimum_order_quantity INTEGER DEFAULT 1;

-- Add constraints for data integrity
ALTER TABLE products 
ADD CONSTRAINT check_cost_price_positive 
CHECK (cost_price IS NULL OR cost_price >= 0);

ALTER TABLE products 
ADD CONSTRAINT check_minimum_order_quantity_positive 
CHECK (minimum_order_quantity >= 1);

-- Add comments to clarify the new fields
COMMENT ON COLUMN products.cost_price IS 'Manufacturer/cost price - NEVER expose to public API, admin only';
COMMENT ON COLUMN products.minimum_order_quantity IS 'Minimum units customers must purchase (e.g., 4 if sold in 4-packs)';

-- Create indexes for better performance
CREATE INDEX idx_products_cost_price ON products(cost_price);
CREATE INDEX idx_products_minimum_order_quantity ON products(minimum_order_quantity);

-- Update existing products with default MOQ of 1
UPDATE products 
SET minimum_order_quantity = 1 
WHERE minimum_order_quantity IS NULL;

-- Make minimum_order_quantity NOT NULL after setting defaults
ALTER TABLE products 
ALTER COLUMN minimum_order_quantity SET NOT NULL;

-- Update the product_images table to support ordering
ALTER TABLE product_images 
ADD COLUMN is_primary BOOLEAN DEFAULT FALSE;

-- Add constraint to ensure only one primary image per product
CREATE UNIQUE INDEX idx_product_images_primary_unique 
ON product_images (product_id) 
WHERE is_primary = TRUE;

-- Set the first image as primary for existing products
WITH first_images AS (
    SELECT DISTINCT ON (product_id) product_id, image_id
    FROM product_images
    ORDER BY product_id, display_order, image_id
)
UPDATE product_images 
SET is_primary = TRUE 
WHERE image_id IN (SELECT image_id FROM first_images);

-- Add comment for the new field
COMMENT ON COLUMN product_images.is_primary IS 'Indicates if this is the primary/thumbnail image for the product';

-- Create a view for admin-only product data (includes cost_price)
CREATE VIEW admin_products AS
SELECT 
    p.*,
    ARRAY_AGG(
        JSON_BUILD_OBJECT(
            'id', pi.image_id,
            'url', pi.image_url,
            'display_order', pi.display_order,
            'is_primary', pi.is_primary
        ) ORDER BY pi.display_order, pi.image_id
    ) FILTER (WHERE pi.image_id IS NOT NULL) as images
FROM products p
LEFT JOIN product_images pi ON p.product_id = pi.product_id
WHERE p.is_active = TRUE
GROUP BY p.product_id;

-- Create a view for public product data (excludes cost_price)
CREATE VIEW public_products AS
SELECT 
    p.product_id,
    p.sku,
    p.title,
    p.description_short,
    p.description_long,
    p.manufacturer_id,
    p.store_type,
    p.mini_app_type,
    p.store_id,
    p.main_price,
    p.strikethrough_price,
    p.stock_left,
    p.minimum_order_quantity,
    p.is_active,
    p.is_featured,
    p.is_mini_app_recommendation,
    p.created_at,
    p.updated_at,
    ARRAY_AGG(
        JSON_BUILD_OBJECT(
            'id', pi.image_id,
            'url', pi.image_url,
            'display_order', pi.display_order,
            'is_primary', pi.is_primary
        ) ORDER BY pi.display_order, pi.image_id
    ) FILTER (WHERE pi.image_id IS NOT NULL) as images
FROM products p
LEFT JOIN product_images pi ON p.product_id = pi.product_id
WHERE p.is_active = TRUE
GROUP BY p.product_id;

-- Add sample data for testing
UPDATE products 
SET cost_price = main_price * 0.6, minimum_order_quantity = 1 
WHERE product_id IN (1, 2, 3, 4, 7);
