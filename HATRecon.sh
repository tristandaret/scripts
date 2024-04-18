#!/bin/bash
#flags (mandatory): -d datatag and -t tag
#flags (optional):  -n total number of events ; -s starting point

cd ~/hatRecon/`nd280-system`

# Number of events
start=0 # starting from event #
nevent=0 # total number of events processed
tag=""
rm_flag = false

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
        datatag=$2
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
if [ -z "$datatag" ] || [ -z "$tag" ]; then
  echo "HATRecon.sh usage: $0 [-s starting event | -n number of events ] -d datatag | -t tag"
  exit 1
fi

# Define data file
if [[ ${datatag} == *"hatTop_cosmic"* ]]; then
  datafile="/sps/t2k/tHAT_CERN_Cosmics/${datatag}.daq.mid.gz"
elif [[ ${datatag} == *"run"* ]]; then
  datafile="/sps/t2k/giganti/jparc_dog/cosmics/${datatag}.mid.gz"
elif [[ ${datatag} == *"MC_mum_vert"* ]]; then
  datafile="/sps/t2k/uvirgine/Work/testSoft14.18/det_gun_mu-_400-5000MeV_BFieldMap_100000evt_g4mc.root"
else
  echo "Unknown datatag: ${datatag}"
  exit 1
fi
# datafile="/sps/t2k/ND280upDataCosmics/magnetON/${datatag}.mid.gz"
# datafile="/sps/t2k/ND280upDataCosmics/magnetOFF/${datatag}.mid.gz"

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
else
  geometry="/sps/t2k/uvirgine/Work/nd280_Software/anaCosmics20231002/geometry.root"
  echo "Geometry:         ${geometry}"
  ./bin/HATRECON.exe -G ${geometry} -m ${datafile} -o ${hatrecon_output} ${flags} &>> ${log} # real data
fi

echo "Running: TreeMaker"
echo "TreeMaker output: ${treemaker_output}"
echo -e "\n---   TREEMAKER   ---" >> "${log}"
./bin/HATRECONTREEMAKER.exe -R -O outfile=${treemaker_output} ${hatrecon_output} &>> ${log}

if [[ "$rm_flag" = true ]]; then
  echo "in remove condition"
  rm ${hatrecon_output} ${log}
fi


# hatrecon_output_ref0="$HOME/public/Output_root/HATRecon_${datatag}_n1.root"
# if [ "$nevent" -ne 1 ]; then
#   if [[ ${datatag} == *"hatTop_cosmic"* ]]; then
#     hadd -a ${hatrecon_output} ${hatrecon_output_ref0}
#   fi
#   ./bin/HATRECONTREEMAKER.exe -R -O outfile=${treemaker_output} ${hatrecon_output} &> ${treemaker_output_log}
# fi