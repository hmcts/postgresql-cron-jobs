#!/bin/bash

set -eu

. ./prepare-variables.sh
. ./run-report-query.sh
. ./run-sort-csv-by-date.sh
. ./run-send-results-to-email.sh
. ./run-cleanup.sh

