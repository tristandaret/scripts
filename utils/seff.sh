#!/bin/bash
#
# seff.sh
# Purpose: Wrapper to inspect Slurm job efficiency via `seff` for a range of
#          job IDs. Kept for documentation to illustrate job-handling helpers.
#
# WARNING (Documentation-only):
#   This script queries a cluster scheduler. It is included for review and
#   should not be executed in the public repository where the cluster is not
#   available or where it could affect unrelated jobs.
#
# Example (documentation only):
#   ./seff.sh 12345 12350

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <first_value> <second_value>"
    exit 1
fi

first_value=$1
second_value=$2

# Execute seff with the provided values
for ((i=first_value; i<=second_value; i++)); do
    seff ${i}
done