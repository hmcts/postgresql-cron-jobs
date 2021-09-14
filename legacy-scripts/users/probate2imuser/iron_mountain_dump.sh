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
#DEFAULT_DATE=20200206
OUTPUT_DIR=/var/lib/probate2im
OUTPUT_FILE_NAME=${DEFAULT_DATE}grant.txt
OUTPUT_SED_FILE_NAME=SIM${DEFAULT_DATE}.txt
FILELOCAL=${DEFAULT_DATE}grant.txt
SFTPHOSTNAME="sftp.ironmountain.eu"
SFTPUSERNAME="CCD-HMCTS"
SFTPPASSWORD="6WOpLC1k"
YESTERDAY=$(date -d "yesterday 13:00" '+%Y-%m-%d')  
#YESTERDAY=2020-02-05  

 # The QUERY 1 - Output data into a temp table called probe

QUERY=$(cat <<EOF


WITH sub AS (
    SELECT *
    FROM case_data, jsonb_array_elements(data -> 'probateDocumentsGenerated') as doc
    WHERE doc -> 'value' ->> 'DocumentDateAdded' = '${YESTERDAY}' AND doc -> 'value' ->>'DocumentType' in ('digitalGrant', 'admonWillGrant', 'intestacyGrant')
    --WHERE (doc -> 'value' ->> 'DocumentDateAdded'  between '2019-04-01' and '2019-04-13') AND doc -> 'value' ->>'DocumentType' in ('digitalGrant', 'admonWillGrant', 'intestacyGrant')
)

SELECT DISTINCT
  trim(data->> 'boDeceasedTitle') AS estate_title,
  trim(data->>'deceasedForenames') AS estate_forenames,
  trim(data->>'deceasedSurname') AS estate_surname,
  to_char(trim(data->>'deceasedDateOfDeath')::date, 'dd-MON-yyyy') AS date_of_death1,
  '' AS date_of_death2,
  to_char(trim(data->>'deceasedDateOfBirth')::date, 'dd-MON-yyyy') AS date_of_birth,
  date_part('years',age((data->>'deceasedDateOfBirth')::date) - age((data->>'deceasedDateOfDeath')::date))  AS estate_age_at_death,
  trim(data->'deceasedAddress'->>'AddressLine1') AS estate_address_line_1,
  trim(data->'deceasedAddress'->>'AddressLine2') AS estate_address_line_2,
  trim(data->'deceasedAddress'->>'PostTown') AS estate_address_line_3,
  trim(data->'deceasedAddress'->>'County') AS estate_address_line_4,
  trim(data->'deceasedAddress'->>'PostCode') AS estate_postcode,
  reference AS grant_probate_number,
  to_char((jsonb_array_elements(data -> 'probateDocumentsGenerated') -> 'value' ->> 'DocumentDateAdded')::date, 'dd-MON-yyyy') AS grant_issued_date, 
  '' AS grantee1_title,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(data->>'primaryApplicantForenames')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' ->>'applyingExecutorName' AS text)), '\s+\S*$','')
  END AS grantee1_forenames,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(data->>'primaryApplicantSurname')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' ->> 'applyingExecutorName' AS text)), '.+[\s]','')
  END AS grantee1_surname,
  CASE
    WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(data -> 'primaryApplicantAddress' ->> 'AddressLine1')
    ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine1' AS text))
  END AS grantee1_address_line_1,
  CASE
    WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(data -> 'primaryApplicantAddress' ->> 'AddressLine2')
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine2' AS text))
  END AS grantee1_address_line_2,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(data -> 'primaryApplicantAddress' ->> 'PostTown')
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'PostTown' AS text))
  END AS grantee1_address_line_3,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(data -> 'primaryApplicantAddress' ->> 'County')
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'County' AS text))
  END AS grantee1_address_line_4,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(data -> 'primaryApplicantAddress' ->> 'PostCode')
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'PostCode' AS text))
  END AS grantee1_postcode,
  '' AS grantee2_title,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' ->>'applyingExecutorName' AS text)), '\s+\S*$','')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' ->>'applyingExecutorName' AS text)), '\s+\S*$','')
  END AS grantee2_forenames,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' ->> 'applyingExecutorName' AS text)), '.+[\s]','')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' ->> 'applyingExecutorName' AS text)), '.+[\s]','')
  END AS grantee2_surname,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine1' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine1' AS text))
  END AS grantee2_address_line_1,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine2' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine2' AS text))
  END AS grantee2_address_line_2,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'PostTown' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'PostTown' AS text))
  END AS grantee2_address_line_3,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'County' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'County' AS text))
  END AS grantee2_address_line_4,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' -> 'applyingExecutorAddress' ->> 'PostCode' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'PostCode' AS text))
  END AS grantee2_postcode,
  '' AS grantee3_title,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' ->>'applyingExecutorName' AS text)), '\s+\S*$','')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' ->>'applyingExecutorName' AS text)), '\s+\S*$','')
  END AS grantee3_forenames,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' ->> 'applyingExecutorName' AS text)), '.+[\s]','')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' ->> 'applyingExecutorName' AS text)), '.+[\s]','')
  END AS grantee3_surname,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine1' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine1' AS text))
  END AS grantee3_address_line_1,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine2' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine2' AS text))
  END AS grantee3_address_line_2,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'PostTown' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'PostTown' AS text))
  END AS grantee3_address_line_3,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'County' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'County' AS text))
  END AS grantee3_address_line_4,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 1) -> 'value' -> 'applyingExecutorAddress' ->> 'PostCode' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'PostCode' AS text))
  END AS grantee3_postcode,
  '' AS grantee4_title,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' ->>'applyingExecutorName' AS text)), '\s+\S*$','')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 3) -> 'value' ->>'applyingExecutorName' AS text)), '\s+\S*$','')
  END AS grantee4_forenames,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' ->> 'applyingExecutorName' AS text)), '.+[\s]','')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 3) -> 'value' ->> 'applyingExecutorName' AS text)), '.+[\s]','')
  END AS grantee4_surname,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine1' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 3) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine1' AS text))
  END AS grantee4_address_line_1,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine2' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 3) -> 'value' -> 'applyingExecutorAddress' ->> 'AddressLine2' AS text))
  END AS grantee4_address_line_2,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'PostTown' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 3) -> 'value' -> 'applyingExecutorAddress' ->> 'PostTown' AS text))
  END AS grantee4_address_line_3,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'County' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 3) -> 'value' -> 'applyingExecutorAddress' ->> 'County' AS text))
  END AS grantee4_address_line_4,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(CAST(jsonb_array_element(data -> 'executorsApplying', 2) -> 'value' -> 'applyingExecutorAddress' ->> 'PostCode' AS text))
  ELSE trim(CAST(jsonb_array_element(data -> 'executorsApplying', 3) -> 'value' -> 'applyingExecutorAddress' ->> 'PostCode' AS text))
  END AS grantee4_postcode,
  upper(trim(data->>'applicationType')) AS grant_applicant_type,
  CASE
    WHEN upper(data ->> 'applicationType') = 'PERSONAL' THEN trim(data->>'primaryApplicantSurname')
    ELSE trim(data ->> 'solsSolicitorFirmName')
  END AS applicant_surname,
  CASE
    WHEN upper(data ->> 'applicationType') = 'PERSONAL' THEN trim(data->'primaryApplicantAddress'->>'AddressLine1')
    ELSE trim(data -> 'solsSolicitorAddress' ->> 'AddressLine1')
  END AS applicant_address_line_1,
  CASE
  WHEN upper(data ->> 'applicationType') = 'PERSONAL' THEN trim(data->'primaryApplicantAddress'->>'AddressLine2')
  ELSE trim(data -> 'solsSolicitorAddress' ->> 'AddressLine2')
  END AS applicant_address_line_2,
  CASE
  WHEN upper(data ->> 'applicationType') = 'PERSONAL' THEN trim(data->'primaryApplicantAddress'->>'PostTown')
  ELSE trim(data -> 'solsSolicitorAddress' ->> 'PostTown')
  END AS applicant_address_line_3,
  CASE
  WHEN upper(data ->> 'applicationType') = 'PERSONAL' THEN trim(data->'primaryApplicantAddress'->>'County')
  ELSE trim(data -> 'solsSolicitorAddress' ->> 'County')
  END AS applicant_address_line_4,
  CASE
  WHEN upper(data ->> 'applicationType') = 'PERSONAL' THEN trim(data->'primaryApplicantAddress'->>'PostCode')
  ELSE trim(data -> 'solsSolicitorAddress' ->> 'PostCode')
  END AS applicant_postcode,
  cast((cast(trim(data->>'ihtGrossValue')  as bigint)) / 100 as decimal(35,0)) AS gross_estate_value,
  cast((cast(trim(data->>'ihtNetValue')  as bigint)) / 100 as decimal(35,0)) AS net_estate_value,
  CASE
  WHEN data->>'caseType' = 'admonWill' THEN 'ADMON/WILL'
  WHEN data->>'caseType' = 'gop' THEN 'PROBATE'
  WHEN data->>'caseType' = 'intestacy' THEN 'ADMINISTRATION'
  ELSE 'UNKNOWN'
  END AS app_case_type,
  CASE
  WHEN data->>'registryLocation' = 'ctsc' THEN 'Principal Registry'
  ELSE trim(data->>'registryLocation')
  END AS reg_name,
  trim(jsonb_array_elements(data->'probateDocumentsGenerated')->'value'->>'DocumentType') AS DocumentType
