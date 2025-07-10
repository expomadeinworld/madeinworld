#!/bin/bash

# Made in World Database Schema Generation Script
# This script generates the current database schema
# Usage: ./generate_schema.sh

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

# Check if required tools are installed
check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v pg_dump &> /dev/null; then
        error "pg_dump is not installed. Please install PostgreSQL client tools."
        exit 1
    fi
    
    success "All dependencies are available."
}

# Test database connection
test_connection() {
    log "Testing database connection..."
    
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$DB_NAME"
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

# Generate current schema
generate_schema() {
    log "Generating current database schema..."
    
    local schema_file="$PROJECT_ROOT/database/current_schema.sql"
    local conn_str="host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$DB_NAME"
    
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    # Create schema header
    cat > "$schema_file" << EOF
-- Made in World Database Schema - Current State
-- Generated on: $(date)
-- Source: Current database structure

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

EOF
    
    # Generate schema-only dump
    pg_dump "$conn_str" --schema-only --no-owner --no-privileges >> "$schema_file"
    
    success "Current schema generated: database/current_schema.sql"
}

# Main execution
main() {
    log "Starting Made in World schema generation process..."
    log "Target database: $DB_NAME at $DB_HOST:$DB_PORT"
    
    check_dependencies
    test_connection
    generate_schema
    
    success "Schema generation completed successfully!"
}

# Handle script interruption
trap 'error "Schema generation process interrupted."; exit 1' INT TERM

# Run main function
main "$@"
