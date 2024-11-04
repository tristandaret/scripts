#!/bin/bash

output_folder="."
RC=0
Dt=0
# Parse command-line arguments for RC and Dt
while [[ $# -gt 0 ]]; do
  case $1 in
    --RC)
      shift
      if [[ "$1" ]]; then
        RC="$1"
        shift
      fi
      ;;
    --Dt)
      shift
      if [[ "$1" ]]; then
        Dt="$1"
        shift
      fi
      ;;
    --output)
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
    *) # No more options
      break
  esac
done

python ./scripts/dEdx_XP_LUT_maker.py "${Dt}" "${RC}" "${output_folder}"