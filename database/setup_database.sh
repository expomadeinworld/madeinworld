#!/bin/bash

# Database Setup Script for Made in World
# This script creates the database, user, and applies the schema

set -e

# Configuration
DB_NAME="madeinworld_db"
DB_USER="madeinworld_admin"
DB_PASSWORD="madeinworld_password_2024"
DB_HOST="localhost"
DB_PORT="5432"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Made in World Database Setup ===${NC}"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Host: $DB_HOST:$DB_PORT"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        exit 1
    fi
}

# Check if PostgreSQL is running
echo -e "${YELLOW}1. Checking PostgreSQL connection...${NC}"
if pg_isready -h $DB_HOST -p $DB_PORT > /dev/null 2>&1; then
    print_status 0 "PostgreSQL is running"
else
    echo -e "${RED}✗ PostgreSQL is not running or not accessible${NC}"
    echo "Please start PostgreSQL first:"
    echo "  macOS (Homebrew): brew services start postgresql"
    echo "  macOS (Postgres.app): Start Postgres.app"
    echo "  Linux: sudo systemctl start postgresql"
    exit 1
fi

# Create database user
echo -e "\n${YELLOW}2. Creating database user...${NC}"
psql -h $DB_HOST -p $DB_PORT -U postgres -c "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
        CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
        ALTER ROLE $DB_USER CREATEDB;
    END IF;
END
\$\$;
" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_status 0 "Database user created/verified"
else
    echo -e "${RED}✗ Failed to create database user${NC}"
    echo "Trying with different superuser..."
    
    # Try with current system user
    psql -h $DB_HOST -p $DB_PORT -d postgres -c "
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
            CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
            ALTER ROLE $DB_USER CREATEDB;
        END IF;
    END
    \$\$;
    " > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_status 0 "Database user created/verified"
    else
        echo -e "${RED}✗ Failed to create database user${NC}"
        echo "Please run manually:"
        echo "  psql -U postgres -c \"CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';\""
        echo "  psql -U postgres -c \"ALTER ROLE $DB_USER CREATEDB;\""
        exit 1
    fi
fi

# Create database
echo -e "\n${YELLOW}3. Creating database...${NC}"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
SELECT 'CREATE DATABASE $DB_NAME'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\\gexec
" > /dev/null 2>&1

print_status $? "Database created/verified"

# Apply schema
echo -e "\n${YELLOW}4. Applying database schema...${NC}"
if [ -f "init.sql" ]; then
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f init.sql > /dev/null 2>&1
    print_status $? "Database schema applied"
else
    echo -e "${RED}✗ init.sql not found${NC}"
    echo "Please run this script from the database directory"
    exit 1
fi

# Apply migrations
echo -e "\n${YELLOW}5. Applying migrations...${NC}"
if [ -d "migrations" ]; then
    for migration in migrations/*.sql; do
        if [ -f "$migration" ]; then
            echo "Applying $(basename $migration)..."
            psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$migration" > /dev/null 2>&1
            print_status $? "Migration $(basename $migration) applied"
        fi
    done
else
    echo -e "${YELLOW}No migrations directory found, skipping...${NC}"
fi

# Apply seed data
echo -e "\n${YELLOW}6. Applying seed data...${NC}"
if [ -f "seed_data.sql" ]; then
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f seed_data.sql > /dev/null 2>&1
    print_status $? "Seed data applied"
else
    echo -e "${YELLOW}No seed_data.sql found, skipping...${NC}"
fi

# Verify setup
echo -e "\n${YELLOW}7. Verifying setup...${NC}"
table_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs)

if [ "$table_count" -gt 0 ]; then
    print_status 0 "Database setup verified ($table_count tables found)"
else
    print_status 1 "Database verification failed"
fi

echo -e "\n${GREEN}=== Database Setup Complete ===${NC}"
echo ""
echo "Connection details:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo ""
echo "Environment variables for services:"
echo "  export DB_HOST=$DB_HOST"
echo "  export DB_PORT=$DB_PORT"
echo "  export DB_NAME=$DB_NAME"
echo "  export DB_USER=$DB_USER"
echo "  export DB_PASSWORD=$DB_PASSWORD"
echo ""
echo "You can now start the order service:"
echo "  cd backend/order-service"
echo "  DB_PASSWORD=$DB_PASSWORD go run cmd/server/main.go"
