#!/bin/bash
#
# scancel.sh
# Purpose: Convenience wrapper to cancel a range of jobs (sbatch IDs) via
#          `scancel`. Included here as an example of job-management utilities.
#
# WARNING (Documentation-only):
#   This script invokes `scancel` which cancels jobs on a scheduler. Do NOT run
#   it from the public repository; it may affect unrelated cluster jobs.
#
# Example (documentation only):
#   ./scancel.sh 1000 1010

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <first_value> <last_value>"
    exit 1
fi

first_value=$1
last_value=$2

# Execute scancel over the provided range
for ((i=first_value; i<=last_value; i++)); do
    scancel ${i}
done