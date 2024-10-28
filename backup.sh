#!/bin/bash

# Configuration
S3_ENDPOINT="https://s3.us-east-1.amazonaws.com"
S3_BUCKET="XXX"
S3_ACCESS_KEY="XXX"
S3_SECRET_KEY="XXX"
BACKUP_BASE_DIR="/tmp/xtrabackup"
CHECKPOINT_DIR="/tmp/xtrabackup_checkpoints"
CURRENT_DATE=$(date +'%Y-%m-%d')
CURRENT_TIME=$(date +'%H-%M')

# Create backup directory if not exists
mkdir -p "$BACKUP_BASE_DIR"
mkdir -p "$CHECKPOINT_DIR"


# Determine if it is time for a full or incremental backup
if [ "$1" == "full" ]; then
    # Full backup
    FULL_BACKUP_DIR="${BACKUP_BASE_DIR}/full_${CURRENT_DATE}"
    mkdir -p "$FULL_BACKUP_DIR"

    # Run full backup and upload to S3
    xtrabackup --compress --parallel 8 --backup --stream=xbstream --extra-lsndir="$CHECKPOINT_DIR" --history=full --target-dir="$FULL_BACKUP_DIR" --page-tracking \
    | xbcloud put --storage=s3 --s3-endpoint="$S3_ENDPOINT" --s3-access-key="$S3_ACCESS_KEY" --s3-secret-key="$S3_SECRET_KEY" --s3-bucket="$S3_BUCKET" "full-backup/${CURRENT_DATE}/backup-full.xbstream"

    echo "Full backup completed for $CURRENT_DATE"

else
    # Incremental backup
    INCREMENTAL_BACKUP_DIR="${BACKUP_BASE_DIR}/incremental_${CURRENT_DATE}_${CURRENT_TIME}"
    mkdir -p "$INCREMENTAL_BACKUP_DIR"

    # Run incremental backup based on the last LSN from the full backup
    xtrabackup --compress --parallel 8 --backup --stream=xbstream --extra-lsndir="$CHECKPOINT_DIR" --incremental-basedir="$CHECKPOINT_DIR" --history=incremental --target-dir="$INCREMENTAL_BACKUP_DIR" --page-tracking \
    | xbcloud put --storage=s3 --s3-endpoint="$S3_ENDPOINT" --s3-access-key="$S3_ACCESS_KEY" --s3-secret-key="$S3_SECRET_KEY" --s3-bucket="$S3_BUCKET" "incremental-backup/${CURRENT_DATE}/${CURRENT_TIME}/backup-inc.xbstream"

    echo "Incremental backup completed for ${CURRENT_DATE} at ${CURRENT_TIME}"
fi
