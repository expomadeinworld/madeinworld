-- Seed data for Made in World Database
-- This script populates the database with initial data from mock_data_service.dart

-- Insert Manufacturers
INSERT INTO manufacturers (manufacturer_id, company_name, contact_person, contact_email, address) VALUES
(1, 'Coca-Cola Company', 'John Smith', 'contact@coca-cola.com', 'Atlanta, GA, USA'),
(2, 'Barilla Group', 'Marco Rossi', 'contact@barilla.com', 'Parma, Italy'),
(3, 'Alpine Springs', 'Hans Mueller', 'contact@alpinesprings.ch', 'Swiss Alps, Switzerland'),
(4, 'Lindt & Sprüngli', 'Pierre Dubois', 'contact@lindt.com', 'Kilchberg, Switzerland'),
(5, 'Swiss Dairy Co.', 'Anna Weber', 'contact@swissdairy.ch', 'Bern, Switzerland'),
(6, 'Mountain Honey', 'Klaus Fischer', 'contact@mountainhoney.ch', 'Graubünden, Switzerland'),
(7, 'Swiss Timepieces', 'Jean-Claude Biver', 'contact@swisstimepieces.ch', 'Geneva, Switzerland');

-- Insert Product Categories
INSERT INTO product_categories (category_id, name, store_type_association) VALUES
(1, '饮料', 'All'),
(2, '零食', 'All'),
(3, '意面', 'Retail'),
(4, '巧克力', 'Unmanned'),
(5, '水果', 'All'),
(6, '乳制品', 'Unmanned'),
(7, '瑞士特产', 'All'),
(8, '奢侈品', 'All'),
(9, '礼品', 'All');

-- Insert Stores
INSERT INTO stores (store_id, name, city, address, latitude, longitude, type, is_active) VALUES
-- Unmanned stores (main app)
(1, 'Via Nassa 店', '卢加诺', 'Via Nassa 5, 6900 Lugano', 46.0037, 8.9511, '无人商店', TRUE),
(3, 'Piazza Riforma 店', '卢加诺', 'Piazza Riforma 1, 6900 Lugano', 46.0049, 8.9517, '无人商店', TRUE),
(4, 'Via Pretorio 店', '卢加诺', 'Via Pretorio 15, 6900 Lugano', 46.0058, 8.9489, '无人仓店', TRUE),
(5, 'Corso Pestalozzi 店', '卢加诺', 'Corso Pestalozzi 8, 6900 Lugano', 46.0071, 8.9523, '无人商店', TRUE),
(6, 'Via Cattedrale 店', '卢加诺', 'Via Cattedrale 3, 6900 Lugano', 46.0043, 8.9503, '无人仓店', TRUE),
-- Retail stores (mini-app only)
(2, 'Centro 店', '卢加诺', 'Via Centro 12, 6900 Lugano', 46.0067, 8.9541, 'Retail', TRUE),
-- Exhibition stores (展销展消 mini-app)
(7, 'Via Cantonale 展销店', '卢加诺', 'Via Cantonale 20, 6900 Lugano', 46.0055, 8.9495, '展销商店', TRUE),
(8, 'Quartiere Molino 展销城', '卢加诺', 'Via Molino 8, 6900 Lugano', 46.0062, 8.9508, '展销商城', TRUE),
(9, 'Via Stauffacher 展销店', '卢加诺', 'Via Stauffacher 12, 6900 Lugano', 46.0048, 8.9532, '展销商店', TRUE);

-- Insert Products
INSERT INTO products (product_id, sku, title, description_short, description_long, manufacturer_id, store_type, main_price, strikethrough_price, is_active, is_featured) VALUES
-- Unmanned store products
(1, 'COCA-001', '可口可乐 12瓶装', '经典口味', '经典可口可乐，12瓶装，清爽怡人，是聚会和日常饮用的完美选择。', 1, '无人商店', 9.99, 12.50, TRUE, TRUE),
(3, 'WATER-001', '天然矿泉水 6瓶装', '源自阿尔卑斯', '来自阿尔卑斯山的天然矿泉水，富含矿物质，口感清甜，6瓶装经济实惠。', 3, '无人商店', 2.99, 3.80, TRUE, TRUE),
(4, 'LINDT-001', '瑞士莲 巧克力', '丝滑享受', '瑞士莲经典牛奶巧克力，丝滑细腻的口感，甜而不腻，是巧克力爱好者的首选。', 4, '无人商店', 4.50, 5.25, TRUE, TRUE),
-- Retail store products
(2, 'BARILLA-001', '百味来 5号意面', '意大利进口', '正宗意大利百味来5号意面，优质小麦制作，口感Q弹，是制作各种意面料理的理想选择。', 2, 'Retail', 1.49, 1.99, TRUE, TRUE),
-- Exhibition store products
(5, 'SWISS-CHEESE-001', '瑞士奶酪拼盘', '精选瑞士奶酪', '精选瑞士本地奶酪拼盘，包含多种口味，适合聚会和品鉴。', 5, '展销商店', 15.99, 18.50, TRUE, TRUE),
(6, 'ALPINE-HONEY-001', '阿尔卑斯蜂蜜', '纯天然蜂蜜', '来自阿尔卑斯山区的纯天然蜂蜜，口感醇厚，营养丰富。', 6, '展销商店', 12.99, 15.00, TRUE, TRUE),
(7, 'SWISS-WATCH-001', '瑞士手表', '精密制造', '瑞士制造的精密手表，工艺精湛，是送礼和收藏的佳品。', 7, '展销商城', 299.99, 350.00, TRUE, TRUE),
(8, 'CHOCOLATE-GIFT-001', '巧克力礼盒', '节日特供', '精美包装的巧克力礼盒，多种口味，是节日送礼的完美选择。', 4, '展销商城', 25.99, 30.00, TRUE, TRUE);

