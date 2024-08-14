#!/bin/bash
set -fex

function log() {
  echo $(date)" ${1}"
}

# Set VArs
AZURE_DB_USERNAME='DTS Platform Operations SC'
AZURE_HOSTNAME='ccd-data-store-api-postgres-db-v15-prod.postgres.database.azure.com'
AZURE_DB='ccd_data_store'

SUBJECT='LAU - New Jurisdiction & Case Type Detection Monthly Check'

# Send email to slack
TO_ADDRESS='summary-alerts-aaaanwqtkx3vfbmtn645ac6uka@moj.org.slack.com'
DEFAULT_DATE=$(date +%Y%m%d)



function errorHandler() {
  local failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Failed to obtain a count of new case & jurisdiction data run ${DEFAULT_DATE}"
  log "${failed_error}"
  echo ""
}

trap errorHandler ERR

# Run the SQL query
NEW_ROWS=$(psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME} -d ${AZURE_DB} -c "
SELECT COUNT(*) as new_jc_types
FROM (
    select jurisdiction, case_type_id, min(created_date) as earliest_created_date from case_data
    group by case_type_id, jurisdiction
) as jcTypes
WHERE jcTypes.earliest_created_date >= CURRENT_DATE - INTERVAL '30 days'")

# Check if there are new rows
if [ "$NEW_ROWS" -gt 0 ]; then
    echo "${NEW_ROWS} New row(s) detected"
    swaks -f $FROM_ADDRESS -t $TO_ADDRESS --server smtp.sendgrid.net:587 --auth PLAIN -au apikey -ap $SENDGRID_APIKEY --header "Subject: ${SUBJECT}" --body "${NEW_ROWS} New row(s) detected"
    log "email sent"
else
    echo "No new rows detected."
fi
