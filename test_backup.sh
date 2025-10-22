#!/bin/bash

# test_backup.sh - Validates backup creation and retention policy

# CONFIG
ENV_FILE=".env"
source "$ENV_FILE"

DATE=$(date +%Y-%m-%d)
LOG="test_backup_${DATE}.log"
TYPE_WEEKLY="weekly"
TYPE_MONTHLY="monthly"
TYPE_YEARLY="yearly"

# Create dummy old backups
weekly_old="./backups/weekly/old_weekly_backup.tar.gz"
monthly_old="./backups/monthly/old_monthly_backup.tar.gz"
yearly_old="./backups/yearly/old_yearly_backup.tar.gz"


touch "$weekly_old"
touch -t $(date -d '80 days ago' +%Y%m%d%H%M) "$weekly_old"

touch "$monthly_old"
touch -t $(date -d '400 days ago' +%Y%m%d%H%M) "$monthly_old"

echo "Starting backup test..." | tee -a "$LOG"

# Run weekly backup
echo "Running weekly backup..." | tee -a "$LOG"
./backup_to_local.sh "$TYPE_WEEKLY"

# Check for new weekly backup
new_weekly=$(ls ./backups/weekly/weekly_backup_${DATE}.tar.gz 2>/dev/null)
if [ -f "$new_weekly" ]; then
  echo "✅ Weekly backup created: $new_weekly" | tee -a "$LOG"
else
  echo "❌ Weekly backup not found!" | tee -a "$LOG"
fi

# Check if old weekly backup was deleted
if [ ! -f "$weekly_old" ]; then
  echo "✅ Old weekly backup deleted (retention passed)" | tee -a "$LOG"
else
  echo "❌ Old weekly backup still exists (retention failed)" | tee -a "$LOG"
fi

# Run monthly backup
echo "Running monthly backup..." | tee -a "$LOG"
./backup_to_local.sh "$TYPE_MONTHLY"

# Check for new monthly backup
new_monthly=$(ls ./backups/monthly/monthly_backup_${DATE}.tar.gz 2>/dev/null)
if [ -f "$new_monthly" ]; then
  echo "✅ Monthly backup created: $new_monthly" | tee -a "$LOG"
else
  echo "❌ Monthly backup not found!" | tee -a "$LOG"
fi

# Check if old monthly backup was deleted
if [ ! -f "$monthly_old" ]; then
  echo "✅ Old monthly backup deleted (retention passed)" | tee -a "$LOG"
else
  echo "❌ Old monthly backup still exists (retention failed)" | tee -a "$LOG"
fi

# Run yearly backup
echo "Running yearly backup..." | tee -a "$LOG"
./backup_to_local.sh "$TYPE_YEARLY"

# Check for new monthly backup
new_yearly=$(ls ./backups/yearly/yearly_backup_${DATE}.tar.gz 2>/dev/null)
if [ -f "$new_yearly" ]; then
  echo "✅ Yearly backup created: $new_yearly" | tee -a "$LOG"
else
  echo "❌ Yearly backup not found!" | tee -a "$LOG"
fi

echo "Backup test completed." | tee -a "$LOG"
