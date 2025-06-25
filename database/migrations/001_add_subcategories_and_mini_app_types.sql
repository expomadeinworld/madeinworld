-- Migration: Add subcategories and mini-app types
-- This migration adds support for hierarchical categories and mini-app associations

-- Add mini_app_type enum
CREATE TYPE mini_app_type AS ENUM ('RetailStore', 'UnmannedStore', 'ExhibitionSales', 'GroupBuying');

-- Create subcategories table
CREATE TABLE subcategories (
    subcategory_id SERIAL PRIMARY KEY,
    parent_category_id INTEGER NOT NULL REFERENCES product_categories(category_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    image_url VARCHAR(500),
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add mini_app_association column to product_categories
ALTER TABLE product_categories
ADD COLUMN mini_app_association mini_app_type[] DEFAULT ARRAY['RetailStore']::mini_app_type[];

-- Create product_subcategory_mapping table (Many-to-Many)
CREATE TABLE product_subcategory_mapping (
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    subcategory_id INTEGER NOT NULL REFERENCES subcategories(subcategory_id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, subcategory_id)
);

-- Create indexes for better performance
CREATE INDEX idx_subcategories_parent_category ON subcategories(parent_category_id);
CREATE INDEX idx_subcategories_display_order ON subcategories(display_order);
CREATE INDEX idx_product_categories_mini_app ON product_categories USING GIN(mini_app_association);
CREATE INDEX idx_product_subcategory_mapping_product ON product_subcategory_mapping(product_id);
CREATE INDEX idx_product_subcategory_mapping_subcategory ON product_subcategory_mapping(subcategory_id);

-- Add trigger to update updated_at timestamp for subcategories
CREATE OR REPLACE FUNCTION update_subcategories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_subcategories_updated_at
    BEFORE UPDATE ON subcategories
    FOR EACH ROW
    EXECUTE FUNCTION update_subcategories_updated_at();

-- Update existing categories with mini-app associations
UPDATE product_categories
SET mini_app_association = CASE
    WHEN store_type_association = 'Retail' THEN ARRAY['RetailStore']::mini_app_type[]
    WHEN store_type_association = 'Unmanned' THEN ARRAY['UnmannedStore']::mini_app_type[]
    WHEN store_type_association = 'All' THEN ARRAY['RetailStore','UnmannedStore']::mini_app_type[]
    ELSE ARRAY['RetailStore']::mini_app_type[]
END;

-- Insert sample subcategories for existing categories
INSERT INTO subcategories (parent_category_id, name, image_url, display_order) VALUES
-- 饮料 subcategories
(1, '休闲零食', 'https://via.placeholder.com/150/FFF5F5/D92525?text=休闲零食', 1),
(1, '乳品冲饮', 'https://via.placeholder.com/150/FFF5F5/D92525?text=乳品冲饮', 2),
(1, '粮油速食', 'https://via.placeholder.com/150/FFF5F5/D92525?text=粮油速食', 3),
(1, '饼干糕点', 'https://via.placeholder.com/150/FFF5F5/D92525?text=饼干糕点', 4),
(1, '中外名酒', 'https://via.placeholder.com/150/FFF5F5/D92525?text=中外名酒', 5),

-- 零食 subcategories  
(2, '地方农货', 'https://via.placeholder.com/150/FFF5F5/D92525?text=地方农货', 1),
(2, '坚果蜜饯', 'https://via.placeholder.com/150/FFF5F5/D92525?text=坚果蜜饯', 2),
(2, '滋补养生', 'https://via.placeholder.com/150/FFF5F5/D92525?text=滋补养生', 3),
(2, '营养保健', 'https://via.placeholder.com/150/FFF5F5/D92525?text=营养保健', 4),
(2, '茶叶', 'https://via.placeholder.com/150/FFF5F5/D92525?text=茶叶', 5),

-- 意面 subcategories
(3, '意大利面条', 'https://via.placeholder.com/150/FFF5F5/D92525?text=意大利面条', 1),
(3, '意式调料', 'https://via.placeholder.com/150/FFF5F5/D92525?text=意式调料', 2),
(3, '意式罐头', 'https://via.placeholder.com/150/FFF5F5/D92525?text=意式罐头', 3),

-- 巧克力 subcategories
(4, '黑巧克力', 'https://via.placeholder.com/150/FFF5F5/D92525?text=黑巧克力', 1),
(4, '牛奶巧克力', 'https://via.placeholder.com/150/FFF5F5/D92525?text=牛奶巧克力', 2),
(4, '白巧克力', 'https://via.placeholder.com/150/FFF5F5/D92525?text=白巧克力', 3),

-- 水果 subcategories
(5, '新鲜水果', 'https://via.placeholder.com/150/FFF5F5/D92525?text=新鲜水果', 1),
(5, '果干果脯', 'https://via.placeholder.com/150/FFF5F5/D92525?text=果干果脯', 2),

-- 乳制品 subcategories
(6, '牛奶', 'https://via.placeholder.com/150/FFF5F5/D92525?text=牛奶', 1),
(6, '酸奶', 'https://via.placeholder.com/150/FFF5F5/D92525?text=酸奶', 2),
(6, '奶酪', 'https://via.placeholder.com/150/FFF5F5/D92525?text=奶酪', 3);

-- Add new categories for Exhibition and Group Buying
INSERT INTO product_categories (name, mini_app_association) VALUES
('展销商品', ARRAY['ExhibitionSales']::mini_app_type[]),
('团购商品', ARRAY['GroupBuying']::mini_app_type[]),
('特色产品', ARRAY['ExhibitionSales','GroupBuying']::mini_app_type[]),
('限时优惠', ARRAY['GroupBuying']::mini_app_type[]);

-- Add subcategories for new categories (using the actual category IDs)
INSERT INTO subcategories (parent_category_id, name, image_url, display_order) VALUES
-- 展销商品 subcategories (category_id = 11)
((SELECT category_id FROM product_categories WHERE name = '展销商品'), '地方特产', 'https://via.placeholder.com/150/FFF5F5/D92525?text=地方特产', 1),
((SELECT category_id FROM product_categories WHERE name = '展销商品'), '手工艺品', 'https://via.placeholder.com/150/FFF5F5/D92525?text=手工艺品', 2),
((SELECT category_id FROM product_categories WHERE name = '展销商品'), '文化用品', 'https://via.placeholder.com/150/FFF5F5/D92525?text=文化用品', 3),

-- 团购商品 subcategories (category_id = 12)
((SELECT category_id FROM product_categories WHERE name = '团购商品'), '批发商品', 'https://via.placeholder.com/150/FFF5F5/D92525?text=批发商品', 1),
((SELECT category_id FROM product_categories WHERE name = '团购商品'), '团购套餐', 'https://via.placeholder.com/150/FFF5F5/D92525?text=团购套餐', 2),
((SELECT category_id FROM product_categories WHERE name = '团购商品'), '企业采购', 'https://via.placeholder.com/150/FFF5F5/D92525?text=企业采购', 3),

-- 特色产品 subcategories (category_id = 13)
((SELECT category_id FROM product_categories WHERE name = '特色产品'), '季节限定', 'https://via.placeholder.com/150/FFF5F5/D92525?text=季节限定', 1),
((SELECT category_id FROM product_categories WHERE name = '特色产品'), '新品推荐', 'https://via.placeholder.com/150/FFF5F5/D92525?text=新品推荐', 2),

-- 限时优惠 subcategories (category_id = 14)
((SELECT category_id FROM product_categories WHERE name = '限时优惠'), '秒杀商品', 'https://via.placeholder.com/150/FFF5F5/D92525?text=秒杀商品', 1),
((SELECT category_id FROM product_categories WHERE name = '限时优惠'), '拼团优惠', 'https://via.placeholder.com/150/FFF5F5/D92525?text=拼团优惠', 2);
