#!/bin/bash
### Script to backup up Azure Postgres DBs to a named location
### Alliu Balogun 20/09/2018
###

#Server CREDENTIALS

AZURE_HOSTNAME="51.140.184.11"
AZURE_DB_USERNAME="ccd@ccd-data-store-api-postgres-db-v11-prod"
AZURE_DB="ccd_data_store"

# Location to place backups
backup_dir="/backups/CCD/case_data/"
#backup_dir="/backups/CCD/case_event/"

#String to append to the name of the backup files
backup_date=`date +%Y-%m-%d_%H-%M`

#Numbers of days you want to keep copies of your databases
#number_of_days=5

## Dump users
#pg_dumpall -g -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME} -d  postgres > $backup_dir/globals.sql


backupfile=$backup_dir
#backupfile=$backup_dir/ccd_db_dump.sql
##$AZURE_DB.$backup_date.sql
#### Using -Fd
date
## Dump Database. With the -c switch, use pg_restore to restore the DB
#pg_dump  -v  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -Fc -f $backupfile  
#pg_dump  -Fd -j16 -t case_data --compress=0 -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -f $backupfile  
#pg_dump  -Fd -j16 -t case_event --compress=0 -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -f $backupfile  
#pg_dump  -Fd -j62 --compress=0 -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -f $backupfile
#pg_dump  -Fd -j 8 -a -T case_event --compress=0 -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -f $backupfile
#pg_restore -v -j 8 --no-owner -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -Fd $backup_dir
pg_restore -v -j 8 -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -Fd $backup_dir
date

#find $backup_dir -type f -prune -mtime +$number_of_days -exec rm -f {} \;
