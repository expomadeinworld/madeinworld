# Made in World - Database Seeds

This directory contains the current database seed files generated from the actual product catalog uploaded through the React admin panel.

## Directory Structure

```
database/seeds/
├── README.md                           # This file
├── 01_manufacturers.sql               # Manufacturer data
├── 02_stores.sql                      # Store locations
├── 03_product_categories.sql          # Product categories
├── 04_subcategories.sql               # Product subcategories
├── 05_products.sql                    # Product catalog
├── 06_product_images.sql              # Product images
├── 07_product_category_mapping.sql    # Product-category relationships
├── 08_product_subcategory_mapping.sql # Product-subcategory relationships
├── 09_inventory.sql                   # Stock inventory
└── seed_all.sql                       # Combined seed file
```

## File Descriptions

### Core Data Files (in dependency order)

1. **01_manufacturers.sql** - Company information for product manufacturers
2. **02_stores.sql** - Physical store locations with coordinates and types
3. **03_product_categories.sql** - Main product categories with store associations
4. **04_subcategories.sql** - Product subcategories linked to main categories
5. **05_products.sql** - Complete product catalog with all uploaded data
6. **06_product_images.sql** - Product image URLs and display order
7. **07_product_category_mapping.sql** - Many-to-many product-category relationships
8. **08_product_subcategory_mapping.sql** - Many-to-many product-subcategory relationships
9. **09_inventory.sql** - Stock quantities for products at specific stores

### Combined Files

- **seed_all.sql** - All seed data combined in correct dependency order for easy import

## Usage

### Import All Data
```bash
# Import all seed data at once
psql -h localhost -U madeinworld_admin -d madeinworld_db -f database/seeds/seed_all.sql
```

### Import Individual Files
```bash
# Import files in dependency order
psql -h localhost -U madeinworld_admin -d madeinworld_db -f database/seeds/01_manufacturers.sql
psql -h localhost -U madeinworld_admin -d madeinworld_db -f database/seeds/02_stores.sql
psql -h localhost -U madeinworld_admin -d madeinworld_db -f database/seeds/03_product_categories.sql
# ... continue with remaining files
```

### Reset Database with Current Data
```bash
# Drop and recreate database, then import current data
dropdb -h localhost -U madeinworld_admin madeinworld_db
createdb -h localhost -U madeinworld_admin madeinworld_db
psql -h localhost -U madeinworld_admin -d madeinworld_db -f database/init.sql
psql -h localhost -U madeinworld_admin -d madeinworld_db -f database/seeds/seed_all.sql
```

## Data Sources

These seed files are generated from the actual database state containing:
- Real product data uploaded through the React admin panel
- Actual product brands (levissima, chanteclair, maxi, etc.)
- Current store locations and configurations
- Live category and subcategory structures
- Active product images in the uploads folder

## Generation

These files are automatically generated using the `scripts/generate_seeds.sh` script, which:
1. Connects to the current database
2. Exports data in correct dependency order
3. Preserves referential integrity
4. Maintains image references to uploads folder
5. Includes all uploaded product catalog data

## Notes

- Files are generated in dependency order to ensure proper import
- All foreign key relationships are preserved
- Image URLs reference the actual uploads folder structure
- Data reflects the current state of products uploaded via admin panel
- Files can be used to recreate the database from scratch
- Regular regeneration ensures seed files stay current with admin panel changes
