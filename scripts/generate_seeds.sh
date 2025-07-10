#!/bin/bash

# Made in World Database Seed Generation Script
# This script generates seed files from the current database state
# Usage: ./generate_seeds.sh

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEEDS_DIR="$PROJECT_ROOT/database/seeds"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Database configuration (from environment or defaults)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-madeinworld_admin}"
DB_NAME="${DB_NAME:-madeinworld_db}"
DB_PASSWORD="${DB_PASSWORD:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v psql &> /dev/null; then
        error "psql is not installed. Please install PostgreSQL client tools."
        exit 1
    fi
    
    success "All dependencies are available."
}

# Test database connection
test_connection() {
    log "Testing database connection..."
    
    # Build connection string
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$DB_NAME"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    # Test connection with a simple query
    if psql "$conn_str" -c "SELECT 1;" &> /dev/null; then
        success "Database connection successful."
    else
        error "Failed to connect to database. Please check your connection settings."
        error "Connection string: $conn_str"
        exit 1
    fi
}

# Execute SQL query and return results
execute_query() {
    local query="$1"
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$DB_NAME"
    
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    psql "$conn_str" -t -c "$query"
}

# Generate seed file for a specific table
generate_table_seed() {
    local table_name="$1"
    local file_name="$2"
    local custom_query="$3"
    
    log "Generating seed file for $table_name..."
    
    local output_file="$SEEDS_DIR/$file_name"
    
    # Create file header
    cat > "$output_file" << EOF
-- Made in World Database Seeds: $table_name
-- Generated on: $(date)
-- Source: Current database state from admin panel uploads

EOF
    
    # Check if table has data
    local count=$(execute_query "SELECT COUNT(*) FROM $table_name;" | tr -d ' ')
    
    if [ "$count" -eq 0 ]; then
        warning "Table $table_name is empty, skipping..."
        echo "-- Table $table_name is empty" >> "$output_file"
        return
    fi
    
    log "Found $count records in $table_name"
    
    # Use custom query if provided, otherwise use default
    local query="$custom_query"
    if [ -z "$query" ]; then
        query="SELECT * FROM $table_name ORDER BY 1;"
    fi
    
    # Generate INSERT statements
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$DB_NAME"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    # Use pg_dump to generate clean INSERT statements
    pg_dump "$conn_str" --data-only --table="$table_name" --inserts --no-owner --no-privileges >> "$output_file"
    
    success "Generated $file_name with $count records"
}

# Create seeds directory
create_seeds_dir() {
    log "Creating seeds directory..."
    mkdir -p "$SEEDS_DIR"
    success "Seeds directory ready: $SEEDS_DIR"
}

# Generate all seed files
generate_all_seeds() {
    log "Generating all seed files..."
    
    # Generate seed files in dependency order
    generate_table_seed "manufacturers" "01_manufacturers.sql"
    generate_table_seed "stores" "02_stores.sql"
    generate_table_seed "product_categories" "03_product_categories.sql"
    generate_table_seed "subcategories" "04_subcategories.sql"
    generate_table_seed "products" "05_products.sql"
    generate_table_seed "product_images" "06_product_images.sql"
    generate_table_seed "product_category_mapping" "07_product_category_mapping.sql"
    generate_table_seed "product_subcategory_mapping" "08_product_subcategory_mapping.sql"
    generate_table_seed "inventory" "09_inventory.sql"
    
    success "All individual seed files generated."
}

# Create combined seed file
create_combined_seed() {
    log "Creating combined seed file..."
    
    local combined_file="$SEEDS_DIR/seed_all.sql"
    
    # Create header
    cat > "$combined_file" << EOF
-- Made in World Database Seeds - Complete Dataset
-- Generated on: $(date)
-- Source: Current database state from admin panel uploads
--
-- This file contains all seed data in correct dependency order
-- Usage: psql -h host -U user -d dbname -f seed_all.sql

-- Disable triggers during import for better performance
SET session_replication_role = replica;

EOF
    
    # Combine all individual files in order
    local files=(
        "01_manufacturers.sql"
        "02_stores.sql"
        "03_product_categories.sql"
        "04_subcategories.sql"
        "05_products.sql"
        "06_product_images.sql"
        "07_product_category_mapping.sql"
        "08_product_subcategory_mapping.sql"
        "09_inventory.sql"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$SEEDS_DIR/$file" ]; then
            echo "" >> "$combined_file"
            echo "-- =============================================================================" >> "$combined_file"
            echo "-- $file" >> "$combined_file"
            echo "-- =============================================================================" >> "$combined_file"
            echo "" >> "$combined_file"
            cat "$SEEDS_DIR/$file" >> "$combined_file"
        fi
    done
    
    # Re-enable triggers
    echo "" >> "$combined_file"
    echo "-- Re-enable triggers" >> "$combined_file"
    echo "SET session_replication_role = DEFAULT;" >> "$combined_file"
    
    success "Combined seed file created: seed_all.sql"
}

# Generate statistics
generate_statistics() {
    log "Generating database statistics..."
    
    local stats_file="$SEEDS_DIR/database_stats_$TIMESTAMP.txt"
    
    cat > "$stats_file" << EOF
Made in World Database Statistics
=================================
Generated on: $(date)

Table Counts:
EOF
    
    # Get counts for all tables
    local tables=("manufacturers" "stores" "product_categories" "subcategories" "products" "product_images" "product_category_mapping" "product_subcategory_mapping" "inventory")
    
    for table in "${tables[@]}"; do
        local count=$(execute_query "SELECT COUNT(*) FROM $table;" | tr -d ' ')
        printf "%-30s: %s\n" "$table" "$count" >> "$stats_file"
    done
    
    echo "" >> "$stats_file"
    echo "Product Breakdown by Store Type:" >> "$stats_file"
    execute_query "SELECT store_type, COUNT(*) as count FROM products WHERE is_active = true GROUP BY store_type ORDER BY count DESC;" >> "$stats_file"
    
    echo "" >> "$stats_file"
    echo "Product Breakdown by Mini-App Type:" >> "$stats_file"
    execute_query "SELECT mini_app_type, COUNT(*) as count FROM products WHERE is_active = true GROUP BY mini_app_type ORDER BY count DESC;" >> "$stats_file"
    
    echo "" >> "$stats_file"
    echo "Categories with Product Counts:" >> "$stats_file"
    execute_query "SELECT pc.name, COUNT(pcm.product_id) as product_count FROM product_categories pc LEFT JOIN product_category_mapping pcm ON pc.category_id = pcm.category_id GROUP BY pc.category_id, pc.name ORDER BY product_count DESC;" >> "$stats_file"
    
    success "Database statistics saved: database_stats_$TIMESTAMP.txt"
}

# Main execution
main() {
    log "Starting Made in World seed generation process..."
    log "Target database: $DB_NAME at $DB_HOST:$DB_PORT"
    
    check_dependencies
    test_connection
    create_seeds_dir
    generate_all_seeds
    create_combined_seed
    generate_statistics
    
    success "Seed generation completed successfully!"
    success "Seed files location: $SEEDS_DIR"
    
    # List generated files
    log "Generated files:"
    ls -lah "$SEEDS_DIR"/*.sql 2>/dev/null || log "No seed files found."
}

# Handle script interruption
trap 'error "Seed generation process interrupted."; exit 1' INT TERM

# Run main function
main "$@"
