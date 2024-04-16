#!/bin/bash
#flags (mandatory): -t tag -f files to merge

source /pbs/throng/t2k/t2k_setup.sh
pbs_nd280 14.18


# Parse command-line arguments
while getopts ":t:f:" opt; do
  case $opt in
    t)
      tag="$OPTARG"
      ;;
    f)
      files_treemaker="$OPTARG"
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

hadd -f /sps/t2k/tdaret/public/Output_root/TreeMaker_${tag}.root ${files_treemaker}

files_hatrecon=$(echo "$files_treemaker" | sed 's/TreeMaker/HATRecon/g')
files_treemaker_log=$(echo "$files_treemaker" | sed 's/root/log/g')
files_hatrecon_log=$(echo "$files_hatrecon" | sed 's/root/log/g')

echo "TreeMaker files: ${files_treemaker}"
rm ${files_treemaker} ${files_hatrecon} ${files_treemaker_log} ${files_hatrecon_log}