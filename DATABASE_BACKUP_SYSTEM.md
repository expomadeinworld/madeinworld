# Made in World - Database Backup and Seed System

This document describes the comprehensive backup and seed file generation system for the Made in World application database.

## Overview

The backup and seed system has been completely redesigned to preserve the actual product catalog data uploaded through the React admin panel, replacing the outdated sample data with real product information including brands like LEVISSIMA, Chanteclair, and MAXI.

## System Components

### 1. Database Backup (`scripts/backup_database.sh`)

Creates complete PostgreSQL database backups with compression and metadata.

**Usage:**
```bash
# Create backup with default name
DB_USER=$(whoami) DB_NAME=madeinworld ./scripts/backup_database.sh

# Create backup with custom name
DB_USER=$(whoami) DB_NAME=madeinworld ./scripts/backup_database.sh my_backup_name
```

**Features:**
- Complete database dump using pg_dump
- Automatic compression with gzip
- Timestamped backup files
- Backup summary reports
- Connection testing and validation

### 2. Seed File Generation (`scripts/generate_seeds.sh`)

Generates seed files from the current database state containing actual admin panel data.

**Usage:**
```bash
DB_USER=$(whoami) DB_NAME=madeinworld ./scripts/generate_seeds.sh
```

**Generated Files:**
- `01_manufacturers.sql` - Company information
- `02_stores.sql` - Store locations with coordinates
- `03_product_categories.sql` - Product categories with associations
- `04_subcategories.sql` - Product subcategories
- `05_products.sql` - Complete product catalog (REAL DATA)
- `06_product_images.sql` - Product image references
- `07_product_category_mapping.sql` - Product-category relationships
- `08_product_subcategory_mapping.sql` - Product-subcategory relationships
- `09_inventory.sql` - Stock inventory data
- `seed_all.sql` - Combined seed file for easy import

### 3. Schema Generation (`scripts/generate_schema.sh`)

Creates current database schema file reflecting all applied migrations.

**Usage:**
```bash
DB_USER=$(whoami) DB_NAME=madeinworld ./scripts/generate_schema.sh
```

**Output:**
- `database/current_schema.sql` - Complete current database structure

### 4. Seed Verification (`scripts/verify_seeds.sh`)

Verifies that generated seed files can successfully recreate the database.

**Usage:**
```bash
DB_USER=$(whoami) DB_NAME=madeinworld ./scripts/verify_seeds.sh
```

**Verification Process:**
- Creates temporary test database
- Imports current schema
- Imports seed data
- Verifies table counts match original
- Performs data integrity checks
- Generates verification report
- Cleans up test database

### 5. Database Restoration (`scripts/restore_database.sh`)

Restores database from seed files or backup files.

**Usage:**
```bash
# Restore from seed files
DB_USER=$(whoami) ./scripts/restore_database.sh seeds

# Restore from backup file
DB_USER=$(whoami) ./scripts/restore_database.sh backups/backup_file.sql.gz

# Restore to different database
DB_USER=$(whoami) ./scripts/restore_database.sh seeds my_test_db
```

## Current Database State

### Product Data Summary
- **12 Products** with real brands (LEVISSIMA, Chanteclair, MAXI)
- **16 Categories** with proper store associations
- **22 Subcategories** with images and display order
- **14 Store Locations** across different types
- **7 Manufacturers** with contact information

### Store Types
- 展销商店 (Exhibition Store): 6 products
- 无人门店 (Unmanned Store): 2 products
- 展销商城 (Exhibition Mall): 2 products
- 无人仓店 (Unmanned Warehouse): 2 products

### Mini-App Distribution
- UnmannedStore: 4 products
- ExhibitionSales: 4 products
- RetailStore: 3 products
- GroupBuying: 1 product

## File Structure

```
madeinworld/
├── scripts/
│   ├── backup_database.sh          # Database backup script
│   ├── generate_seeds.sh           # Seed generation script
│   ├── generate_schema.sh          # Schema generation script
│   ├── verify_seeds.sh             # Seed verification script
│   └── restore_database.sh         # Database restoration script
├── database/
│   ├── current_schema.sql          # Current database schema
│   ├── seed_data.sql               # Main seed file (UPDATED)
│   ├── seed_data_old_sample.sql    # Old sample data (backup)
│   └── seeds/                      # Individual seed files
│       ├── 01_manufacturers.sql
│       ├── 02_stores.sql
│       ├── 03_product_categories.sql
│       ├── 04_subcategories.sql
│       ├── 05_products.sql
│       ├── 06_product_images.sql
│       ├── 07_product_category_mapping.sql
│       ├── 08_product_subcategory_mapping.sql
│       ├── 09_inventory.sql
│       └── seed_all.sql
└── backups/
    ├── current_admin_data_backup.sql.gz
    └── current_admin_data_backup_summary.txt
```

## Key Improvements

### 1. Real Data Preservation
- Replaced sample data (Coca-Cola, Barilla) with actual admin panel uploads
- Preserves real product brands: LEVISSIMA, Chanteclair, MAXI
- Maintains actual store locations and configurations
- Keeps current category and subcategory structures

### 2. Schema Accuracy
- Uses current database schema instead of outdated init.sql
- Includes all applied migrations and structural changes
- Supports all current enum types and constraints

### 3. Data Integrity
- Comprehensive verification system
- Foreign key relationship validation
- Table count verification
- Data consistency checks

### 4. Automation
- Automated backup and seed generation
- Dependency order preservation
- Error handling and rollback capabilities
- Comprehensive logging and reporting

## Usage Examples

### Daily Backup
```bash
# Create daily backup
DB_USER=$(whoami) DB_NAME=madeinworld ./scripts/backup_database.sh daily_backup_$(date +%Y%m%d)
```

### Update Seed Files After Admin Changes
```bash
# Regenerate seeds after admin panel updates
DB_USER=$(whoami) DB_NAME=madeinworld ./scripts/generate_seeds.sh
DB_USER=$(whoami) DB_NAME=madeinworld ./scripts/verify_seeds.sh
```

### Fresh Database Setup
```bash
# Set up new database with current data
createdb my_new_database
DB_USER=$(whoami) ./scripts/restore_database.sh seeds my_new_database
```

## Environment Variables

All scripts support these environment variables:
- `DB_HOST` (default: localhost)
- `DB_PORT` (default: 5432)
- `DB_USER` (default: madeinworld_admin)
- `DB_NAME` (default: madeinworld_db)
- `DB_PASSWORD` (default: empty)

## Verification Reports

The system generates detailed reports for:
- Backup operations with file sizes and metadata
- Seed verification with table counts and integrity checks
- Restoration operations with success confirmation
- Database statistics with product breakdowns

## Maintenance

### Regular Tasks
1. **Weekly Backups**: Create backups after significant admin panel changes
2. **Seed Updates**: Regenerate seeds when product catalog is updated
3. **Verification**: Run verification after any database changes
4. **Cleanup**: Remove old backup files to save disk space

### Troubleshooting
- Check database connection settings if scripts fail
- Verify PostgreSQL client tools are installed
- Ensure sufficient disk space for backups
- Review script logs for detailed error information

This system ensures that the Made in World application's product catalog data is properly preserved and can be reliably restored, maintaining the integrity of all data uploaded through the React admin panel.
