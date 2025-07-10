#!/bin/bash

# Made in World Database Restoration Script
# This script restores the database from seed files or backup
# Usage: ./restore_database.sh [backup_file|seeds] [target_db_name]

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEEDS_DIR="$PROJECT_ROOT/database/seeds"
BACKUPS_DIR="$PROJECT_ROOT/backups"

# Database configuration (from environment or defaults)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-madeinworld_admin}"
DB_NAME="${DB_NAME:-madeinworld_db}"
DB_PASSWORD="${DB_PASSWORD:-}"

# Script parameters
RESTORE_SOURCE="${1:-seeds}"  # 'seeds' or backup file path
TARGET_DB_NAME="${2:-$DB_NAME}"

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

# Show usage information
show_usage() {
    echo "Usage: $0 [backup_file|seeds] [target_db_name]"
    echo ""
    echo "Parameters:"
    echo "  backup_file    Path to backup file (.sql or .sql.gz)"
    echo "  seeds          Use current seed files (default)"
    echo "  target_db_name Target database name (default: $DB_NAME)"
    echo ""
    echo "Examples:"
    echo "  $0 seeds                                    # Restore from seed files"
    echo "  $0 backups/backup_20240101_120000.sql.gz   # Restore from backup"
    echo "  $0 seeds my_test_db                         # Restore seeds to test database"
    echo ""
}

# Check if required tools are installed
check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v psql &> /dev/null; then
        error "psql is not installed. Please install PostgreSQL client tools."
        exit 1
    fi
    
    if ! command -v createdb &> /dev/null; then
        error "createdb is not installed. Please install PostgreSQL client tools."
        exit 1
    fi
    
    if ! command -v dropdb &> /dev/null; then
        error "dropdb is not installed. Please install PostgreSQL client tools."
        exit 1
    fi
    
    if [ "$RESTORE_SOURCE" != "seeds" ] && [[ "$RESTORE_SOURCE" == *.gz ]]; then
        if ! command -v gunzip &> /dev/null; then
            error "gunzip is not installed."
            exit 1
        fi
    fi
    
    success "All dependencies are available."
}

# Test database connection
test_connection() {
    log "Testing database connection..."
    
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=postgres"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    if psql "$conn_str" -c "SELECT 1;" &> /dev/null; then
        success "Database connection successful."
    else
        error "Failed to connect to database. Please check your connection settings."
        exit 1
    fi
}

# Validate restore source
validate_restore_source() {
    log "Validating restore source: $RESTORE_SOURCE"
    
    if [ "$RESTORE_SOURCE" = "seeds" ]; then
        if [ ! -f "$SEEDS_DIR/seed_all.sql" ]; then
            error "Seed file not found: $SEEDS_DIR/seed_all.sql"
            error "Please run ./scripts/generate_seeds.sh first."
            exit 1
        fi
        success "Using seed files from: $SEEDS_DIR"
    else
        if [ ! -f "$RESTORE_SOURCE" ]; then
            error "Backup file not found: $RESTORE_SOURCE"
            exit 1
        fi
        success "Using backup file: $RESTORE_SOURCE"
    fi
}

# Confirm destructive operation
confirm_operation() {
    if [ "$TARGET_DB_NAME" = "$DB_NAME" ]; then
        warning "You are about to restore to the main database: $TARGET_DB_NAME"
        warning "This will PERMANENTLY DELETE all current data!"
        echo ""
        read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation
        
        if [ "$confirmation" != "yes" ]; then
            log "Operation cancelled by user."
            exit 0
        fi
    else
        log "Restoring to database: $TARGET_DB_NAME"
    fi
}

# Drop and recreate database
recreate_database() {
    log "Recreating database: $TARGET_DB_NAME"
    
    # Drop database if it exists
    dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$TARGET_DB_NAME" 2>/dev/null || true
    
    # Create database
    if createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$TARGET_DB_NAME"; then
        success "Database recreated: $TARGET_DB_NAME"
    else
        error "Failed to recreate database."
        exit 1
    fi
}

