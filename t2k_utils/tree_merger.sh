#!/bin/bash
#
# tree_merger.sh
# Purpose: Merge ROOT files (via `hadd`) and remove intermediate files.
#          This helper illustrates how outputs were combined after batch jobs.
#
# WARNING (Documentation-only):
#   This script manipulates files and uses `hadd`. It is included for
#   documentation and should not be executed in the public repository.
#
# Example (documentation only):
#   ./tree_merger.sh -t TAG -f "file1.root file2.root" -n public/data/MC/

#flags (mandatory): -t tag -f files to merge -n output prefix

# Parse command-line arguments
while getopts ":t:f:n:" opt; do
  case $opt in
    t)
      tag="$OPTARG"
      ;;
    f)
      files_tomerge="$OPTARG"
      ;;
    n)
      output_name="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

echo "Files to merge: ${files_tomerge}"
hadd -f $HOME/${output_name}${tag}.root ${files_tomerge}
rm ${files_tomerge}