#!/bin/bash

# Default values of flags
N=500       # number of events
n=0         # number of events per job
comment=""
rm_flag=false
machine="htc"
cleaning=false

# flags for mc.sh
# Gun type
particle="mu-"
kinetic="600"

# Position (approximate values by scanning with the gun)
#bHAT center:          (  0, -75, -192.5) cm
#HAT half lengths:     (±97, ±35, ± 82.5) cm
#HAT inner dimensions: (194,  70,  165)   cm
X=-50
Y=75
Z=-275
DX=0
DY=0
DZ=0

# Direction
phi=0
dphi=0
theta=0
dtheta=0

# Parse command--tagsine arguments
while :; do
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

flags="-p $particle -e $kinetic -x $X -y $Y -z $Z --dx $DX --dy $DY --dz $DZ --phi $phi --dphi $dphi --theta $theta --dtheta $dtheta"

tags="MC_${particle}_${kinetic}MeV_x${X}_y${Y}_z${Z}_phi${phi}_theta${theta}"

# Add comment if any
if [ "$comment" != "" ]; then
  tags="${tags}_${comment}"
fi

# Batch or non-batch mode for number of events
if [ $n -ne 0 ]; then
  flags="${flags} -N $n"
  tags_job="${tags}_N${n}"
else
  flags="${flags} -N $N"
fi
tags="${tags}_N${N}"

# Remove intermediate files
if [ "$rm_flag" = true ]; then
  flags="${flags} --rm"
fi


### RUNNING ###
# Interactive console
if [ $n -eq 0 ]; then
  echo "STARTING: nd280 MC generation pipeline for ${N} events in interactive shell"
  flags="${flags} --tags ${tags}"
  time $HOME/scripts/execute/nd280_MC_reco_execute.sh ${flags}

# Jobs
else
  echo "STARTING: ND280 MC generation pipeline of ${N} events with jobs of ${n} events each"
  if [ $N -eq $n ]; then
    sbatch -t 4:00:00 -n 1 --mem 5GB --account t2k -p ${machine} $HOME/scripts/execute/nd280_MC_reco_execute.sh ${flags} --tags ${tags}
  else
    for ((i=0; i<N/n; i++)); do
      tags_job_here="${tags_job}_i${i}"
      flags_job="${flags} --tags ${tags_job_here}"
      job_mc=$(sbatch -t 4:00:00 -n 1 --mem 5GB --account t2k -p ${machine} $HOME/scripts/execute/nd280_MC_reco_execute.sh ${flags_job})
      job_mc_id="${job_mc_id}:$(echo $job_mc | awk '{print $NF}')"
      files_drs="${files_drs} $HOME/public/data/MC/2_DRS_${tags_job_here}.root"
      files_eventAnalysis="${files_eventAnalysis} $HOME/public/output_nd280/root/MC/5_eventAnalysis_${tags_job_here}.root"
    done
    sbatch -t 1:00:00 -n 1 --mem 4GB --account t2k -p ${machine} --dependency=afterok$job_mc_id $HOME/scripts/t2k_utils/tree_merger.sh -t ${tags} -f "${files_drs}" -n public/data/MC/DRS_
    sbatch -t 1:00:00 -n 1 --mem 4GB --account t2k -p ${machine} --dependency=afterok$job_mc_id $HOME/scripts/t2k_utils/tree_merger.sh -t ${tags} -f "${files_eventAnalysis}" -n public/output_nd280/root/MC/eventAnalysis_
  fi
fi
