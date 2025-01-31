#!/bin/bash

run=""
comment=""
flags=""
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
if [ "$N" -ne 0 ]; then
   flags="-N ${N} -n ${n}"
fi
if [ "$rm_flag" = true ]; then
   flags="${flags} --rm"
fi
flags="--comment ${comment}"

for file in "${files[@]}"; do
   ./scripts/submit_analysis.sh -d "${file}" ${flags}
done