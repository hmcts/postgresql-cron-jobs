#!/bin/bash
set -eu

source 'function-declarations.sh'

log "Logging into psql and running query"

psql -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB}  \
     --command "SELECT reference, state, data ->>'hearingCentre' AS hearing_centre, data ->>'ariaListingReference' AS listing_Reference, data ->>'appealReferenceNumber' AS SC_number, data ->>'isDecisionAllowed' AS decision_outcome, data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded' as dateUploaded FROM case_data WHERE case_type_id = 'Asylum' AND jurisdiction = 'IA' and state ='decided' and DATE(data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded') > (CURRENT_DATE - 7)" \
     --csv >> ${OUTPUT_FILE_NAME}

log "Query ran and output file created file created"