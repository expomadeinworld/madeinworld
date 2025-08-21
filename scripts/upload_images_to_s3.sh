#!/bin/bash

# Upload existing local images to S3 and update database URLs
# This script migrates local images to S3 for production deployment

set -e

# Configuration
BUCKET_NAME="madeinworld-product-images-admin"
REGION="eu-central-1"
LOCAL_UPLOADS_DIR="backend/catalog-service/uploads"
DB_HOST=${DB_HOST:-"ep-super-tooth-a2qtgrry.eu-central-1.aws.neon.tech"}
DB_USER=${DB_USER:-"neondb_owner"}
DB_NAME=${DB_NAME:-"neondb"}
# IMPORTANT: Do not hardcode passwords. Provide DB_PASSWORD via environment or AWS Secrets Manager.
if [ -z "${DB_PASSWORD}" ]; then
  echo "ERROR: DB_PASSWORD not set. Export DB_PASSWORD or use: DB_PASSWORD=\"...\" $0" >&2
  exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if local uploads directory exists
if [ ! -d "$LOCAL_UPLOADS_DIR" ]; then
    error "Local uploads directory not found: $LOCAL_UPLOADS_DIR"
    exit 1
fi

log "Starting image migration to S3..."

# Upload product images
if [ -d "$LOCAL_UPLOADS_DIR/products" ]; then
    log "Uploading product images..."
    for image in "$LOCAL_UPLOADS_DIR/products"/*; do
        if [ -f "$image" ]; then
            filename=$(basename "$image")
            # Extract product ID from filename (assuming format: productid_timestamp_originalname)
            product_id=$(echo "$filename" | cut -d'_' -f1)
            
            s3_key="products/$product_id/$(date +%s)000_$filename"
            s3_url="https://$BUCKET_NAME.s3.$REGION.amazonaws.com/$s3_key"
            
            log "Uploading $filename to S3..."
            if aws s3 cp "$image" "s3://$BUCKET_NAME/$s3_key" --region "$REGION"; then
                success "Uploaded $filename"
                
                # Update database with new S3 URL
                old_url="https://device-api.expomadeinworld.com/uploads/products/$filename"
                log "Updating database URL for $filename..."
                PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c \
                    "UPDATE product_images SET image_url = '$s3_url' WHERE image_url = '$old_url';" || true
            else
                error "Failed to upload $filename"
            fi
        fi
    done
fi

# Upload store images
if [ -d "$LOCAL_UPLOADS_DIR/stores" ]; then
    log "Uploading store images..."
    for image in "$LOCAL_UPLOADS_DIR/stores"/*; do
        if [ -f "$image" ]; then
            filename=$(basename "$image")
            s3_key="stores/$filename"
            s3_url="https://$BUCKET_NAME.s3.$REGION.amazonaws.com/$s3_key"
            
            log "Uploading $filename to S3..."
            if aws s3 cp "$image" "s3://$BUCKET_NAME/$s3_key" --region "$REGION"; then
                success "Uploaded $filename"
                
                # Update database with new S3 URL
                old_url="/uploads/stores/$filename"
                log "Updating database URL for $filename..."
                PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c \
                    "UPDATE stores SET image_url = '$s3_url' WHERE image_url = '$old_url';" || true
            else
                error "Failed to upload $filename"
            fi
        fi
    done
fi

# Upload subcategory images
if [ -d "$LOCAL_UPLOADS_DIR/subcategories" ]; then
    log "Uploading subcategory images..."
    for image in "$LOCAL_UPLOADS_DIR/subcategories"/*; do
        if [ -f "$image" ]; then
            filename=$(basename "$image")
            s3_key="subcategories/$filename"
            s3_url="https://$BUCKET_NAME.s3.$REGION.amazonaws.com/$s3_key"
            
            log "Uploading $filename to S3..."
            if aws s3 cp "$image" "s3://$BUCKET_NAME/$s3_key" --region "$REGION"; then
                success "Uploaded $filename"
                
                # Update database with new S3 URL
                old_url="/uploads/subcategories/$filename"
                log "Updating database URL for $filename..."
                PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c \
                    "UPDATE subcategories SET image_url = '$s3_url' WHERE image_url = '$old_url';" || true
            else
                error "Failed to upload $filename"
            fi
        fi
    done
fi

success "Image migration completed!"
log "All local images have been uploaded to S3 and database URLs updated."
