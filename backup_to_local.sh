#!/bin/bash

# LOAD ENV VARS
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs) # Filter out comments and load variables into current shell session
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

# CREATE BACKUP FILE LOCATION
log "Creating backup directory..."
BACKUP_NAME="${TYPE}_backup_${DATE}.tar.gz"
TMP_DIR="./tmp_${TYPE}_${DATE}"
mkdir -p "$TMP_DIR" || error_exit "Failed to create temp directory."

log "Starting $TYPE backup..."

# -- UNTESTED --
# CREATE BACKUP FILE LOCATION
log "Creating tmp folder..."
mkdir -p "$TMP_BUCKET" || error_exit "Failed to create temp directory."
DUMP_FILE="$TMP_BUCKET/${TYPE}_backup_${DATE}.sql"

# Export DB to tmp folder
log "Exporting live DB to $DUMP_FILE..."
log "$LIVE_DB_HOST"
log "$LIVE_SSH_USER"
# ssh $LIVE_SSH_USER "mysqldump --opt --user='$LIVE_DB_USER' -p'$LIVE_DB_PASS' --host='$LIVE_DB_HOST' --no-tablespaces '$LIVE_DB_NAME'" > "$DUMP_FILE" || error_exit "Failed to export database."

ssh -T "$LIVE_SSH_USER" \
  "mysqldump \
    --opt \
    --user=$LIVE_DB_USER \
    --password=$LIVE_DB_PASS \
    --host=$LIVE_DB_HOST \
    --no-tablespaces \
    $LIVE_DB_NAME" \
  > "$DUMP_FILE"




# Check if dump file exists and is not empty
if [ ! -s "$DUMP_FILE" ]; then
  error_exit "Database dump file is missing or empty."
fi

log "Database dump file created successfully."
# -- UNTESTED --

# COPY DB from local
cp -r "$SITE_DIR/." "$TMP_DIR" || error_exit "Failed to copy site files." 
cp "$DB_DUMP" "$TMP_DIR" || error_exit "Failed to copy DB dump."

# ARCHIVE FILES AND DB
tar -czf "$BUCKET/$TYPE/$BACKUP_NAME" -C "$TMP_DIR" . # Create archive file from the contents of $TMP_DIR
if [ $? -ne 0 ]; then
    error_exit "Failed to create archive."
fi

log "Backup stored: $BUCKET/$TYPE/$BACKUP_NAME"

# REMOVE TEMP
rm -rf "$TMP_DIR"
log "TMP files deleted."

# -- RETENTION POLICY--
log "Applying retention policy for $TYPE backups..."

find "$BUCKET/$TYPE" -type f -name "*.tar.gz" | while read -r file; do # Find and loop through all of the .tag.gz file in backup TYPE folder
    file_date=$(date -r "$file" +%s) # Last modified timestamp
    now=$(date +%s)
    age_days=$(((now - file_date)/ 86400))

    if [[ "$TYPE" == "weekly" && "$age_days" -gt 60 ]]; then
        rm "$file" && log "Deleted old weekly backup: $file"
    elif [[ "$TYPE" == "monthly" && "$age_days" -gt 365 ]]; then
        rm "$file" && log "Deleted old monthly backup: $file"
    fi
done