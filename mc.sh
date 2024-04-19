#!/bin/bash
rm -f $HOME/slurm-*.out
rm -f $HOME/plots/*.pdf

# Default values of flags
N=2000      # number of events
n=0         # number of events per job
tag=""
rm_flag=false
make_flag=false
machine="htc"

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

if [ "$make_flag" = true ]; then
  cd $HOME/hatRecon/`nd280-system`
  cmake ../cmake/
  make -j40
  cd ../..
fi


# flags for gun_init.sh
# Gun type
particle="mu-"
energy="600"

# Position (approximate values by scanning with the gun)
#HAT center:           (  0, -75, -192.5) cm
#HAT half lengths:     (±97, ±35, ± 82.5) cm
#HAT inner dimensions: (194,  70,  165)   cm
X=50
Y=-60
Z=-285
DX=0
DY=1
DZ=0

# Direction
phi=0
dphi=1
theta=0
dtheta=1
label="MC_${particle}_${energy}MeV_x${X}_y${Y}_z${Z}_phi${phi}_theta${theta}"

flags="-p $particle -e $energy -x $X -y $Y -z $Z --dx $DX --dy $DY --dz $DZ --phi $phi --dphi $dphi --theta $theta --dtheta $dtheta"
if [ "$tag" != "" ]; then
  flags="${flags} -t $tag"
fi
# Batch or non-batch mode for number of events
if [ $n -ne 0 ]; then
  flags="${flags} -N $n"
  label_job="${label}_N${n}${tag}"
else
  flags="${flags} -N $N"
fi
label="${label}_N${N}${tag}"
# Remove intermediate files
if [ "$rm_flag" = true ]; then
  flags="${flags} --rm"
fi



### RUNNING ###
# Interactive console
if [ $n -eq 0 ]; then
  echo "STARTING: Particle guns of ${N} events in interactive shell"
  flags="${flags} -l ${label}"
  ./scripts/gun_init.sh ${flags}

# Jobs
else
  echo "STARTING: Particle guns of ${N} events with jobs of ${n} events each"
  if [ $N -eq $n ]; then
    sbatch -t 1:00:00 -n 1 --mem 3GB --account t2k -p ${machine} ./scripts/gun_init.sh ${flags} -l ${label}
  else
    for ((i=0; i<N/n; i++)); do
      label_job_here="${label_job}_i${i}"
      flags_job="${flags} -i ${i} -l ${label_job_here}"
      job_mc=$(sbatch -t 1:00:00 -n 1 --mem 4GB --account t2k -p ${machine} ./scripts/gun_init.sh ${flags_job})
      job_mc_id="${job_mc_id}:$(echo $job_mc | awk '{print $NF}')"
      files_data="${files_data} /sps/t2k/tdaret/public/Output_root/MC/2_DetResSim_${label_job_here}.root"
      files_treemaker="${files_treemaker} /sps/t2k/tdaret/public/Output_root/TreeMaker_${label_job_here}.root"
    done
    sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_mc_id ./scripts/TreeMerger.sh -t ${label} -f "${files_data}" -n public/data/MC/
    sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_mc_id ./scripts/TreeMerger.sh -t ${label} -f "${files_treemaker}" -n public/Output_root/TreeMaker_
  fi
fi
