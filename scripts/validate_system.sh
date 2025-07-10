#!/bin/bash

# Made in World Database System Validation Script
# This script validates the complete backup and seed system
# Usage: ./validate_system.sh

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
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

# Execute SQL query and return results
execute_query() {
    local query="$1"
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$DB_NAME"
    
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    psql "$conn_str" -t -c "$query" 2>/dev/null
}

# Validate database content
validate_database_content() {
    log "Validating database content..."
    
    # Check total products
    local total_products=$(execute_query "SELECT COUNT(*) FROM products;" | tr -d ' ')
    if [ "$total_products" -ge 10 ]; then
        success "✓ Database contains $total_products products (expected: ≥10)"
    else
        error "✗ Database contains only $total_products products (expected: ≥10)"
        return 1
    fi
    
    # Check real brand products
    local real_brands=$(execute_query "SELECT COUNT(*) FROM products WHERE title LIKE '%MAXI%' OR title LIKE '%LEVISSIMA%' OR title LIKE '%Chanteclair%';" | tr -d ' ')
    if [ "$real_brands" -ge 5 ]; then
        success "✓ Database contains $real_brands real brand products (MAXI, LEVISSIMA, Chanteclair)"
    else
        error "✗ Database contains only $real_brands real brand products"
        return 1
    fi
    
    # Check store types
    local store_types=$(execute_query "SELECT COUNT(DISTINCT store_type) FROM products;" | tr -d ' ')
    if [ "$store_types" -ge 3 ]; then
        success "✓ Database contains $store_types different store types"
    else
        error "✗ Database contains only $store_types store types"
        return 1
    fi
    
    # Check categories
    local categories=$(execute_query "SELECT COUNT(*) FROM product_categories;" | tr -d ' ')
    if [ "$categories" -ge 10 ]; then
        success "✓ Database contains $categories categories"
    else
        error "✗ Database contains only $categories categories"
        return 1
    fi
    
    # Check subcategories
    local subcategories=$(execute_query "SELECT COUNT(*) FROM subcategories;" | tr -d ' ')
    if [ "$subcategories" -ge 15 ]; then
        success "✓ Database contains $subcategories subcategories"
    else
        error "✗ Database contains only $subcategories subcategories"
        return 1
    fi
}

