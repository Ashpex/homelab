#!/bin/bash
# RomM Database Restore Script
# Usage: ./scripts/restore-romm.sh [backup-file.sql.gz]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups/romm"
BACKUP_FILE="${1:-${BACKUP_DIR}/romm-db-latest.sql.gz}"

echo "Starting RomM database restore..."
echo "Backup file: ${BACKUP_FILE}"

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Error: Backup file not found: ${BACKUP_FILE}"
    echo ""
    echo "Available backups:"
    ls -la "${BACKUP_DIR}"/romm-db-backup-*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

# Check if romm-db container is running
if ! docker ps --format "table {{.Names}}" | grep -q "romm-db"; then
    echo "Error: romm-db container is not running!"
    echo "   Start RomM first: make deploy-service romm"
    exit 1
fi

# Confirm restore
echo ""
echo "WARNING: This will REPLACE the current RomM database!"
echo "   Current database will be PERMANENTLY LOST!"
echo ""
read -p "Are you sure you want to restore? (type 'YES' to continue): " confirm

if [ "$confirm" != "YES" ]; then
    echo "Restore cancelled."
    exit 1
fi

# Stop RomM service (but keep database running)
echo "Stopping RomM application..."
docker stop romm || true

# Extract and restore database
echo "Restoring database from backup..."
gunzip -c "${BACKUP_FILE}" | docker exec -i romm-db mysql \
    -u root \
    -p$(docker exec romm-db printenv MARIADB_ROOT_PASSWORD) \
    romm

# Restart RomM
echo "Starting RomM application..."
docker start romm

# Wait for RomM to be ready
echo "Waiting for RomM to start..."
sleep 10

echo "RomM database restore completed!"
