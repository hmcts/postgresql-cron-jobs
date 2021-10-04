#!/bin/bash
# vi:syntax=sh

## Weekly Probate Extract for the HMRC 
## Extraction is from CCD - core_case_data DB
# JIRA - https://tools.hmcts.net/jira/browse/PRO-5395 & https://tools.hmcts.net/confluence/display/PRO/HMRC+Extract
# Alliu Balogun - 10/06/2019
# 

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

  # Set date and output VARS

DEFAULT_DATE=$(date +%Y%m%d)
#DEFAULT_DATE=20190101
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=2_${DEFAULT_DATE}.dat
OUTPUT_SED_FILE_NAME=1_${DEFAULT_DATE}.dat
#YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d')  
#SEVENDAYSAGO=$(date -d "1 days ago" '+%Y-%m-%d')  
#HMRCYESTERDAY=$(date -d "yesterday" '+%Y%m%d')  
#HMRCSEVENDAYSAGO=$(date -d "1 days ago" '+%Y%m%d')  
YESTERDAY=2020-08-31  
SEVENDAYSAGO=2020-02-01  
HMRCYESTERDAY=20200831 
HMRCSEVENDAYSAGO=20200201  
#TO_ADDRESS=dm.interfaces@dwp.gov.uk
TO_ADDRESS=alliu.balogun@hmcts.net
#TO_ADDRESS=simon.pope@hmcts.net
CC_ADDRESS=sanjay.parekh@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
#FAILURE_ADDRESS=dcd-devops-support@hmcts.net
FAILURE_ADDRESS=alliu.balogun@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="HMRC Weekly extract on ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "HMRC Weekly extract ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
}

trap errorHandler ERR

if [[ -z "${CC_ADDRESS}" ]]; then
    CC_COMMAND=""
    CC_LOG_MESSAGE=""
else
    CC_COMMAND="-c ${CC_ADDRESS}"
    CC_LOG_MESSAGE="copied to: ${CC_ADDRESS}"
fi

 # The QUERY 1 - Output data into a temp table called HMRC

