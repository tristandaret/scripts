#!/bin/bash
#
# hadd.sh
# Purpose: Example wrapper showing how ROOT `hadd` was used to merge files in
#          the original workflows. Kept for documentation of command usage.
#
# WARNING (Documentation-only):
#   This script will remove and rewrite files. Do not execute it in the public
#   repository — it is present only for reviewers to understand the workflow.
#
folder="public/Output_root"
output_file="${folder}/hatRecon_dog1_00001022_master_T04_all01.root"
input_files=""

# Remove existing merged file (present in original environment)
# rm ${output_file}

for i in $(seq -w 0 1); do
    input_files+="${folder}/hatRecon_dog1_00001022_000${i}_s0_n28000.root "
done

# Example invocation of hadd (commented out here for safety):
# hadd -T $output_file $input_files