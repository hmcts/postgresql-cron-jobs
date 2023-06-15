#!/bin/bash

## load the environment variables if not already loaded
if [ -z ${VARIABLES_SET+x} ];
then
  log "Variables are not present. Loading them."
  echo "Hint: are you running the script locally?"
  source 'prepare-variables.sh'
fi


function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}

trap errorHandler ERR
