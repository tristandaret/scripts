#!/bin/bash

# Default values of flags
start=0         # starting event
N=500       # number of events
n=0         # number of events per job
comment=""
rm_flag=false
machine="htc"
cleaning=false

# Parse command--tagsine arguments
while :; do
case $1 in
   -s)
      if [ "$2" ]; then
      start=$2
      shift
      fi
      ;;
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
   -d)
   if [ "$2" ]; then
      datafile=$2
      shift
   fi
   ;;
   --comment)
   if [ "$2" ]; then
      comment=$2
      shift
   fi
   ;;
   --clean)
   cleaning=true
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
shift
done

if [ "$cleaning" = true ]; then
  $HOME/scripts/utils/cleaning.sh
fi

if [ -z "$datafile" ]; then
#   datafile="dog1_00001148_0000"
  datafile="MC_mu-_400MeV_x0_y75_z-300_phi0_theta0_horizontal_14.29_N5000"
fi

flags="-d ${datafile}"
tags="${datafile}"

# Handle case with optional flag
if [ "$start" -ne 0 ]; then
  flags="${flags} -s ${start}"
fi
tags="${tags}_s${start}"

if [ "$N" -ne 0 ]; then
  flags="${flags} -n ${N}"
  tags="${tags}_n${N}"
else
  tags="${tags}_nAll"
fi

if [ "$n" -ne 0 ]; then
  flags_iter="-d ${datafile} -n ${n}"
fi

# Setting details
# Add comment if any
if [ "$comment" != "" ]; then
  tags="${tags}_${comment}"
fi
# Final list of arguments
flags="${flags} --tags ${tags}"
# Remove intermediate files
if [[ "$rm_flag" = true ]]; then
  flags="${flags} --rm"
  flags_iter="${flags_iter} --rm"
fi


### RUNNING ###
# Run in interactive shell
if [ ${n} -eq 0 ]; then
   if [ "$N" -ne 0 ]; then
      echo "STARTING: ND280 pipeline for ${N} events in interactive shell"
      echo "flags:                 ${flags}"
      ./scripts/execute/nd280_reco_execute.sh ${flags}
   elif [ "$N" -eq 0 ]; then
      echo "STARTING: hatRecon for ALL events in one bash job"
      echo "flags:                 ${flags}"
      sbatch -t 5:00:00 -n 1 --mem 5GB --account t2k -p ${machine} ./scripts/execute/nd280_reco_execute.sh ${flags}
   fi

# Parallelization
else
   echo "STARTING: ND280 pipeline for ${N} events with parallel jobs of ${n} events each from event ${start}"
   echo "flags: ${flags}"
   # single job
   if [ $N -eq $n ]; then
      sbatch -t 3:00:00 -n 1 --mem 5GB --account t2k -p ${machine} ./scripts/execute/nd280_reco_execute.sh ${flags}
   # several jobs
   else
      for ((s = start; s < start+N; s += n)); do
         tags_iter="${datafile}_s${s}_n${n}${comment}"
         flags_iter_here="${flags_iter} -s ${s} --tags ${tags_iter}"
         echo "flags_iter_here: ${flags_iter_here}"
         job_nd280=$(sbatch -t 2:00:00 -n 1 --mem 5GB --account t2k -p ${machine} ./scripts/execute/nd280_reco_execute.sh ${flags_iter_here})
         job_nd280_id="${job_nd280_id}:$(echo $job_nd280 | awk '{print $NF}')"
         files_nd280="${files_nd280} /sps/t2k/tdaret/public/output_nd280/root/5_eventAnalysis_${datafile}_s${s}_n${n}${comment}.root"
      done
      sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_nd280_id ./scripts/t2k_utils/tree_merger.sh --tags ${tags} -f "${files_nd280}" -n public/output_nd280/root/hatRecon_
   fi
fi
