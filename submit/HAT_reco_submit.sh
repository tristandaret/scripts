#!/bin/bash

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

if [ "$make_flag" = true ]; then
  (cd $HOME/hatRecon/`nd280-system`
  make -j16)
fi

# Handle case without -d flag
if [ -z "$datafile" ]; then
   # datafile="R2021_07_02-11_26_27-000" #DESY21 electrons 4 GeV
   # datafile="R2022_09_07-21_38_55-000" #CERN2022 muons +1GeV full mockup
   # datafile="hat_00000885_0000"
   # datafile="MC_mu+_50-3000MeV_x0_y105_z-200_phi-90_theta0_N20000"
   # datafile="DRS_MC_mu-_600MeV_x50_y115_z-250_phi-90_theta0_systLUT"
   # datafile="DRS_MC_mu-_600MeV_x50_y113_z-275_phi-40_theta0_systLUT"
   # datafile="DRS_MC_mu-_600MeV_x50_y113_z-275_phi0_theta0_systLUT"
   # datafile="DRS_MC_mu-_600MeV_x96_y100_z-275_phi0_theta0_systLUT_N5000"
   # datafile="DRS_MC_mu-_600MeV_x96_y100_z-275_phi-40_theta0_systLUT_N5000"
   # datafile="dog1_00001022_0000" # first wf bins a bit too early
   datafile="dog1_00001148_0000" # Default cosmics with B field
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
tags="${tags}${comment}"
# Final list of arguments
flags="${flags} --tags ${tags}"
# Remove intermediate files
if [[ "$rm_flag" = true ]]; then
  flags="${flags} --rm"
  flags_iter="${flags_iter} --rm"
fi


# Run in interactive shell
if [ ${n} -eq 0 ]; then
   if [ "$N" -ne 0 ]; then
      echo "STARTING: HATRecon for ${N} events in interactive shell"
      echo "flags:            ${flags}"
      ./scripts/analysis.sh ${flags}
   elif [ "$N" -eq 0 ]; then
      echo "STARTING: HATRecon for ALL events in one bash job"
      echo "flags:            ${flags}"
      sbatch -t 5:00:00 -n 1 --mem 10GB --account t2k -p ${machine} ./scripts/analysis.sh ${flags}
   fi

# Parallelization
else
   echo "STARTING: HATRecon for ${N} events with parallel jobs of ${n} events each from event ${start}"
   echo "flags: ${flags}"
   # single job
   if [ $N -eq $n ]; then
      sbatch -t 3:00:00 -n 1 --mem 6GB --account t2k -p ${machine} ./scripts/analysis.sh ${flags}
   # several jobs
   else
      for ((s = start; s < start+N; s += n)); do
         tags_iter="${datafile}_s${s}_n${n}${comment}"
         flags_iter_here="${flags_iter} -s ${s} --tags ${tags_iter}"
         echo "flags_iter_here: ${flags_iter_here}"
         job_hatrecon=$(sbatch -t 2:00:00 -n 1 --mem 4GB --account t2k -p ${machine} ./scripts/analysis.sh ${flags_iter_here})
         job_hatrecon_id="${job_hatrecon_id}:$(echo $job_hatrecon | awk '{print $NF}')"
         files_hatrecon="${files_hatrecon} /sps/t2k/tdaret/public/Output_root/HATRecon_${datafile}_s${s}_n${n}${comment}.root"
         files_treemaker="${files_treemaker} /sps/t2k/tdaret/public/Output_root/TreeMaker_${datafile}_s${s}_n${n}${comment}.root"
         # files_SR="${files_SR} /sps/t2k/tdaret/public/Output_root/SpatialResolution_${datafile}_s${s}_n${n}${comment}.root"
      done
      sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/tree_merger.sh --tags ${tags} -f "${files_hatrecon}" -n public/Output_root/HATRecon_
      sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/tree_merger.sh --tags ${tags} -f "${files_treemaker}" -n public/Output_root/TreeMaker_
      #  sbatch -t 0:10:00 -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/tree_merger.sh --tags ${tags} -f "${files_SR}" -n public/Output_root/SpatialResolution_
   fi
fi