INTO temp probe
FROM sub WHERE JURISDICTION='PROBATE' AND case_type_id = 'GrantOfRepresentation' and state = 'BOGrantIssued';
 
SELECT
 estate_title,
 estate_forenames ,
 estate_surname,
 date_of_death1,
 date_of_death2,
 date_of_birth ,
 estate_age_at_death,
 regexp_replace(estate_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS estate_address_line_1,
 estate_address_line_2,
 estate_address_line_3,
 estate_address_line_4,
 estate_postcode  ,
 grant_probate_number,
 grant_issued_date,
 grantee1_title,
 grantee1_forenames,
 grantee1_surname ,
 regexp_replace(grantee1_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS grantee1_address_line_1,
 grantee1_address_line_2,
 grantee1_address_line_3,
 grantee1_address_line_4,
 grantee1_postcode ,
 grantee2_title,
 grantee2_forenames,
 grantee2_surname ,
 regexp_replace(grantee2_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS grantee2_address_line_1,
 grantee2_address_line_2,
 grantee2_address_line_3,
 grantee2_address_line_4,
 grantee2_postcode ,
 grantee3_title,
 grantee3_forenames,
 grantee3_surname ,
 regexp_replace(grantee3_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS grantee3_address_line_1,
 grantee3_address_line_2,
 grantee3_address_line_3,
 grantee3_address_line_4,
 grantee3_postcode ,
 grantee4_title,
 grantee4_forenames,
 grantee4_surname ,
 regexp_replace(grantee4_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS grantee4_address_line_1,
 grantee4_address_line_2,
 grantee4_address_line_3,
 grantee4_address_line_4,
 grantee4_postcode ,
 grant_applicant_type,
 applicant_surname ,
 regexp_replace(applicant_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS applicant_address_line_1,
 applicant_address_line_2,
 applicant_address_line_3,
 applicant_address_line_4,
 applicant_postcode,
 gross_estate_value,
 net_estate_value ,
 app_case_type,
 reg_name 

 FROM probe WHERE DocumentType IN ('digitalGrant', 'admonWillGrant', 'intestacyGrant') ORDER BY grant_probate_number;

EOF
)

 # Connect to DB and pass QUERY above but use -t switch to disable tuples

psql -t -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}" -P format=u  > ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}

 

# SED to to clean out \N (NULLS)

sed -r -e 's/$/|/' -e '1 s/^.*$//'  -e '/\(/d' ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME} > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#sed -r -e 's/\\N//' ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME} > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Iron Mountain Dump Complete"

#SFTP CONNECTION
sshpass -p $SFTPPASSWORD sftp $SFTPUSERNAME@$SFTPHOSTNAME << !
	put $FILELOCAL
	ls -ltr
	bye
!
