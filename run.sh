#!/bin/bash
#flags (mandatory): -d datafile
#flags (optional): -s starting at event number s ; -N number of events ; -n number of events per jobs

rm $HOME/slurm-*.out
rm $HOME/plots/*.pdf

start=0       # starting event
N=0           # never of events analyzed (0: all)
n=0           # number of events per job
comment="_trash"
rm_flag=false
make_flag=false
machine="htc"


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
        datatag=$2
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
    -*) # Missing argument
      printf 'ERROR: Option requires an argument: %s\n' "$1" >&2
      exit 1
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


# Handle case without -d flag
if [ -z "$datatag" ]; then
  datatag="run15504_00" #JPARC cosmics MAGNET ON November 2023
  # datatag="nd280_00016070_0004" #JPARC cosmics MAGNET ON November 2023
  # datatag="run01407_09" #JPARC cosmics MAGNET OFF March 4
  # datatag="run01397_18" #JPARC cosmics MAGNET ON March 4
  # datatag="hatTop_cosmic_00000019_0004" # tHAT cosmics CERN 350V  27.5kV center (run with pbs_nd280 14.10)
  # datatag="hatTop_cosmic_00000024_0002" # tHAT cosmics CERN G2200 27.5kV center
  # datatag="hatTop_cosmic_00000030_0000" # tHAT cosmics CERN G2200 20.0kV center
  # datatag="hatTop_cosmic_00000032_0002" # tHAT cosmics CERN G2200 27.5kV left
  # datatag="hatTop_cosmic_00000033_0002" # tHAT cosmics CERN G2200 27.5kV right
  # datatag="MC_mum_vert" #Cosmics 0.4 to 5GeV muons- 
fi

flags="-d ${datatag}"
tag="${datatag}"

# Handle case with optional flag
if [ "$start" -ne 0 ]; then
  flags="${flags} -s ${start}"
fi
tag="${tag}_s${start}"

if [ "$N" -ne 0 ]; then
  flags="${flags} -n ${N}"
  tag="${tag}_n${N}"
else
  tag="${tag}_nall"
fi

if [ "$n" -ne 0 ]; then
  flags_iter="-d ${datatag} -n ${n}"
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
  echo "STARTING: HATRecon for ${N} events in interactive shell"
  echo "flags: ${flags}"
  ./scripts/HATRecon.sh ${flags}

# Parallelization
else
  echo "STARTING: HATRecon for ${N} events with parallel jobs of ${n} events each"
  echo "flags: ${flags}"
  if [ $N -eq $n ]; then # single job
    sbatch -t 1:00:00 -n 1 --mem 3GB --account t2k -p ${machine} ./scripts/HATRecon.sh ${flags}
  else # several jobs
    for ((s = 0; s < N; s += n)); do
      tag_iter="${datatag}_s${s}_n${n}${comment}"
      flags_iter_here="${flags_iter} -s ${s} -t ${tag_iter}"
      echo "flags_iter_here: ${flags_iter_here}"
      job_hatrecon=$(sbatch -t 1:00:00 -n 1 --mem 3GB --account t2k -p ${machine} ./scripts/HATRecon.sh ${flags_iter_here})
      job_hatrecon_id="${job_hatrecon_id}:$(echo $job_hatrecon | awk '{print $NF}')"
      files_treemaker="${files_treemaker} /sps/t2k/tdaret/public/Output_root/TreeMaker_${datatag}_s${s}_n${n}${comment}.root"
    done
    sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/TreeMerger.sh -t ${tag} -f "${files_treemaker}" -n public/Output_root/TreeMaker
  fi
fi


  # Stupid step necessary to be able to run TreeMaker with files starting from an event > 0 because important information is written in the fake event 0
  # echo "Making HATRecon file with 1 event necessary to run TreeMaker"
  # job_hat0=$(sbatch -t 0:02:00 -n 1 --mem 2GB --account t2k -p ${machine} ./scripts/HATRecon.sh -d ${datatag} -n 1 -t ${datatag}_n1)
  # job_hat0_id="$(echo $job_hat0 | awk '{print $NF}')"
    # job_hatrecon=$(sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterany:$job_hat0_id ./scripts/HATRecon.sh ${flags_iter})