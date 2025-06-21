#!/bin/bash

inputFile=$1

# Remove path prefix and suffix
file=${inputFile#/sps/t2k/Jparc/May_2024/beam/hatRecon_14.29/hatRecon_nd280}
file=${file%.root}

outputFile="$HOME/public/output_hatRecon/root/beam/treeMaker_14.29_nd280${file}.root"
logs="$HOME/public/output_hatRecon/logs/TreeMaker_14.29_nd280${file}.log"

echo "logs:             ${logs}"
echo "treeMaker output: ${outputFile}"

HATRECONTREEMAKER.exe -R -t b -O outfile=$outputFile $inputFile &> $logs