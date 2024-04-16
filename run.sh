#!/bin/bash
#flags (mandatory): -d datafile
#flags (optional): -s starting at event number s ; -n number of events ; -i step size for parallelization of jobs ; -m running mode

cd ~/hatRecon/`nd280-system`
cmake ../cmake/
make -j40
cd ../..

start=0       # starting event
nevent=0      # never of eventsanalyzed (0: all)
mode=0        # run mode (0 local, 1 job, 2 parallel)
iterator=500  # parallelize job with 1k event each
comment="_trash"


# Parse command-line arguments
while getopts ":d:s:n:i:m:" opt; do
  case $opt in
    s)
      start="$OPTARG"
      ;;
    n)
      nevent="$OPTARG"
      ;;
    d)
      datatag="$OPTARG"
      ;;
    i)
      iterator="$OPTARG"
      ;;
    m)
      mode="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


# Handle case without -d flag
if [ -z "$datatag" ]; then
  # datatag="run15504_00" #JPARC cosmics MAGNET ON November 2023
  # datatag="nd280_00016070_0004" #JPARC cosmics MAGNET ON November 2023
  # datatag="run01407_09" #JPARC cosmics MAGNET OFF March 4
  # datatag="run01397_18" #JPARC cosmics MAGNET ON March 4
  # datatag="hatTop_cosmic_00000019_0004" # tHAT cosmics CERN 350V  27.5kV center (run with pbs_nd280 14.10)
  # datatag="hatTop_cosmic_00000024_0002" # tHAT cosmics CERN G2200 27.5kV center
  # datatag="hatTop_cosmic_00000030_0000" # tHAT cosmics CERN G2200 20.0kV center
  # datatag="hatTop_cosmic_00000032_0002" # tHAT cosmics CERN G2200 27.5kV left
  # datatag="hatTop_cosmic_00000033_0002" # tHAT cosmics CERN G2200 27.5kV right
  datatag="MC_mum_vert" #Cosmics 0.4 to 5GeV muons- 
fi

flags="-d ${datatag}"
tag="${datatag}"

# Handle case with optional flag
if [ "$start" -ne 0 ]; then
  flags="${flags} -s ${start}"
fi
tag="${tag}_s${start}"

if [ "$nevent" -ne 0 ]; then
  flags="${flags} -n ${nevent}"
  tag="${tag}_n${nevent}"
else
  tag="${tag}_nall"

fi

# Setting details
tag="${tag}${comment}"
# Final list of arguments
flags="${flags} -t ${tag}"



# Run in interactive
if [ "$mode" -eq 0 ]; then
  echo "Starting HATRecon in interactive console (local)"
  echo "flags: ${flags}"
  ./HATRecon.sh ${flags}


# Run in batch
elif [ "$mode" -eq 1 ]; then
  echo "Starting HATRecon as a job on CCLyon"
  echo "flags: ${flags}"
  job_hatrecon=$(sbatch -t 4:00:00 -n 2 --mem 8GB --account t2k -p htc ./HATRecon.sh ${flags})




# Run in parallel
elif [ "$mode" -eq 2 ]; then
  if [ "$nevent" -eq 0 ]; then
    echo "To run parallelized job, you must submit a number of events using the -n flag"
    exit 1
  fi
  echo "Starting HATRecon (parallel jobs)"
  echo "flags: ${flags}"
  # Stupid step necessary to be able to run TreeMaker with files starting from an event > 0 because important information is written in the fake event 0
  # echo "Making HATRecon file with 1 event necessary to run TreeMaker"
  # job_hat0=$(sbatch -t 0:02:00 -n 1 --mem 2GB --account t2k -p htc ./HATRecon.sh -d ${datatag} -n 1 -t ${datatag}_n1)
  # job_hat0_id="$(echo $job_hat0 | awk '{print $NF}')"
  for ((s = 0; s < nevent; s += iterator)); do
    tag_iter="${datatag}_s${s}_n${iterator}${comment}"
    flags_iter="-d ${datatag} -s ${s} -n ${iterator} -t ${tag_iter}"
    echo "flags_iter: ${flags_iter}"
    # job_hatrecon=$(sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p htc --dependency=afterany:$job_hat0_id ./HATRecon.sh ${flags_iter})
    job_hatrecon=$(sbatch -t 1:00:00 -n 1 --mem 3GB --account t2k -p htc ./HATRecon.sh ${flags_iter})
    job_hatrecon_id="${job_hatrecon_id}:$(echo $job_hatrecon | awk '{print $NF}')"
    files_treemaker="${files_treemaker} /sps/t2k/tdaret/public/Output_root/TreeMaker_${datatag}_s${s}_n${iterator}${comment}.root"
  done
  sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p htc --dependency=afterok$job_hatrecon_id ./TreeMerger.sh -t ${tag} -f "${files_treemaker}"
  # sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p htc ./TreeMerger.sh -t ${tag} -f "${files_treemaker}"

else
  echo "Argument of flag -m was not recognized. [0 local, 1 single job, 2 parallel jobs]" >&2
  exit 1
fi