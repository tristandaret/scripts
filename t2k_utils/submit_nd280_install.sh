#!/bin/bash
#
# submit_nd280_install.sh
# Purpose: Helper wrapper that submits `nd280_install.sh` on a batch system with
#          convenient sbatch flags. This file exists to show how installation
#          was run in the original environment and is for documentation only.
#
# WARNING (Documentation-only):
#   The script issues a batch submission which will not work in the public repo
#   and may alter remote systems. Do not run it here.
#
# Example (documentation only):
#   ./submit_nd280_install.sh -v master -c -j 8

flags=""
while getopts ":v:csj:d:" opt; do
   case ${opt} in
      v )
         flags="$flags -v $OPTARG"
         ;;
      c )
         flags="$flags -c"
         ;;
      s )
         flags="$flags -s"
         ;;
      j )
         flags="$flags -j $OPTARG"
         ;;
      d)
         flags="$flags -d $OPTARG"
         ;;
      \? )
         echo "Invalid option: -$opt" 1>&2
         exit 1
         ;;
      : )
         echo "Invalid option: -$opt requires an argument" 1>&2
         exit 1
         ;;
   esac
done
shift $((OPTIND -1))

echo "submit flags: $flags"

sbatch -t 10:00:00 -n 4 --mem 10GB --account t2k $HOME/scripts/t2k_utils/nd280_install.sh ${flags}