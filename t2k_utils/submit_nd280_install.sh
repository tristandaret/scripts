#!/bin/bash

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

sbatch -t 10:00:00 -n 4 --mem 10GB --account t2k $HOME/scripts/utils/nd280_install.sh ${flags}