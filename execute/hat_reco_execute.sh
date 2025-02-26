#!/bin/bash

# Number of events
start=0 # starting from event #
nevent=0 # total number of events processed
tags=""
rm_flag=false
SR_flag=false
AC_flag=false

# Parse command-line arguments
while :; do
   case $1 in
      -s)
      if [ "$2" ]; then
         start=$2
         shift
      fi
      ;;
      -n)
      if [ "$2" ]; then
         nevent=$2
         shift
      fi 
      ;;
      -d)
      if [ "$2" ]; then
         datafile=$2
         shift
      fi
      ;;
      --tags)
      if [ "$2" ]; then
         tags=$2
         shift
      fi
      ;;
      --sr)
         SR_flag=true
      ;;
      --ac)
         AC_flag=true
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

# Define data file
datarun="${datafile:0:${#datafile}-5}"
if [[ "$datafile" == *"hat"* ]]; then
  datafile="/sps/t2k/Jparc/May_2024/${datafile}.daq.mid.gz"
elif [[ "$datafile" == *"dog1"* ]]; then
  datafile="/sps/t2k/Jparc/May_2024/dog1/${datarun}/${datafile}.daq.mid.gz"
elif [[ "$datafile" == *"MC"* ]]; then
  datafile="$HOME/public/data/MC/${datafile}.root"
fi
echo "File used:        ${datafile}"

# Output file names
if [[ "$datafile" == *"MC"* ]]; then
   hatrecon_output="$HOME/public/output_hatRecon/root/MC/hatRecon_${tags}.root"
   treemaker_output="$HOME/public/output_hatRecon/root/MC/TreeMaker_${tags}.root"
   SR_output="$HOME/public/output_hatRecon/root/MC/SpatialResolution_${tags}.root"
   AC_output="$HOME/public/output_hatRecon/root/MC/AnaCosmics_${tags}.root"
else
   hatrecon_output="$HOME/public/output_hatRecon/root/cosmics/hatRecon_${tags}.root"
   treemaker_output="$HOME/public/output_hatRecon/root/cosmics/TreeMaker_${tags}.root"
   SR_output="$HOME/public/output_hatRecon/root/cosmics/SpatialResolution_${tags}.root"
   AC_output="$HOME/public/output_hatRecon/root/cosmics/AnaCosmics_${tags}.root"
fi
log="$HOME/public/output_hatRecon/logs/logs_${tags}.log"
echo "logs:             ${log}"


flags="-R"
# Handle cases with optional flags
if [ "$start" -ne 0 ]; then
  flags="${flags} -s ${start}"
fi

if [ "$nevent" -ne 0 ]; then
  flags="${flags} -n ${nevent}"
fi


echo "Running:          hatRecon"
echo "hatRecon flags:   ${flags}"
echo "hatRecon output:  ${hatrecon_output}"
echo "--- STEP 1:   HATRECON    ---" > "${log}"

if [[ ${tags} == *"MC"* ]]; then # MC data
  time $HOME/hatRecon/`nd280-system`/bin/HATRECON.exe ${datafile} -o ${hatrecon_output} ${flags} &>> ${log}
elif [[ ${tags} == *"R2021"* || ${tags} == *"R2022"* ]]; then #test beam data
  geometry="/sps/t2k/wsaenz/My_files/detres_gun_nu_e_700MeV_g4mc_72800.root"
  echo "Geometry:       ${geometry}"
  echo "< hatRecon.TestBeamFile = ${datafile} >" > new_par.dat
  time $HOME/hatRecon/`nd280-system`/bin/HATRECON.exe -o ${hatrecon_output} ${geometry} -O par_override=./new_par.dat ${flags} &>> ${log}
else # real data
  geometry="/sps/t2k/tdaret/public/data/geom_baseline2024_50k.root"
  echo "Geometry:         ${geometry}"
  time $HOME/hatRecon/`nd280-system`/bin/HATRECON.exe -G ${geometry} -m ${datafile} -o ${hatrecon_output} ${flags} &>> ${log}
fi

echo "Running:          TreeMaker"
echo "TreeMaker output: ${treemaker_output}"
echo -e "\n--- STEP2:  TREEMAKER   ---" >> "${log}"
time $HOME/hatRecon/`nd280-system`/bin/HATRECONTREEMAKER.exe -R -O outfile=${treemaker_output} ${hatrecon_output} &>> ${log}

if [[ "$SR_flag" = true ]]; then
   echo "Running: SpatialResolution"
   echo "SpatialResolution output: ${SR_output}"
   echo -e "\n--- STEP3:  SPATIALRESOLUTION   ---" >> "${log}"
   time $HOME/hatRecon/`nd280-system`/bin/SpatialResolution.exe -R -O outfile=${SR_output} ${hatrecon_output} &>> ${log}
fi

if [[ "$AC_flag" = true ]]; then
   echo "Running: AnaCosmics"
   echo "AnaCosmics output: ${SR_output}"
   echo -e "\n--- STEP4:  ANACOSMICS   ---" >> "${log}"
   time $HOME/hatRecon/`nd280-system`/bin/ANACOSMICS.exe -R -O outfile=${AC_output} ${hatrecon_output} &>> ${log}
fi

if [[ "$rm_flag" = true ]]; then
  rm -f ${SR_output} ${AC_output} #${hatrecon_output}
fi