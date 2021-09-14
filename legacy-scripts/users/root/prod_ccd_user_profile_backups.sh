#!/bin/bash
### Script to backup up Azure Postgres DBs to a named location
### Alliu Balogun 20/09/2018
###

#Server CREDENTIALS

AZURE_HOSTNAME="ccd-user-profile-api-postgres-db-prod.postgres.database.azure.com"
AZURE_DB_USERNAME="ccd@ccd-user-profile-api-postgres-db-prod"
AZURE_DB="ccd_user_profile"

# Location to place backups
backup_dir="/backups/CCD/"

#String to append to the name of the backup files
backup_date=`date +%Y-%m-%d_%H-%M`

#Numbers of days you want to keep copies of your databases
number_of_days=5

## Dump users
#pg_dumpall -g -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME} -d  postgres > $backup_dir/globals.sql

#backupfile=$backup_dir$AZURE_DB.$backup_date.sql.gz
backupfile=$backup_dir$AZURE_DB.$backup_date.tar

## Dump Database. With the -c switch, use pg_restore to restore the DB
#pg_dump -Fc  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} | gzip > $backupfile > $backupfile
pg_dump -Fc  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB}  > $backupfile

find $backup_dir -type f -prune -mtime +$number_of_days -exec rm -f {} \;
