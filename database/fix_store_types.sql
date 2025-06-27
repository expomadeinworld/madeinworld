-- Fix Store Type Values
-- This script corrects the store type values in the database to match the expected Chinese values

-- First, check current store types
SELECT store_id, name, type FROM stores ORDER BY store_id;

-- Update store types from English to Chinese values and fix naming consistency
UPDATE stores
SET type = CASE
    WHEN type = 'Unmanned' THEN '无人商店'
    WHEN type = '无人门店' THEN '无人商店'  -- Update old naming for consistency
    WHEN type = 'Retail' THEN '展销商店'
    WHEN type = 'Warehouse' THEN '无人仓店'
    WHEN type = 'Exhibition' THEN '展销商城'
    ELSE type  -- Keep existing value if already correct
END
WHERE type IN ('Unmanned', 'Retail', 'Warehouse', 'Exhibition', '无人门店');

-- Also update products table to match
UPDATE products
SET store_type = CASE
    WHEN store_type = 'Unmanned' THEN '无人商店'
    WHEN store_type = '无人门店' THEN '无人商店'  -- Update old naming for consistency
    WHEN store_type = 'Retail' THEN '展销商店'
    WHEN store_type = 'Warehouse' THEN '无人仓店'
    WHEN store_type = 'Exhibition' THEN '展销商城'
    ELSE store_type  -- Keep existing value if already correct
END
WHERE store_type IN ('Unmanned', 'Retail', 'Warehouse', 'Exhibition', '无人门店');

-- Verify the changes
SELECT store_id, name, type FROM stores ORDER BY store_id;
SELECT product_id, title, store_type FROM products ORDER BY product_id;
