#!/bin/bash
#flags (mandatory): -d datafile and -t tag
#flags (optional):  -n total number of events ; -s starting point

cd ~/hatRecon/`nd280-system`

# Number of events
start=0 # starting from event #
nevent=0 # total number of events processed
tag=""
rm_flag=false

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
    -t)
      if [ "$2" ]; then
        tag=$2
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
    -*) # Missing argument
      printf 'ERROR: Option requires an argument: %s\n' "$1" >&2
      exit 1
      ;;
    *) # No more options
      break
  esac
  shift
done

# Check if -d and -t flags are provided
if [ -z "$datafile" ] || [ -z "$tag" ]; then
  echo "HATRecon.sh usage: $0 [-s starting event | -n number of events ] -d datafile | -t tag"
  exit 1
fi

# # Define data file
# if [[ ${datafile} == *"MC"* ]]; then
#   datafile="$HOME/public/data/MC/${datafile}.root"
# elif [[ ${datafile} == *"R2021"* ]]; then
#   datafile="$HOME/public/data/DESY21/${datafile}.root"
# elif [[ ${datafile} == *"R2022"* ]]; then
#   # datafile="$HOME/public/data/CERN22/${datafile}.root"
#   datafile="/sps/t2k/testbeamdata/CERN-2022/root/trawevents/${datafile}.root"
# elif [[ ${datafile} == *"hatTop_cosmic"* ]]; then
#   datafile="/sps/t2k/tHAT_CERN_Cosmics/${datafile}.daq.mid.gz"
# elif [[ ${datafile} == *"run"* ]]; then
#   datafile="/sps/t2k/giganti/jparc_dog/cosmics/${datafile}.mid.gz"
# else
#   echo "Unknown data file: ${datafile}"
#   exit 1
# fi
# datafile="/sps/t2k/ND280upDataCosmics/magnetON/${datafile}.mid.gz"
# datafile="/sps/t2k/ND280upDataCosmics/magnetOFF/${datafile}.mid.gz"
# datafile="$HOME/public/data/${datafile}.daq.mid.gz"
# datafile="/sps/t2k/Jparc/May_2024/${datafile}.daq.mid.gz"
# datafile="$HOME/public/data/MC/${datafile}.root"
datafile="$HOME/public/data/MC/${datafile}.root"
  # datafile="/sps/t2k/Jparc/May_2024/dog1/hatTree_RHEL/${datafile}.root"

echo "File used:        ${datafile}"

# Output file names
hatrecon_output="$HOME/public/Output_root/HATRecon_${tag}.root"
treemaker_output="$HOME/public/Output_root/TreeMaker_${tag}.root"
log="$HOME/public/Output_log/logs_${tag}.log"
echo "logs:             ${log}"


flags="-R"
# Handle cases with optional flags
if [ "$start" -ne 0 ]; then
  flags="${flags} -s ${start}"
fi

if [ "$nevent" -ne 0 ]; then
  flags="${flags} -n ${nevent}"
fi


echo "Running:          HATRecon"
echo "HATRecon flags:   ${flags}"
echo "HATRecon output:  ${hatrecon_output}"
echo "---    HATRECON    ---" > "${log}"

if [[ ${tag} == *"MC"* ]]; then
  ./bin/HATRECON.exe ${datafile} -o ${hatrecon_output} ${flags} &>> ${log} # MC data
elif [[ ${tag} == *"R2021"* || ${tag} == *"R2022"* ]]; then
  geometry="/sps/t2k/wsaenz/My_files/detres_gun_nu_e_700MeV_g4mc_72800.root"
  echo "Geometry:       ${geometry}"
  echo "< hatRecon.TestBeamFile = ${datafile} >" > new_par.dat
  ./bin/HATRECON.exe -o ${hatrecon_output} ${geometry} -O par_override=./new_par.dat ${flags} &>> ${log} #test beam data
else
  geometry="/sps/t2k/tdaret/public/data/geom_bHAT_50k.root"
  echo "Geometry:         ${geometry}"
  ./bin/HATRECON.exe -G ${geometry} -m ${datafile} -o ${hatrecon_output} ${flags} &>> ${log} # real data
fi

echo "Running: TreeMaker"
echo "TreeMaker output: ${treemaker_output}"
echo -e "\n---   TREEMAKER   ---" >> "${log}"

./bin/HATRECONTREEMAKER.exe -R -O outfile=${treemaker_output} ${hatrecon_output} &>> ${log}

if [[ "$rm_flag" = true ]]; then
  rm ${hatrecon_output}
fi


# hatrecon_output_ref0="$HOME/public/Output_root/HATRecon_${datafile}_n1.root"
# if [ "$nevent" -ne 1 ]; then
#   if [[ ${datafile} == *"hatTop_cosmic"* ]]; then
#     hadd -a ${hatrecon_output} ${hatrecon_output_ref0}
#   fi
#   ./bin/HATRECONTREEMAKER.exe -R -O outfile=${treemaker_output} ${hatrecon_output} &> ${treemaker_output_log}
# fi