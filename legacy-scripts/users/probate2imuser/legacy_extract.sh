#!/bin/bash
# vi:syntax=sh

## IRON MOUNTAIN DUMP SCRIPT
# JIRA - https://tools.hmcts.net/jira/browse/RDO-3276

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

  # Set date and output VARS

DEFAULT_DATE=$(date +%Y%m%d)
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=${DEFAULT_DATE}alliu.txt
OUTPUT_SED_FILE_NAME=SIM${DEFAULT_DATE}.txt
FILELOCAL=${DEFAULT_DATE}IM_legacy.txt

 # The QUERY 1 - Output data into a temp table called probe

QUERY=$(cat <<EOF

SELECT  deceased_title AS estate_title, deceased_forenames AS estate_forenames , deceased_surname AS estate_surname, date_of_death1, date_of_death2, date_of_birth , deceased_age_at_death AS estate_age_at_death, regexp_replace(deceased_address, E'[\\r\\n]+', ' ', 'g' ) AS estate_address_line_1, '' AS estate_address_line_2, '' AS estate_address_line_3, '' AS estate_address_line_4,  '' AS estate_postcode  , CASE WHEN ccd_case_no IS NULL THEN probate_number END AS grant_probate_number, grant_issued_date, grantee1_title, grantee1_forenames, grantee1_surname , regexp_replace(grantee1_address, E'[\\r\\n]+', ' ', 'g' ) AS grantee1_address_line_1, '' AS grantee1_address_line_2, '' AS grantee1_address_line_3, '' AS grantee1_address_line_4,  '' AS grantee1_postcode , grantee2_title, grantee2_forenames, grantee2_surname , regexp_replace(grantee2_address, E'[\\r\\n]+', ' ', 'g' ) AS grantee2_address_line_1, '' AS grantee2_address_line_2,  '' AS grantee2_address_line_3,  '' AS grantee2_address_line_4,  '' AS grantee2_postcode , grantee3_title, grantee3_forenames, grantee3_surname , regexp_replace(grantee3_address, E'[\\r\\n]+', ' ', 'g' ) AS grantee3_address_line_1,  '' AS grantee3_address_line_2,  '' AS grantee3_address_line_3,  '' AS grantee3_address_line_4,  '' AS grantee3_postcode , grantee4_title, grantee4_forenames, grantee4_surname , regexp_replace(grantee4_address, E'[\\r\\n]+', ' ', 'g' ) AS grantee4_address_line_1,  '' AS grantee4_address_line_2,  '' AS grantee4_address_line_3,  '' AS grantee4_address_line_4,  '' AS grantee4_postcode , grant_applicant_type, applicant_surname , regexp_replace(applicant_address, E'[\\r\\n]+', ' ', 'g' ) AS applicant_address_line_1, '' AS applicant_address_line_2, '' AS applicant_address_line_3, '' AS applicant_address_line_4, '' AS applicant_postcode, gross_estate_value, net_estate_value , app_case_type, registry_name AS reg_name from grant_applications_flat where app_received_date between '1996-01-01' and '1996-12-31' ORDER BY app_received_date;
EOF
)

 # Connect to DB and pass QUERY above but use -t switch to disable tuples

psql -h probatemandb-postgres-db-prod.postgres.database.azure.com -U probateman_user@probatemandb-postgres-db-prod -d probatemandb -c "${QUERY}" -P format=u  > ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}

 

# SED to to clean out \N (NULLS)

sed -r -e 's/$/|/' -e '1 s/^.*$//'  -e '/\(/d' ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME} > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Extract Complete"

#SFTP CONNECTION
