# DIRECTORY
project-root/
├── backups/
│   ├── weekly/
│   ├── monthly/
│   └── yearly/
├── site
│   ├── db/
│       └── db.sql
│   └── html/
│       └── index.php
├── .env
├── backup_to_local.sh
└── backup.log

# USAGE
Run the script with one of the following arguments:
./backup.sh weekly
./backup.sh monthly
./backup.sh yearly

# What It Does
-Loads environment variables from .env
-Validates the backup type
-Creates a temporary directory for the backup
-Copies site files and database dump into the temp directory
-Archives the contents into a .tar.gz file
-Stores the archive in the appropriate bucket folder
-Logs each step to a timestamped log file
-Cleans up temporary files

# Logging
Logs are stored in ./logs/backup_<type>_<date>.log and include timestamps for each operation.

# Error Handling
If any step fails, the script:
-Logs the error
-Exits immediately to prevent partial backups

# Example Output
[2025-10-22 13:30:24] Starting weekly validation...
[2025-10-22 13:30:24] weekly type validated...
[2025-10-22 13:30:25] Creating backup directory...
[2025-10-22 13:30:25] Starting weekly backup...
[2025-10-22 13:30:25] Backup stored: ./backups/weekly/weekly_backup_2025-10-22.tar.gz
[2025-10-22 13:30:25] TMP files deleted.

# Testing Retention Policy
Create dummy files then backdate them:

touch ./backups/weekly/old_weekly.tar.gz
touch ./backups/monthly/old_monthly.tar.gz

touch -t $(date -d '70 days ago' +%Y%m%d%H%M) ./backups/weekly/old_weekly.tar.gz
touch -t $(date -d '400 days ago' +%Y%m%d%H%M) ./backups/monthly/old_monthly.tar.gz

