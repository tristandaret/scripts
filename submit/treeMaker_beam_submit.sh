#!/bin/sh
#
# treeMaker_beam_submit.sh
# Purpose: Submit TreeMaker jobs for each beam HAT recon output file listed in
#          a simple file called `beam_hatRecon_outputs.txt`. Included here for
#          documentation; job submission commands and sbatch options are site
#          specific and should not be executed from the repository.
#
# WARNING (Documentation-only):
#   Do not run this script in the public repo. It assumes `sbatch`, the
#   HATRECONTREEMAKER binary and specific file lists that are not present.
#
# Example (documentation only):
#   ./treeMaker_beam_submit.sh
#
# Read each line from the file

while IFS= read -r line || [ -n "$line" ]; do
   echo "Submitting job for $line"
   sbatch -t 03:00:00 -n 1 --mem 5GB --account t2k -p htc "$HOME/scripts/execute/treeMaker_beam_execute.sh" "$line"
done < beam_hatRecon_outputs.txt