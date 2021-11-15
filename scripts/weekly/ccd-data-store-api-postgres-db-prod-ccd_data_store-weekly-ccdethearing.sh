cat <<EOF
COPY (SELECT EXTRACTION_DATE
, CE_CASE_DATA_ID
, CASE_METADATA_EVENT_ID
, CE_CREATED_DATE
, CE_HEARING_ID
, CE_HEARING_TYPE
, regexp_replace(CE_HEARING_NOTES, E'[\\n\\r]+', '\\n', 'g' ) AS CE_HEARING_NOTES
, CE_HEARING_VENUE
, CE_HEARING_NUMBER
, CE_HEARING_SIT_ALONE
, CE_HEARING_EST_LENGTH
, CE_HEARING_EST_LENGTH_TYPE
, CE_HEARING_PUBLIC_PRIVATE
, CE_JUDGE_DETAILS
FROM (
  SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS EXTRACTION_DATE,
  CE.case_data_id        AS CE_CASE_DATA_ID,
  CE.ID as CASE_METADATA_EVENT_ID,
  CE.CREATED_DATE as CE_CREATED_DATE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{id}' AS CE_HEARING_ID,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,Hearing_type}' AS CE_HEARING_TYPE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,Hearing_notes}' AS CE_HEARING_NOTES,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,Hearing_venue}' AS CE_HEARING_VENUE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingNumber}' AS CE_HEARING_NUMBER,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingSitAlone}' AS CE_HEARING_SIT_ALONE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingEstLengthNum}' AS CE_HEARING_EST_LENGTH,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingEstLengthNumType}' AS CE_HEARING_EST_LENGTH_TYPE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingPublicPrivate}' AS CE_HEARING_PUBLIC_PRIVATE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,judge}' AS CE_JUDGE_DETAILS
  FROM case_event CE
  WHERE CE.case_type_id IN ( 'Bristol','Leeds','LondonCentral','LondonEast','LondonSouth','Manchester','MidlandsEast','MidlandsWest','Newcastle','Scotland','Wales','Watford' )
) a
Where CE_HEARING_ID is not null
AND CE_CREATED_DATE >= (current_date-7 + time '00:00')
AND CE_CREATED_DATE < (current_date + time '00:00')
ORDER BY CE_CREATED_DATE) TO STDOUT WITH CSV HEADER
EOF