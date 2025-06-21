#!/bin/bash

start=0       # starting event
N=0           # number of events analyzed (0: all)
n=0           # number of events per job
comment=""
rm_flag=false
SR_flag=false
AC_flag=false
submit="job"
machine="htc"
merge=false
make_flag=false
cleaning=false
datatype=""


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
         comment=_$2
         shift
      fi
      ;;
      --sr)
         SR_flag=true
      ;;
      --ac)
         AC_flag=true
      ;;
      --clean)
      cleaning=true
      ;;
      --submit)
      if [ "$2" ]; then
         submit=$2
         shift
      fi
      ;;
      --machine)
      if [ "$2" ]; then
         machine=$2
         shift
      fi
      ;;
      --merge)
      merge=true
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

# Cleaning
if [ "$cleaning" = true ]; then
  $HOME/scripts/utils/cleaning.sh
fi

# Make hatRecon
if [ "$make_flag" = true ]; then
   source $HOME/scripts/t2k_utils/.sourcers.sh
   make_hatRecon
fi

# Check submission mode validity
if [ "$submit" != "local" ] && [ "$submit" != "job" ]; then
   echo "WARNING: unknown submission mode. Possibilities are either 'local' or 'job'."
   echo "WARNING: Default option ${submit} will be used."
fi

# Handle case without -d flag
if [ -z "$datafile" ]; then
   # datafile="R2021_07_02-11_26_27-000" #DESY21 electrons 4 GeV
   # datafile="R2022_09_07-21_38_55-000" #CERN2022 muons +1GeV full mockup
   datafile="dog1_00001148_0000" # Default cosmics with B field
   # datafile="MC_mu-_400MeV_x0_y75_z-300_phi0_theta0_horizontal_14.29_N5000"
   # datafile="MC_mu-_400MeV_x0_y120_z-190_phi-90_theta0_vertical_14.29_N5000"
fi

# Determine the datatype
if [[ "$datafile" == *"MC"* ]]; then
   datatype="MC"
else [[ "$datafile" == *"dog1"* ]]
   datatype="cosmics"
fi

# Define flags and tags
flags="-d ${datafile}"
tags="${datafile}"

# Handle case with optional flag
# Start point
if [ "$start" -ne 0 ]; then
  flags="${flags} -s ${start}"
fi
tags="${tags}_s${start}"

# Number of events
if [ "$N" -ne 0 ]; then
  flags="${flags} -n ${N}"
  tags="${tags}_n${N}"
else
  tags="${tags}_nAll"
fi

# Number of events per job
if [ "$n" -ne 0 ]; then
  flags_iter="-d ${datafile} -n ${n}"
fi

# Run Spatial Resolution app
if [ "$SR_flag" = true ]; then
  flags="${flags} --sr"
fi

# Run Analysis of Cosmics app
if [ "$AC_flag" = true ]; then
  flags="${flags} --ac"
fi

# Add comment if any
if [ "$comment" != "" ]; then
  tags="${tags}${comment}"
fi

# Final list of arguments
flags="${flags} --tags ${tags}"

# Remove intermediate files
if [[ "$rm_flag" = true ]]; then
  flags="${flags} --rm"
  flags_iter="${flags_iter} --rm"
fi

# Time limit
time="10:00:00"
# Limit time for jobs if using flash
if [[ "$machine" == "flash" ]]; then
  time="01:00:00"
fi
# Limit time for merging jobs when running a whole file
time_merge="0:10:00"
if [ $N -eq 0 ]; then
   time_merge="02:00:00"
fi

# Submitting
if [ "$submit" == "local" ]; then # Submit locally
   echo "STARTING: hatRecon for ${N} events from event ${start}"
   echo "flags:            ${flags}"
   ./scripts/execute/hat_reco_execute.sh ${flags}

elif [ "$submit" == "job" ]; then # Submit jobs
   if [ "$N" -eq 0 ]; then # if N=0, run all events in one job
      echo "STARTING: hatRecon for ALL events in one job"
      echo "flags:            ${flags}"
      sbatch -t "${time}" -n 1 --mem 5GB --account t2k -p ${machine} ./scripts/execute/hat_reco_execute.sh ${flags}
   elif [ "$N" -ne 0 ]; then # if N!=0, run N events in parallel jobs
      if [ "$n" -eq 0 ]; then 
         echo "ERROR: Number of events per job not defined"
         exit 1
      elif [ "$n" -ne 0 ]; then
         echo "STARTING: hatRecon for ${N} events with parallel jobs of ${n} events each from event ${start}"
         echo "flags: ${flags}"
         for ((s = start; s < start+N; s += n)); do
            tags_iter="${datafile}_s${s}_n${n}${comment}"
            flags_iter_here="${flags_iter} -s ${s} --tags ${tags_iter}"
            echo "flags_iter_here: ${flags_iter_here}"
            job_hatrecon=$(sbatch -t "${time}" -n 1 --mem 5GB --account t2k -p ${machine} ./scripts/execute/hat_reco_execute.sh ${flags_iter_here})
            job_hatrecon_id="${job_hatrecon_id}:$(echo $job_hatrecon | awk '{print $NF}')"
            files_hatrecon="${files_hatrecon} /sps/t2k/tdaret/public/output_hatRecon/root/${datatype}/hatRecon_${datafile}_s${s}_n${n}${comment}.root"
            files_treemaker="${files_treemaker} /sps/t2k/tdaret/public/output_hatRecon/root/${datatype}/TreeMaker_${datafile}_s${s}_n${n}${comment}.root"
            files_SR="${files_SR} /sps/t2k/tdaret/public/output_hatRecon/root/${datatype}/SpatialResolution_${datafile}_s${s}_n${n}${comment}.root"
         done
         if [ "$merge" = true ]; then
            sbatch -t "${time_merge}" -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/t2k_utils/tree_merger.sh -t ${tags} -f "${files_hatrecon}" -n public/output_hatRecon/root/${datatype}/hatRecon_
            sbatch -t "${time_merge}" -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/t2k_utils/tree_merger.sh -t ${tags} -f "${files_treemaker}" -n public/output_hatRecon/root/${datatype}/TreeMaker_
            if [ "$SR_flag" = true ]; then
               sbatch -t "${time_merge}" -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/t2k_utils/tree_merger.sh -t ${tags} -f "${files_SR}" -n public/output_hatRecon/root/${datatype}/SpatialResolution_
            fi # Spatial Resolution
            if [ "$AC_flag" = true ]; then
               sbatch -t "${time_merge}" -n 1 --mem 2GB --account t2k -p ${machine} --dependency=afterok$job_hatrecon_id ./scripts/t2k_utils/tree_merger.sh -t ${tags} -f "${files_AC}" -n public/output_hatRecon/root/${datatype}/AnaCosmics_
            fi # Analysis of cosmics
         fi # Merge
      fi # check n is passed
   fi # number of jobs
fi # submit