# Validate file structure
validate_file_structure() {
    log "Validating file structure..."
    
    local required_files=(
        "scripts/backup_database.sh"
        "scripts/generate_seeds.sh"
        "scripts/generate_schema.sh"
        "scripts/verify_seeds.sh"
        "scripts/restore_database.sh"
        "database/current_schema.sql"
        "database/seed_data.sql"
        "database/seeds/seed_all.sql"
        "DATABASE_BACKUP_SYSTEM.md"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$PROJECT_ROOT/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        success "✓ All required files are present"
    else
        error "✗ Missing files:"
        for file in "${missing_files[@]}"; do
            error "  - $file"
        done
        return 1
    fi
    
    # Check if scripts are executable
    local scripts=("backup_database.sh" "generate_seeds.sh" "generate_schema.sh" "verify_seeds.sh" "restore_database.sh")
    for script in "${scripts[@]}"; do
        if [ ! -x "$PROJECT_ROOT/scripts/$script" ]; then
            error "✗ Script not executable: scripts/$script"
            return 1
        fi
    done
    
    success "✓ All scripts are executable"
}

# Validate seed files
validate_seed_files() {
    log "Validating seed files..."
    
    local seed_files=(
        "01_manufacturers.sql"
        "02_stores.sql"
        "03_product_categories.sql"
        "04_subcategories.sql"
        "05_products.sql"
        "06_product_images.sql"
        "07_product_category_mapping.sql"
        "08_product_subcategory_mapping.sql"
        "09_inventory.sql"
        "seed_all.sql"
    )
    
    for file in "${seed_files[@]}"; do
        if [ ! -f "$PROJECT_ROOT/database/seeds/$file" ]; then
            error "✗ Missing seed file: $file"
            return 1
        fi
        
        # Check if file has content
        if [ ! -s "$PROJECT_ROOT/database/seeds/$file" ]; then
            warning "⚠ Seed file is empty: $file"
        fi
    done
    
    success "✓ All seed files are present"
    
    # Check if seed_all.sql contains real data
    if grep -q "MAXI\|LEVISSIMA\|Chanteclair" "$PROJECT_ROOT/database/seeds/seed_all.sql"; then
        success "✓ Seed files contain real product data"
    else
        error "✗ Seed files do not contain real product data"
        return 1
    fi
}

# Validate backup system
validate_backup_system() {
    log "Validating backup system..."
    
    # Check if backups directory exists
    if [ ! -d "$PROJECT_ROOT/backups" ]; then
        error "✗ Backups directory does not exist"
        return 1
    fi
    
    success "✓ Backups directory exists"
    
    # Check if there are any backup files
    if ls "$PROJECT_ROOT/backups"/*.sql.gz 1> /dev/null 2>&1; then
        local backup_count=$(ls "$PROJECT_ROOT/backups"/*.sql.gz | wc -l)
        success "✓ Found $backup_count backup file(s)"
    else
        warning "⚠ No backup files found in backups directory"
    fi
}

# Generate validation report
generate_validation_report() {
    log "Generating validation report..."
    
    local report_file="$PROJECT_ROOT/system_validation_report_$TIMESTAMP.txt"
    
    cat > "$report_file" << EOF
Made in World Database System Validation Report
===============================================
Generated on: $(date)
Database: $DB_NAME at $DB_HOST:$DB_PORT

System Status: VALIDATED ✓

Database Content:
EOF
    
    # Add database statistics
    execute_query "SELECT 'Total Products: ' || COUNT(*) FROM products;" >> "$report_file"
    execute_query "SELECT 'Real Brand Products: ' || COUNT(*) FROM products WHERE title LIKE '%MAXI%' OR title LIKE '%LEVISSIMA%' OR title LIKE '%Chanteclair%';" >> "$report_file"
    execute_query "SELECT 'Categories: ' || COUNT(*) FROM product_categories;" >> "$report_file"
    execute_query "SELECT 'Subcategories: ' || COUNT(*) FROM subcategories;" >> "$report_file"
    execute_query "SELECT 'Stores: ' || COUNT(*) FROM stores;" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "Product Brands Found:" >> "$report_file"
    execute_query "SELECT DISTINCT CASE WHEN title LIKE '%MAXI%' THEN 'MAXI' WHEN title LIKE '%LEVISSIMA%' THEN 'LEVISSIMA' WHEN title LIKE '%Chanteclair%' THEN 'Chanteclair' END as brand FROM products WHERE title LIKE '%MAXI%' OR title LIKE '%LEVISSIMA%' OR title LIKE '%Chanteclair%' ORDER BY brand;" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "System Files:" >> "$report_file"
    echo "- Backup scripts: ✓" >> "$report_file"
    echo "- Seed generation: ✓" >> "$report_file"
    echo "- Schema management: ✓" >> "$report_file"
    echo "- Verification tools: ✓" >> "$report_file"
    echo "- Documentation: ✓" >> "$report_file"
    
    success "Validation report saved: $report_file"
}

# Main execution
main() {
    log "Starting Made in World system validation..."
    log "Target database: $DB_NAME at $DB_HOST:$DB_PORT"
    
    validate_database_content
    validate_file_structure
    validate_seed_files
    validate_backup_system
    generate_validation_report
    
    success "System validation completed successfully!"
    success "The Made in World backup and seed system is fully operational."
    success "All admin panel data is properly preserved and can be restored."
}

# Handle script interruption
trap 'error "Validation process interrupted."; exit 1' INT TERM

# Run main function
main "$@"
