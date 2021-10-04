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
OUTPUT_FILE_NAME=${DEFAULT_DATE}_IM_1999_2004-2.txt
OUTPUT_SED_FILE_NAME=SIM${DEFAULT_DATE}.txt
FILELOCAL=${DEFAULT_DATE}IM_legacy.txt

 # The QUERY 1 - Output data into a temp table called probe

QUERY=$(cat <<EOF

SELECT  ga.deceased_title AS estate_title, ga.deceased_forenames AS estate_forenames , ga.deceased_surname AS estate_surname, ga.date_of_death1, ga.date_of_death2, ga.date_of_birth , ga.deceased_age_at_death AS estate_age_at_death, regexp_replace(dr.estate1_address_line_1_split, E'[\\r\\n]+', ' ', 'g' ) AS estate_address_line_1, dr.estate1_address_line_2_split AS estate_address_line_2, dr.estate1_address_line_3_split AS estate_address_line_3, dr.estate1_address_line_4_split AS estate_address_line_4,  dr.estate1_postcode_split AS estate_postcode  , CASE WHEN ga.ccd_case_no IS NULL THEN ga.probate_number ELSE ga.ccd_case_no END AS grant_probate_number, ga.grant_issued_date, ga.grantee1_title, ga.grantee1_forenames,  CASE  WHEN ga.grantee1_surname = 'CALENDAR' THEN ''  ELSE ga.grantee1_surname END AS grantee1_surname , regexp_replace(dr.grantee1_address_line_1_split, E'[\\r\\n]+', ' ', 'g' ) AS grantee1_address_line_1, dr.grantee1_address_line_2_split AS grantee1_address_line_2, dr.grantee1_address_line_3_split AS grantee1_address_line_3, dr.grantee1_address_line_4_split AS grantee1_address_line_4,  dr.grantee1_postcode_split AS grantee1_postcode , ga.grantee2_title, ga.grantee2_forenames, ga.grantee2_surname , regexp_replace(ga.grantee2_address, E'[\\r\\n]+', ' ', 'g' ) AS grantee2_address_line_1, '' AS grantee2_address_line_2,  '' AS grantee2_address_line_3,  '' AS grantee2_address_line_4,  '' AS grantee2_postcode , ga.grantee3_title, ga.grantee3_forenames, ga.grantee3_surname , regexp_replace(ga.grantee3_address, E'[\\r\\n]+', ' ', 'g' ) AS grantee3_address_line_1,  '' AS grantee3_address_line_2,  '' AS grantee3_address_line_3,  '' AS grantee3_address_line_4,  '' AS grantee3_postcode , ga.grantee4_title, ga.grantee4_forenames, ga.grantee4_surname , regexp_replace(ga.grantee4_address, E'[\\r\\n]+', ' ', 'g' ) AS grantee4_address_line_1,  '' AS grantee4_address_line_2,  '' AS grantee4_address_line_3,  '' AS grantee4_address_line_4,  '' AS grantee4_postcode , ga.grant_applicant_type, ga.applicant_surname , regexp_replace(dr.applicant1_address_line_1_split, E'[\\r\\n]+', ' ', 'g' ) AS applicant_address_line_1, dr.applicant1_address_line_2_split AS applicant_address_line_2, dr.applicant1_address_line_3_split AS applicant_address_line_3, dr.applicant1_address_line_4_split AS applicant_address_line_4, dr.applicant1_postcode_split AS applicant_postcode, ga.gross_estate_value, ga.net_estate_value , CASE  WHEN ga.app_case_type = 'Reseal Probate' THEN 'COLONIAL RESEAL (PROBATE)'   WHEN app_case_type = 'Reseal Admon' THEN 'COLONIAL RESEAL (ADMON / WILL)'  ELSE UPPER(ga.app_case_type) END AS app_case_type, ga.registry_name AS reg_name from grant_applications_flat ga, dr_addresses_cleansed dr where ga.probate_number = dr.probateman_id AND ga.app_received_date between '1999-01-01' and '2004-12-31' ORDER BY ga.app_received_date;
EOF
)

 # Connect to DB and pass QUERY above but use -t switch to disable tuples

psql -h 51.140.184.11 -U probateman_user@probatemandb-postgres-db-prod -d probatemandb -c "${QUERY}" -P format=u  > ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}

 

# SED to to clean out \N (NULLS)

sed -r -e 's/$/|/' -e '1 s/^.*$//'  -e '/\(/d' ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME} > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Extract Complete"

#SFTP CONNECTION
