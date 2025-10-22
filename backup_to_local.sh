#!/bin/bash

# LOAD ENV VARS
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "Missing .env file at $ENV_FILE"
  exit 1
fi

DATE=$(date +%Y-%m-%d)
TYPE=$1  # weekly, monthly, yearly

# FUNCTIONS
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}
# log "$LOG_FILE"


error_exit() {
    log "ERROR: $1"
    exit 1
}

# VALIDATE TYPE
log "Starting $TYPE validation..."
if [[ "$TYPE" != "weekly" && "$TYPE" != "monthly" && "$TYPE" != "yearly" ]]; then
    error_exit "Invalid backup type: $TYPE. Use weekly, monthly, or yearly."
fi

log "$TYPE type validated..."

# CREATE BACKUP FILE LOCATION
log "Creating backup directory..."
BACKUP_NAME="${TYPE}_backup_${DATE}.tar.gz"
TMP_DIR="./tmp_${TYPE}_${DATE}"
mkdir -p "$TMP_DIR" || error_exit "Failed to create temp directory."

log "Starting $TYPE backup..."

# COPY DUMMY DB
# cp "$DB_DUMP" "$TMP_DIR/db.sql" || error_exit "Failed to copy DB dump."
cp -r "$SITE_DIR/." "$TMP_DIR" || error_exit "Failed to copy site files."
cp "$DB_DUMP" "$TMP_DIR" || error_exit "Failed to copy DB dump."

# ARCHIVE FILES AND DB
tar -czf "$BUCKET/$TYPE/$BACKUP_NAME" -C "$TMP_DIR" .
if [ $? -ne 0 ]; then
    error_exit "Failed to create archive."
fi

# UPLOAD TO TMP LOCATION
# mkdir -p "$BUCKET/$TYPE"
# cp "$TMP_DIR/$BACKUP_NAME" "$BUCKET/$TYPE/$BACKUP_NAME" ||  error_exit "Failed to copy backup to bucket."

log "Backup stored: $BUCKET/$TYPE/$BACKUP_NAME"

# REMOVE TEMP
rm -rf "$TMP_DIR"
log "TMP files deleted."

