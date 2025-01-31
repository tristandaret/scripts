#!/bin/bash

# Default values of flags
N=500       # number of events
n=0         # number of events per job
tag=""
rm_flag=false
make_flag=false
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
X=50
Y=75
Z=-275
DX=50
DY=35
DZ=0

# Direction
phi=0
dphi=0
theta=0
dtheta=0

# Parse command-line arguments
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
    -t)
      if [ "$2" ]; then
        tag=$2
        shift
      fi
      ;;
    -X)
      if [ "$2" ]; then
        X=$2
        shift
      fi
      ;;
    -Y)
      if [ "$2" ]; then
        Y=$2
        shift
      fi
      ;;
    --phi)
      if [ "$2" ]; then
        phi=$2
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
    --make)
      make_flag=true
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
  $HOME/scripts/cleaning.sh
fi

if [ "$make_flag" = true ]; then
  make_hatRecon
fi

flags="-p $particle -e $kinetic -x $X -y $Y -z $Z --dx $DX --dy $DY --dz $DZ --phi $phi --dphi $dphi --theta $theta --dtheta $dtheta"

label="MC_${particle}_${kinetic}MeV_x${X}_y${Y}_z${Z}_phi${phi}_theta${theta}"

# Add tag if any
if [ "$tag" != "" ]; then
  label="${label}_${tag}"
fi

# Batch or non-batch mode for number of events
if [ $n -ne 0 ]; then
  flags="${flags} -N $n"
  label_job="${label}_N${n}"
else
  flags="${flags} -N $N"
fi
label="${label}_N${N}"

# Remove intermediate files
if [ "$rm_flag" = true ]; then
  flags="${flags} --rm"
fi


### RUNNING ###
# Interactive console
if [ $n -eq 0 ]; then
  echo "STARTING: Particle guns of ${N} events in interactive shell"
  flags="${flags} -l ${label}"
  $HOME/scripts/mc.sh ${flags}

# Jobs
else
  echo "STARTING: Particle guns of ${N} events with jobs of ${n} events each"
  if [ $N -eq $n ]; then
    sbatch -t 1:00:00 -n 1 --mem 4GB --account t2k -p ${machine} $HOME/scripts/mc.sh ${flags} -l ${label}
  else
    for ((i=0; i<N/n; i++)); do
      label_job_here="${label_job}_i${i}"
      flags_job="${flags} -i ${i} -l ${label_job_here}"
      job_mc=$(sbatch -t 1:00:00 -n 1 --mem 4GB --account t2k -p ${machine} $HOME/scripts/mc.sh ${flags_job})
      job_mc_id="${job_mc_id}:$(echo $job_mc | awk '{print $NF}')"
      files_drs="${files_drs} $HOME/public/data/MC/2_DetResSim_${label_job_here}.root"
      files_treemaker="${files_treemaker} $HOME/public/Output_root/MC/TreeMaker_${label_job_here}.root"
    done
    sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_mc_id $HOME/scripts/tree_merger.sh -t ${label} -f "${files_drs}" -n public/data/MC/Simu_
    sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_mc_id $HOME/scripts/tree_merger.sh -t ${label} -f "${files_treemaker}" -n public/Output_root/MC/TreeMaker_
  fi
fi
