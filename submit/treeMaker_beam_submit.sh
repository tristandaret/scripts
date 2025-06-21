#!/bin/sh

# Read each line from the file

while IFS= read -r line || [ -n "$line" ]; do
   echo "Submitting job for $line"
   sbatch -t 03:00:00 -n 1 --mem 5GB --account t2k -p htc "$HOME/scripts/execute/treeMaker_beam_execute.sh" "$line"
done < beam_hatRecon_outputs.txt