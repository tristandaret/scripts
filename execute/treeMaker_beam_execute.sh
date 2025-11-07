#!/bin/bash
#
# treeMaker_beam_execute.sh
# Purpose: Run HATRECONTREEMAKER on a single beam input file and produce a
#          documented TreeMaker ROOT output and log. This file is kept here for
#          inspection and is not intended to be executed from the public repo.
#
# WARNING (Documentation-only):
#   The script references experiment-specific binaries and paths; do not run it
#   in this repository.
#
# Example (documentation only):
#   ./treeMaker_beam_execute.sh /path/to/hatRecon_output.root

inputFile=$1

# Remove path prefix and suffix
file=${inputFile#/sps/t2k/Jparc/May_2024/beam/hatRecon_14.29/hatRecon_nd280}
file=${file%.root}

outputFile="$HOME/public/output_hatRecon/root/beam/treeMaker_14.29_nd280${file}.root"
logs="$HOME/public/output_hatRecon/logs/TreeMaker_14.29_nd280${file}.log"

echo "logs:             ${logs}"
echo "treeMaker output: ${outputFile}"

HATRECONTREEMAKER.exe -R -t b -O outfile=$outputFile $inputFile &> $logs