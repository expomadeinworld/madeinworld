#!/bin/bash

# Made in World Database Backup Script
# This script creates a comprehensive backup of the PostgreSQL database
# Usage: ./backup_database.sh [backup_name]

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Database configuration (from environment or defaults)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-madeinworld_admin}"
DB_NAME="${DB_NAME:-madeinworld_db}"
DB_PASSWORD="${DB_PASSWORD:-}"

# Backup file naming
BACKUP_NAME="${1:-database_backup_$TIMESTAMP}"
BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME}.sql"
BACKUP_COMPRESSED="$BACKUP_DIR/${BACKUP_NAME}.sql.gz"

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
    
    if ! command -v pg_dump &> /dev/null; then
        error "pg_dump is not installed. Please install PostgreSQL client tools."
        exit 1
    fi
    
    if ! command -v gzip &> /dev/null; then
        error "gzip is not installed."
        exit 1
    fi
    
    success "All dependencies are available."
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    log "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    success "Backup directory ready: $BACKUP_DIR"
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

# Create database backup
create_backup() {
    log "Creating database backup..."
    log "Backup file: $BACKUP_FILE"
    
    # Build connection parameters
    local pg_dump_args=(
        "--host=$DB_HOST"
        "--port=$DB_PORT"
        "--username=$DB_USER"
        "--dbname=$DB_NAME"
        "--verbose"
        "--clean"
        "--if-exists"
        "--create"
        "--format=plain"
        "--encoding=UTF8"
        "--no-password"
    )
    
    # Set password if provided
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    # Create the backup
    if pg_dump "${pg_dump_args[@]}" > "$BACKUP_FILE"; then
        success "Database backup created successfully."
    else
        error "Failed to create database backup."
        exit 1
    fi
    
    # Get backup file size
    local backup_size=$(du -h "$BACKUP_FILE" | cut -f1)
    log "Backup size: $backup_size"
}

# Compress backup file
compress_backup() {
    log "Compressing backup file..."
    
    if gzip -c "$BACKUP_FILE" > "$BACKUP_COMPRESSED"; then
        success "Backup compressed successfully."
        
        # Remove uncompressed file to save space
        rm "$BACKUP_FILE"
        
        # Get compressed file size
        local compressed_size=$(du -h "$BACKUP_COMPRESSED" | cut -f1)
        log "Compressed size: $compressed_size"
    else
        error "Failed to compress backup file."
        warning "Keeping uncompressed backup: $BACKUP_FILE"
    fi
}

# Generate backup summary
generate_summary() {
    log "Generating backup summary..."
    
    local summary_file="$BACKUP_DIR/${BACKUP_NAME}_summary.txt"
    
    cat > "$summary_file" << EOF
Made in World Database Backup Summary
=====================================

Backup Details:
- Backup Name: $BACKUP_NAME
- Timestamp: $TIMESTAMP
- Database: $DB_NAME
- Host: $DB_HOST:$DB_PORT
- User: $DB_USER

Files Created:
- Backup: ${BACKUP_NAME}.sql.gz
- Summary: ${BACKUP_NAME}_summary.txt

Backup Command Used:
pg_dump --host=$DB_HOST --port=$DB_PORT --username=$DB_USER --dbname=$DB_NAME --verbose --clean --if-exists --create --format=plain --encoding=UTF8 --no-password

Restoration Command:
gunzip -c ${BACKUP_NAME}.sql.gz | psql --host=<host> --port=<port> --username=<user> --dbname=<dbname>

Notes:
- This backup includes the complete database schema and all data
- The backup is compressed using gzip
- Use the restoration command above to restore the database
- Ensure the target database exists before restoration

Generated on: $(date)
EOF

    success "Backup summary created: $summary_file"
}

# Main execution
main() {
    log "Starting Made in World database backup process..."
    log "Target database: $DB_NAME at $DB_HOST:$DB_PORT"
    
    check_dependencies
    create_backup_dir
    test_connection
    create_backup
    compress_backup
    generate_summary
    
    success "Database backup completed successfully!"
    success "Backup location: $BACKUP_COMPRESSED"
    
    # List recent backups
    log "Recent backups in $BACKUP_DIR:"
    ls -lah "$BACKUP_DIR"/*.sql.gz 2>/dev/null | tail -5 || log "No previous backups found."
}

# Handle script interruption
trap 'error "Backup process interrupted."; exit 1' INT TERM

# Run main function
main "$@"