-- Insert Product Images
-- FIX: Using a more reliable placeholder service
INSERT INTO product_images (product_id, image_url, display_order) VALUES
(1, 'https://via.placeholder.com/300/FFF5F5/D92525?text=可口可乐', 0),
(2, 'https://via.placeholder.com/300/FFF5F5/D92525?text=百味来', 0),
(3, 'https://via.placeholder.com/300/FFF5F5/D92525?text=矿泉水', 0),
(4, 'https://via.placeholder.com/300/FFF5F5/D92525?text=巧克力', 0);

-- Insert Product Category Mappings
INSERT INTO product_category_mapping (product_id, category_id) VALUES
(1, 1), -- Coca-Cola -> 饮料
(2, 3), -- Barilla -> 意面
(3, 1), -- Water -> 饮料
(4, 4); -- Lindt -> 巧克力

-- Insert Inventory for Unmanned stores only (matching mock data stock quantities)
-- Product 1 (Coca-Cola) - stock: 25, display: 20
INSERT INTO inventory (product_id, store_id, quantity) VALUES
(1, 1, 25), -- Via Nassa
(1, 3, 25), -- Piazza Riforma
(1, 4, 25), -- Via Pretorio
(1, 5, 25), -- Corso Pestalozzi
(1, 6, 25); -- Via Cattedrale

-- Product 3 (Water) - stock: 15, display: 10
INSERT INTO inventory (product_id, store_id, quantity) VALUES
(3, 1, 15), -- Via Nassa
(3, 3, 15), -- Piazza Riforma
(3, 4, 15), -- Via Pretorio
(3, 5, 15), -- Corso Pestalozzi
(3, 6, 15); -- Via Cattedrale

-- Product 4 (Lindt) - stock: 12, display: 7
INSERT INTO inventory (product_id, store_id, quantity) VALUES
(4, 1, 12), -- Via Nassa
(4, 3, 12), -- Piazza Riforma
(4, 4, 12), -- Via Pretorio
(4, 5, 12), -- Corso Pestalozzi
(4, 6, 12); -- Via Cattedrale

-- Insert a sample admin user (for testing purposes)
INSERT INTO users (user_id, phone_number, password_hash, full_name, email, role) VALUES
(uuid_generate_v4(), '+41791234567', '$2a$10$example.hash.here', 'Admin User', 'admin@madeinworld.com', 'Admin');

-- Insert a sample customer user (matching mock data)
INSERT INTO users (user_id, phone_number, password_hash, full_name, email, avatar_url, role) VALUES
('550e8400-e29b-41d4-a716-446655440000', '+41791234568', '$2a$10$example.hash.here', '尊贵的用户', 'user.name@email.com', 'https://via.placeholder.com/96/D92525/FFFFFF?text=M', 'Customer');

-- Reset sequences to continue from the inserted values
SELECT setval('manufacturers_manufacturer_id_seq', (SELECT MAX(manufacturer_id) FROM manufacturers), true);
SELECT setval('product_categories_category_id_seq', (SELECT MAX(category_id) FROM product_categories), true);
SELECT setval('stores_store_id_seq', (SELECT MAX(store_id) FROM stores), true);
SELECT setval('products_product_id_seq', (SELECT MAX(product_id) FROM products), true);
SELECT setval('product_images_image_id_seq', (SELECT MAX(image_id) FROM product_images), true);
SELECT setval('inventory_inventory_id_seq', (SELECT MAX(inventory_id) FROM inventory), true);