#!/bin/bash
source ~/.bashrc
#flags (mandatory): -d datafile
#flags (optional): -s starting at event number s ; -N number of events ; -n number of events per jobs

start=0       # starting event
N=0           # number of events analyzed (0: all)
n=0           # number of events per job
comment=""
rm_flag=false
make_flag=false
machine="htc"
cleaning=false


# Parse command-line arguments
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
    -*) # Missing argument
      printf 'ERROR: Option requires an argument: %s\n' "$1" >&2
      exit 1
      ;;
    *) # No more options
      break
  esac
  shift
done

if [ "$cleaning" = true ]; then
  $HOME/scripts/cleaning.sh
fi
module load Libraries/fftw/3.3.10
if [ "$make_flag" = true ]; then
  (cd $HOME/hatRecon/`nd280-system`
  cmake ../cmake/
  make -j16)
fi
module load Libraries/fftw/3.3.10

# Handle case without -d flag
if [ -z "$datafile" ]; then
  # datafile="R2021_07_02-11_26_27-000" #DESY21 electrons 4 GeV
  # datafile="R2022_09_07-21_38_55-000" #CERN2022 muons +1GeV full mockup
  # datafile="MC_mu+_50-3000MeV_x0_y105_z-200_phi-90_theta0_N20000"
  # datafile="2_DetResSim_MC_mu-_600MeV_x-50_y-75_z-190_phi0_theta0_N20"
  datafile="dog1_00001022_0000"
fi

flags="-d ${datafile}"
tag="${datafile}"

# Handle case with optional flag
if [ "$start" -ne 0 ]; then
  flags="${flags} -s ${start}"
fi
tag="${tag}_s${start}"

if [ "$N" -ne 0 ]; then
  flags="${flags} -n ${N}"
  tag="${tag}_n${N}"
else
  tag="${tag}_nAll"
fi

if [ "$n" -ne 0 ]; then
  flags_iter="-d ${datafile} -n ${n}"
fi

# Setting details
tag="${tag}${comment}"
# Final list of arguments
flags="${flags} -t ${tag}"
# Remove intermediate files
if [[ "$rm_flag" = true ]]; then
  flags="${flags} --rm"
  flags_iter="${flags_iter} --rm"
fi


# Run in interactive shell
if [ ${n} -eq 0 ]; then
  if [ "$N" -ne 0 ]; then
    echo "STARTING: HATRecon for ${N} events in interactive shell"
  else
    echo "STARTING: HATRecon for all events in interactive shell"
  fi
  echo "flags:            ${flags}"
  ./scripts/analysis.sh ${flags}

# Parallelization
else
  echo "STARTING: HATRecon for ${N} events with parallel jobs of ${n} events each from event ${start}"
  echo "flags: ${flags}"
  # single job
  if [ $N -eq $n ]; then
    sbatch -t 1:00:00 -n 1 --mem 3GB --account t2k -p ${machine} ./scripts/analysis.sh ${flags}
  # several jobs
  else
    for ((s = start; s < start+N; s += n)); do
      tag_iter="${datafile}_s${s}_n${n}${comment}"
      flags_iter_here="${flags_iter} -s ${s} -t ${tag_iter}"
      echo "flags_iter_here: ${flags_iter_here}"
      job_hatrecon=$(sbatch -t 2:00:00 -n 1 --mem 6GB --account t2k -p ${machine} ./scripts/analysis.sh ${flags_iter_here})
      job_hatrecon_id="${job_hatrecon_id}:$(echo $job_hatrecon | awk '{print $NF}')"
      files_hatrecon="${files_hatrecon} /sps/t2k/tdaret/public/Output_root/HATRecon_${datafile}_s${s}_n${n}${comment}.root"
      files_treemaker="${files_treemaker} /sps/t2k/tdaret/public/Output_root/TreeMaker_${datafile}_s${s}_n${n}${comment}.root"
    done
    # sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/tree_merger.sh -t ${tag} -f "${files_hatrecon}" -n public/Output_root/hatRecon_
    sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/tree_merger.sh -t ${tag} -f "${files_treemaker}" -n public/Output_root/TreeMaker_
  fi
fi