#!/bin/bash
#
# hat_reco_supersubmit.sh
# Purpose: Dispatch large-scale production submissions for hat reconstruction.
#          Typically iterates over configurations and submits many job arrays.
#
# WARNING (Documentation-only):
#   This script is for documentation and should not be executed in this
#   repository. It references cluster accounts, sbatch and experiment paths.
#
# Example (documentation only):
#   ./hat_reco_supersubmit.sh --run campaign01 --submit job
#
run=""
comment=""
flags=""
submit="job"
machine="htc"
rm_flag=false
N=0
n=0

while [[ "$#" -gt 0 ]]; do
   case $1 in
      -N)
         if [ "$2" ]; then
            N=$2
            shift
         fi
         ;;
      -n)
         if [ "$2" ]; then
            n=$2
            shift
         fi
         ;;
      --comment)
         if [ "$2" ]; then
            comment=$2
            shift
         fi
         ;;
      --run)
         if [ "$2" ]; then
            run=$2
            shift
         fi
         ;;
      --submit)
         if [ "$2" ]; then
            submit=$2
            shift
         fi
         ;;
      --machine)
         if [ "$2" ]; then
            machine=$2
            shift
         fi
         ;;
      --rm)
         rm_flag=true
         ;;
      *)
         echo "Invalid option: $1" >&2
         exit 1
         ;;
   esac
   shift
done

# Define the number of subruns in each run
if [ "$run" == "1022" ]; then
    imax=45
elif [ "$run" == "1148" ]; then
   imax=42
elif [ "$run" == "1205" ]; then
   imax=86
fi

# Create the list of subrun files
for i in $(seq 0 $imax); do
   subrun=$(printf "%04d" $i)
   files+=("dog1_0000${run}_${subrun}")
done

# Make the flags
flags="--submit ${submit} --machine ${machine}"
if [ "$N" -ne 0 ]; then
   flags="${flags} -N ${N} -n ${n}"
fi
flags="${flags} --comment ${comment}"
if [ "$rm_flag" = true ]; then
   flags="${flags} --rm"
fi

echo "SUPERSUBMIT FLAGS: ${flags}"

for file in "${files[@]}"; do
   echo "Submitting ${file}"
   ./scripts/submit/hat_reco_submit.sh -d "${file}" ${flags}
done