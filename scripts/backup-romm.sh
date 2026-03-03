#!/bin/bash
# RomM Database Backup Script
# Usage: ./scripts/backup-romm.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups/romm"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="romm-db-backup-${DATE}.sql"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

echo "Starting RomM database backup..."

# Check if romm-db container is running
if ! docker ps --format "table {{.Names}}" | grep -q "romm-db"; then
    echo "Error: romm-db container is not running!"
    echo "   Start RomM first: make deploy-service romm"
    exit 1
fi

# Create database dump
echo "Creating database dump..."
docker exec romm-db mysqldump \
    --single-transaction \
    --routines \
    --triggers \
    -u root \
    -p$(docker exec romm-db printenv MARIADB_ROOT_PASSWORD) \
    romm > "${BACKUP_DIR}/${BACKUP_FILE}"

# Compress the backup
echo "Compressing backup..."
gzip "${BACKUP_DIR}/${BACKUP_FILE}"

# Create a "latest" symlink
ln -sf "${BACKUP_FILE}.gz" "${BACKUP_DIR}/romm-db-latest.sql.gz"

echo "Backup completed: ${BACKUP_DIR}/${BACKUP_FILE}.gz"
echo "Latest backup: ${BACKUP_DIR}/romm-db-latest.sql.gz"

# Show backup size
echo "Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_FILE}.gz" | cut -f1)"

# Clean up old backups (keep last 7 days)
echo "Cleaning up old backups (keeping last 7)..."
find "${BACKUP_DIR}" -name "romm-db-backup-*.sql.gz" -mtime +7 -delete

echo "RomM database backup completed!"
