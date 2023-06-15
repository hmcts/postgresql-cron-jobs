#!/bin/bash

## load the environment variables if not already loaded
if [ -z ${ENVIRONMENT_IS_SET+x} ];
then
  log "Environment variables are not present. Loading them."
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
