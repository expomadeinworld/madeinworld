-- Migration: Add display_order to product_categories
-- This migration adds display order functionality to categories for proper ordering in the Flutter app

-- Add display_order column to product_categories
ALTER TABLE product_categories 
ADD COLUMN display_order INTEGER NOT NULL DEFAULT 0;

-- Create index for better performance when ordering categories
CREATE INDEX idx_product_categories_display_order ON product_categories (display_order);

-- Update existing categories with default display orders based on their creation order
-- This ensures existing categories have meaningful display orders
UPDATE product_categories 
SET display_order = category_id 
WHERE display_order = 0;

-- Add comment to clarify the purpose
COMMENT ON COLUMN product_categories.display_order IS 'Order in which categories should be displayed in the Flutter app and admin panel';