QUERY=$(cat <<EOF
WITH sub AS (
    SELECT cd.reference, cd.data
    FROM case_data cd, jsonb_array_elements(cd.data -> 'probateDocumentsGenerated') as doc
WHERE cd.jurisdiction = 'PROBATE' AND cd.case_type_id = 'GrantOfRepresentation' AND cd.state = 'BOGrantIssued' AND cd.data ->> 'grantIssuedDate' BETWEEN '${SEVENDAYSAGO}' AND '${YESTERDAY}' 
)

SELECT DISTINCT
  'T' as record_type,
  reference AS probate_number,
  trim(data->>'registryLocation') AS registryLocation,
  trim(data->> 'boDeceasedTitle') AS bodeceasedtitle,
  trim(data->>'deceasedForenames') AS deceasedforenames,
  trim(data->>'deceasedSurname') AS deceasedsurname,
  trim(data->>'boDeceasedHonours') AS bodeceasedhonours,
  '' AS deceased_sex,
  to_char(trim(data->>'deceasedDateOfDeath')::date, 'dd-MON-yyyy') AS dod1,
  '' AS dod2,
  to_char(trim(data->>'deceasedDateOfBirth')::date, 'dd-MON-yyyy') AS deceased_dob,
  date_part('years',age((data->>'deceasedDateOfBirth')::date) - age((data->>'deceasedDateOfDeath')::date))  AS deceased_age_at_death,
  'England and Wales' AS deceased_domicile,
  trim(data->'deceasedAddress'->>'AddressLine1') AS deceased_address_line_1,
  trim(data->'deceasedAddress'->>'AddressLine2') AS deceased_address_line_2,
  trim(data->'deceasedAddress'->>'PostTown') AS deceased_address_line_3,
  trim(data->'deceasedAddress'->>'County') AS deceased_address_line_4,
  trim(data->'deceasedAddress'->>'PostCode') AS deceased_postcode,
  to_char((jsonb_array_elements(data -> 'probateDocumentsGenerated') -> 'value' ->> 'DocumentDateAdded')::date, 'dd-MON-yyyy') AS grant_issue_date,
  '' AS grantee1_title,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(data->>'primaryApplicantForenames')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' ->>'applyingExecutorName' AS text)), '\s+\S*$','')
  END AS grantee1_forenames,
  CASE
  WHEN data ->> 'primaryApplicantIsApplying' = 'Yes' THEN trim(data->>'primaryApplicantSurname')
  ELSE regexp_replace(trim(CAST(jsonb_array_element(data -> 'executorsApplying', 0) -> 'value' ->> 'applyingExecutorName' AS text)), '.+[\s]','')
  END AS grantee1_surname,
  '' AS grantee_1_honours,
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
  '' AS grantee_2_honours,
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
  '' AS grantee_3_honours,
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
  '' AS grantee_4_honours,
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
 trim(data ->> 'solsSolicitorFirmName') AS solicitor_name,
 trim(data -> 'solsSolicitorAddress' ->> 'AddressLine1') AS solicitor_address_line_1,
 trim(data -> 'solsSolicitorAddress' ->> 'AddressLine2') AS solicitor_address_line_2,
 trim(data -> 'solsSolicitorAddress' ->> 'PostTown') AS solicitor_address_line_3,
 trim(data -> 'solsSolicitorAddress' ->> 'County') AS solicitor_address_line_4,
 trim(data -> 'solsSolicitorAddress' ->> 'PostCode') AS solicitor_postcode,
  cast((cast(trim(data->>'ihtGrossValue')  as bigint)) / 100 as decimal(35,0)) AS gross_estate_value,
CASE
  WHEN data->>'ihtFormId' = 'IHT400421' THEN 'N'
  WHEN data->>'ihtFormId' = 'IHT205' THEN 'Y'
  WHEN data->>'ihtFormId' = 'IHT207' THEN 'E'
  ELSE ''
  END AS expected_estate_indicator,
  cast((cast(trim(data->>'ihtNetValue')  as bigint)) / 100 as decimal(35,0)) AS net_estate_value,
  CASE
  WHEN data->>'caseType' = 'admonWill' THEN 'ADMON/WILL'
  WHEN data->>'caseType' = 'gop' THEN 'PROBATE'
  WHEN data->>'caseType' = 'intestacy' THEN 'ADMINISTRATION'
  ELSE ''
  END AS case_type
INTO temp hmrc
FROM sub; 

-- 2nd QUERY

SELECT
record_type,
probate_number,
registrylocation,
bodeceasedtitle,
deceasedforenames,
deceasedsurname,
bodeceasedhonours,
deceased_sex,
dod1,
dod2,
deceased_dob,
deceased_age_at_death,
deceased_domicile,
regexp_replace(deceased_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS deceased_address_line_1,
deceased_address_line_2,
deceased_address_line_3,
deceased_address_line_4,
deceased_postcode,
grant_issue_date,
grantee1_title,
grantee1_forenames,
grantee1_surname,
grantee_1_honours,
regexp_replace(grantee1_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS grantee1_address_line_1,
grantee1_address_line_2,
grantee1_address_line_3,
grantee1_address_line_4,
grantee1_postcode,
grantee2_title,
grantee2_forenames,
grantee2_surname,
grantee_2_honours,
regexp_replace(grantee2_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS grantee2_address_line_1,
grantee2_address_line_2,
grantee2_address_line_3,
grantee2_address_line_4,
grantee2_postcode ,
grantee3_title,
grantee3_forenames,
grantee3_surname,
grantee_3_honours,
regexp_replace(grantee3_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS grantee3_address_line_1,
grantee3_address_line_2,
grantee3_address_line_3,
grantee3_address_line_4,
grantee3_postcode,
grantee4_title,
grantee4_forenames,
grantee4_surname,
grantee_4_honours,
regexp_replace(grantee4_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS grantee4_address_line_1,
grantee4_address_line_2,
grantee4_address_line_3,
grantee4_address_line_4,
grantee4_postcode,
solicitor_name,
regexp_replace(solicitor_address_line_1, E'[\\r\\n]+', ' ', 'g' ) AS solicitor_address_line_1,
solicitor_address_line_2,
solicitor_address_line_3,
solicitor_address_line_4,
solicitor_postcode,
gross_estate_value,
expected_estate_indicator,
net_estate_value,
case_type
FROM hmrc ORDER BY probate_number;
--WHERE grant_issue_date::date BETWEEN '${HMRCSEVENDAYSAGO}' AND '${HMRCYESTERDAY}'  ORDER BY probate_number;  

EOF
)

## 2ND Query with reduced columns

QUERY2=$(cat <<EOF
WITH sub2 AS (
    SELECT cd.reference, cd.data
    FROM case_data cd, jsonb_array_elements(cd.data -> 'probateDocumentsGenerated') as doc
    WHERE cd.jurisdiction = 'PROBATE' AND cd.case_type_id = 'GrantOfRepresentation' AND cd.state = 'BOGrantIssued' AND cd.data ->> 'grantIssuedDate' BETWEEN '${SEVENDAYSAGO}' AND '${YESTERDAY}'
)

SELECT DISTINCT
  'A' as record_type,
  reference AS probate_number,
  '' AS deceased_alias_title,
  regexp_replace(trim(CAST(jsonb_array_elements(data->'solsDeceasedAliasNamesList')->'value'->>'SolsAliasname' AS text)), '\s+\S*$','') AS deceased_alias_forenames,  --- ONLY extract Forename from fullname
  regexp_replace(trim(CAST(jsonb_array_elements(data->'solsDeceasedAliasNamesList')->'value'->>'SolsAliasname' AS text)), '.+[\s]','') AS deceased_alias_surname, --- ONLY extract Surname from fullname
  '' AS deceased_alias_honours,
  to_char((jsonb_array_elements(data -> 'probateDocumentsGenerated') -> 'value' ->> 'DocumentDateAdded')::date, 'dd-MON-yyyy') AS grant_issue_date
 INTO temp hmrc2
 FROM sub2;

SELECT DISTINCT
record_type,
probate_number,
deceased_alias_title ,
deceased_alias_forenames ,
deceased_alias_surname,
deceased_alias_honours
FROM hmrc2; 
--WHERE grant_issue_date::date BETWEEN '${HMRCSEVENDAYSAGO}' AND '${HMRCYESTERDAY}'  ORDER BY probate_number;

EOF
)

 # Connect to DB and pass QUERY above but use -t switch to disable tuples

#psql -t -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}" -P format=u > ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}
psql -t -U ccdro@ccd-data-store-performance -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}" -P format=u > ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}


## Append 2nd query Output into bottom of the 1st file

#psql -t -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY2}" -P format=u >> ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}
psql -t -U ccdro@ccd-data-store-performance -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY2}" -P format=u >> ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}
 

# SED to clean out \N (NULLS) and replace "|" with "~" as per column separator requirement
sed -e 's/\\N//' -e 's/|/~/g' ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME} > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

## Sort by 2nd column (probate_number - CCD Reference) numerically then by 1st alphabetically as per requirement
sort -t "~" -k2n,16 -rk1,1 ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} > ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}

# Part of the filename to include row count
ROWCOUNT=`wc -l ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} | cut -d' ' -f1`
echo "Z~LCD${DEFAULT_DATE}A.dat~${ROWCOUNT}~1~Y~" >> ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}

# Insert "ENGLAND" in the first line of the file
sed -i '1s/^/ENGLAND\n/' ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME}

# Finished with the tidy-up, move SED filename to real filename 
mv ${OUTPUT_DIR}/${OUTPUT_SED_FILE_NAME} ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}


log "Finished extracting HMRC feed on ${DEFAULT_DATE}"

# Zip file before sending to HMRC
#zip -m ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.zip ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Sending zip file extract to HMRC: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "Probate extract from MoJ to the HMRC" | mail -s "MoJ feed to the HMRC" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.zip -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} 

