#!/bin/bash
#flags (mandatory): -t tag -f files to merge -n output prefix

source /pbs/throng/t2k/t2k_setup.sh
pbs_nd280 14.18


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
hadd -f $HOME/${output_name}_${tag}.root ${files_tomerge}
rm ${files_tomerge}