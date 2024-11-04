#!/bin/bash
source root/bin/thisroot.sh
output_folder="."
# Initialize arrays
RC_list=()
Dt_list=()

# Parse command-line arguments for RC and Dt
while [[ $# -gt 0 ]]; do
  case $1 in
    --RC)
      shift
      while [[ $# -gt 0 && $1 != -* ]]; do
        RC_list+=("$1")
        shift
      done
      ;;
    --Dt)
      shift
      while [[ $# -gt 0 && $1 != -* ]]; do
        Dt_list+=("$1")
        shift
      done
      ;;
    --folder)
      shift
      if [[ "$1" ]]; then
        output_folder="$1"
        shift
      fi
      ;;
    --) # End of all options
      shift
      break
      ;;
    -?*) # Unknown option
      printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      ;;
    *) # No more options
      break
  esac
done

# Debug output
echo "STARTING dEdx XP LUT PARALLELIZATION"
echo "Dt values: ${Dt_list[@]}"
echo "RC values: ${RC_list[@]}"
echo "Output folder: $output_folder"

for RC in "${RC_list[@]}"; do
  for Dt in "${Dt_list[@]}"; do
    echo "RC: ${RC}, Dt: ${Dt}"
    # Launch the job
    job=$(sbatch -t 1:00:00 -n 1 --mem 3GB --account t2k ./scripts/LUT.sh --Dt "${Dt}" --RC "${RC}" --output "${output_folder}")
    job_id="${job_id}:$(echo $job | awk '{print $NF}')"
    files="${files} ${output_folder}/dEdx_XP_LUT_tmp_Dt${Dt}_RC${RC}.root"
  done
done
sbatch -t 0:02:00 -n 1 --mem 1GB --account t2k --dependency=afterok${job_id} ./scripts/tree_merger.sh -f "${files}" -n "${output_folder}/dEdx_XP_LUT"
