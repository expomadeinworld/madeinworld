# Made in World - Database Schema

This directory contains the database schema and initial data for the Made in World application.

## Files

- `init.sql` - Complete database schema with tables, indexes, and triggers
- `seed_data.sql` - Initial data population matching the Flutter app's mock data
- `README.md` - This documentation file

## Database Schema Overview

### Core Tables

#### User Management
- **users** - User accounts with roles (Customer, Admin, Manufacturer, 3PL, Partner)
- **manufacturers** - Company profiles for product manufacturers
- **partners** - Partner profiles linked to users for unmanned store management

#### Product Catalog
- **stores** - Physical store locations (Retail, Unmanned, Warehouse)
- **product_categories** - Product categories with store type associations
- **products** - Product catalog with pricing and metadata
- **product_images** - Multiple images per product with display order
- **product_category_mapping** - Many-to-many relationship between products and categories

#### Inventory & Operations
- **inventory** - Real-time stock quantities per product per store
- **stock_requests** - Logistics workflow initiation by admins
- **shipments** - 3PL managed deliveries
- **stock_verifications** - Partner verification of received goods

#### E-commerce
- **carts** - User shopping carts
- **cart_items** - Items in shopping carts
- **orders** - Completed purchases
- **order_items** - Individual items in orders
- **notifications** - System notifications for all stakeholders

## Setup Instructions

### Prerequisites

1. PostgreSQL 15+ installed and running
2. Database connection details from Terraform output
3. Database client (psql, DBeaver, etc.)

### 1. Connect to Database

After Terraform deployment, get the connection details:

```bash
# Get RDS endpoint from Terraform output
terraform output rds_endpoint

# Connect using psql
psql -h <rds-endpoint> -U madeinworld_admin -d madeinworld_db
```

### 2. Create Schema

Execute the schema creation script:

```sql
\i init.sql
```

### 3. Populate Initial Data

Execute the seed data script:

```sql
\i seed_data.sql
```

### 4. Verify Setup

Check that all tables are created and populated:

```sql
-- List all tables
\dt

-- Check data counts
SELECT 'products' as table_name, COUNT(*) as count FROM products
UNION ALL
SELECT 'stores', COUNT(*) FROM stores
UNION ALL
SELECT 'inventory', COUNT(*) FROM inventory;
```

## Data Migration from Mock Service

The seed data exactly matches the mock data from `madeinworld_app/lib/data/services/mock_data_service.dart`:

### Products
- **Coca-Cola 12瓶装** (SKU: COCA-001) - Unmanned stores, stock: 25
- **百味来 5号意面** (SKU: BARILLA-001) - Retail stores only
- **天然矿泉水 6瓶装** (SKU: WATER-001) - Unmanned stores, stock: 15
- **瑞士莲 巧克力** (SKU: LINDT-001) - Unmanned stores, stock: 12

### Stores
- **5 Unmanned stores** in Lugano for main app features
- **1 Retail store** accessible only through mini-app

### Categories
- **饮料** (Beverages) - All store types
- **零食** (Snacks) - All store types
- **意面** (Pasta) - Retail only
- **巧克力** (Chocolate) - Unmanned only
- **水果** (Fruits) - All store types
- **乳制品** (Dairy) - Unmanned only

## Key Features

### Stock Management
- Real stock quantities stored in `inventory` table
- Display stock = actual stock - 5 (buffer applied in API)
- Only unmanned stores have inventory tracking

### Store Type Separation
- Retail stores: No stock tracking, always "in stock"
- Unmanned stores: Real-time inventory with 5-unit buffer
- Categories can be associated with specific store types

### Data Integrity
- Foreign key constraints ensure referential integrity
- Triggers automatically update `updated_at` timestamps
- Indexes optimize query performance
- UUID primary keys for users for better security

### Extensibility
- Schema supports full logistics workflow (stock requests, shipments, verifications)
- Notification system for all stakeholders
- Cart and order management for e-commerce
- Role-based access control

## API Compatibility

The database schema is designed to work seamlessly with the existing Flutter Product model:

```dart
Product.fromJson({
  'id': product_id,
  'sku': sku,
  'title': title,
  'description_short': description_short,
  'description_long': description_long,
  'manufacturer_id': manufacturer_id,
  'store_type': store_type,
  'main_price': main_price,
  'strikethrough_price': strikethrough_price,
  'is_active': is_active,
  'is_featured': is_featured,
  'image_urls': [array of image_url],
  'category_ids': [array of category_id],
  'stock_quantity': quantity (from inventory)
})
```

## Security Considerations

- User passwords stored as bcrypt hashes
- Database accessible only from EKS cluster
- Sensitive data (like database passwords) managed via AWS Secrets Manager
- All tables include audit timestamps
- UUID user IDs prevent enumeration attacks

## Maintenance

### Backup Strategy
- RDS automated backups enabled (7-day retention)
- Point-in-time recovery available
- Consider additional manual backups before major updates

### Monitoring
- Monitor inventory levels for automatic reordering
- Track stock request workflow completion rates
- Monitor notification delivery and read rates

### Performance
- Indexes created on frequently queried columns
- Consider partitioning for large tables in production
- Monitor query performance and add indexes as needed
