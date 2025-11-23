#!/bin/bash

# Matomo mariadb backup script

#Define a timestamp function
timestamp() {
date "+%b %d %Y %T %Z"
}

#Define load environment variables file function
envup() {
  local file=$1

  if [ -f $file ]; then
    set -a
    source $file
    set +a
  else
    echo "No $file file found" 1>&2
    return 1
  fi
}

MARIA_DB_SERVICE=db
BACKUP_DIR=./backup
LOG=./backup.log
# Load matomo db environme variables file
envup ./.db.secret

# Add timestamp
echo "$(timestamp): Matmo-DB-backup started" | tee -a $LOG
echo "-------------------------------------------------------------------------------" | tee -a $LOG


# Execute Mariadb dump command through docker-compose
docker run -i --network backend --rm mariadb mariadb-dump -h ${MARIA_DB_SERVICE} --user=matomo --password=${MATOMO_DB_PASSWORD} matomo > ${BACKUP_DIR}/matomo-db-dump.sql 2>> $LOG

# Compress dump file
tar zcf ${BACKUP_DIR}/matomo-mariadb-database-$(date +%Y-%m-%d-%H.%M.%S).sql.tar.gz ${BACKUP_DIR}/matomo-db-dump.sql

# Delete dump file
rm ${BACKUP_DIR}/matomo-db-dump.sql

# Delete old backup files
find ${BACKUP_DIR} -mtime +10 -exec rm {} \;

# Add timestamp
echo "-------------------------------------------------------------------------------" | tee -a $LOG
echo "$(timestamp): Matomo DB backup finished" | tee -a $LOG
printf "\n" | tee -a $LOG
