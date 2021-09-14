#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
	  echo $(date --rfc-3339=seconds)" ${1}"
  }

  # Default to yesterday so we get a full days reconciliation
  #DEFAULT_DATE=$(date +%F) ##--date '-1 days')
  DEFAULT_DATE=$(date +%d%m%Y) 

  OUTPUT_DIR=/tmp/
  OUTPUT_FILE_NAME=IM${DEFAULT_DATE}.txt

  QUERY=$(cat <<EOF
COPY (SELECT 
'' AS estate_title,
trim(data->>'deceasedForenames') AS estate_forenames,
trim(data->>'deceasedSurname') AS estate_surname,
trim(data->>'deceasedDateOfDeath') AS date_of_death1,
trim(data->>'deceasedDateOfBirth') AS date_of_birth,
date_part('years',age((data->>'deceasedDateOfBirth')::date) - age((data->>'deceasedDateOfDeath')::date))  AS estate_age_at_death,
trim(data->'deceasedAddress'->>'AddressLine1') AS estate_address_line_1,
'' AS estate_address_line_2,
'' AS estate_address_line_3,
'' AS estate_address_line_4,
right((data->'deceasedAddress'->>'AddressLine1'), 8) AS estate_postcode,
reference AS grant_probate_number,
trim(data->>'grantIssuedDate') AS grant_issued_date,
'' AS grantee1_title,
'' AS grantee1_forenames,
'' AS grantee1_surname,
'' AS grantee1_address_line_1,
'' AS grantee1_address_line_2,
'' AS grantee1_address_line_3,
'' AS grantee1_address_line_4,
'' AS grantee1_postcode,
'' AS grantee2_title,
'' AS grantee2_forenames,
'' AS grantee2_surname,
'' AS grantee2_address_line_1,
'' AS grantee2_address_line_2,
'' AS grantee2_address_line_3,
'' AS grantee2_address_line_4,
'' AS grantee2_postcode,
'' AS grantee3_title,
'' AS grantee3_forenames,
'' AS grantee3_surname,
'' AS grantee3_address_line_1,
'' AS grantee3_address_line_2,
'' AS grantee3_address_line_3,
'' AS grantee3_address_line_4,
'' AS grantee3_postcode,
'' AS grantee4_title,
'' AS grantee4_forenames,
'' AS grantee4_surname,
'' AS grantee4_address_line_1,
'' AS grantee4_address_line_2,
'' AS grantee4_address_line_3,
'' AS grantee4_address_line_4,
'' AS grantee4_postcode,
trim(data->>'applicationType') AS grant_applicant_type,
'' AS applicant_surname,
'' AS applicant_address_line_1,
'' AS applicant_address_line_2,
'' AS applicant_address_line_3,
'' AS applicant_address_line_4,
'' AS applicant_postcode,
trim(data->>'ihtGrossValue') AS gross_estate_value,
trim(data->>'ihtNetValue') AS net_estate_value,
trim(data->>'caseType') AS app_case_type,
trim(data->>'registryLocation') AS reg_name
FROM case_data WHERE JURISDICTION='PROBATE' AND data->>'deceasedDateOfBirth' IS NOT NULL) TO STDOUT (DELIMITER '|');
EOF
)
psql -U ccd@ccd-data-store-api-postgres-db-prod -h ccd-data-store-api-postgres-db-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}${OUTPUT_FILE_NAME}

log "Iron Mountain Dump Complete"
