#!/bin/bash
set -e
# Connect to Postgres and dump database
# Dump database from the pod
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME | gzip > $BACKUP_FILE

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup failed!"
  exit 1
fi

file_size=$(stat -c "%s" "$BACKUP_FILE")

echo "The size of $BACKUP_FILE is $file_size bytes."

# Upload backup file to S3
# aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/$BACKUP_FILE

# # Check if upload succeeded
# if [ $? -ne 0 ]; then
#   echo "Error: Upload to S3 failed!"
#   exit 1
# fi

echo "Backup completed successfully!"