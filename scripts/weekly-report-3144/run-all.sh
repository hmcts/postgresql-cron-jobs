#!/bin/bash

set -x

. ./prepare-variables.sh
. ./run-email-report.sh
. ./run-sort-csv-by-date.sh
. ./run-send-results-to-email.sh