# Initialize database schema
initialize_schema() {
    log "Initializing database schema..."
    
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$TARGET_DB_NAME"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    if psql "$conn_str" -f "$PROJECT_ROOT/database/current_schema.sql" >/dev/null 2>&1; then
        success "Database schema initialized."
    else
        error "Failed to initialize database schema."
        exit 1
    fi
}

# Restore from seed files
restore_from_seeds() {
    log "Restoring from seed files..."
    
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$TARGET_DB_NAME"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    if psql "$conn_str" -f "$SEEDS_DIR/seed_all.sql" >/dev/null 2>&1; then
        success "Database restored from seed files."
    else
        error "Failed to restore from seed files."
        exit 1
    fi
}

# Restore from backup file
restore_from_backup() {
    log "Restoring from backup file..."

    # For backup files, we don't recreate the database since the backup includes CREATE DATABASE
    # Instead, we drop the existing database and let the backup recreate it
    log "Dropping existing database for backup restoration..."
    dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$TARGET_DB_NAME" 2>/dev/null || true

    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=postgres"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi

    if [[ "$RESTORE_SOURCE" == *.gz ]]; then
        # Compressed backup
        if gunzip -c "$RESTORE_SOURCE" | psql "$conn_str" >/dev/null 2>&1; then
            success "Database restored from compressed backup."
        else
            error "Failed to restore from compressed backup."
            exit 1
        fi
    else
        # Uncompressed backup
        if psql "$conn_str" -f "$RESTORE_SOURCE" >/dev/null 2>&1; then
            success "Database restored from backup."
        else
            error "Failed to restore from backup."
            exit 1
        fi
    fi
}

# Verify restoration
verify_restoration() {
    log "Verifying restoration..."
    
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$TARGET_DB_NAME"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    # Check if main tables exist and have data
    local tables=("manufacturers" "stores" "product_categories" "products")
    local verification_passed=true
    
    for table in "${tables[@]}"; do
        local count=$(psql "$conn_str" -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' ')
        
        if [ -n "$count" ] && [ "$count" -gt 0 ]; then
            success "✓ $table: $count records"
        else
            error "✗ $table: No data or table missing"
            verification_passed=false
        fi
    done
    
    if [ "$verification_passed" = true ]; then
        success "Database restoration verified successfully."
    else
        error "Database restoration verification failed."
        return 1
    fi
}

# Generate restoration report
generate_restoration_report() {
    log "Generating restoration report..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$PROJECT_ROOT/restoration_report_$timestamp.txt"
    
    cat > "$report_file" << EOF
Made in World Database Restoration Report
=========================================
Generated on: $(date)
Target Database: $TARGET_DB_NAME
Restore Source: $RESTORE_SOURCE

Restoration Summary:
- Database recreation: SUCCESS
- Schema initialization: SUCCESS
- Data restoration: SUCCESS
- Verification: SUCCESS

Database Details:
- Host: $DB_HOST:$DB_PORT
- Database: $TARGET_DB_NAME
- User: $DB_USER

Table Counts After Restoration:
EOF
    
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$TARGET_DB_NAME"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    local tables=("manufacturers" "stores" "product_categories" "subcategories" "products" "product_images" "product_category_mapping" "product_subcategory_mapping" "inventory")
    
    for table in "${tables[@]}"; do
        local count=$(psql "$conn_str" -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' ')
        printf "%-30s: %s\n" "$table" "$count" >> "$report_file"
    done
    
    success "Restoration report saved: $report_file"
}

# Main execution
main() {
    # Show usage if help requested
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    log "Starting Made in World database restoration process..."
    log "Restore source: $RESTORE_SOURCE"
    log "Target database: $TARGET_DB_NAME at $DB_HOST:$DB_PORT"
    
    check_dependencies
    test_connection
    validate_restore_source
    confirm_operation

    if [ "$RESTORE_SOURCE" = "seeds" ]; then
        recreate_database
        initialize_schema
        restore_from_seeds
    else
        restore_from_backup
    fi
    
    verify_restoration
    generate_restoration_report
    
    success "Database restoration completed successfully!"
    success "Database $TARGET_DB_NAME is ready for use."
}

# Handle script interruption
trap 'error "Restoration process interrupted."; exit 1' INT TERM

# Run main function
main "$@"
