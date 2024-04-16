#!/bin/bash
#flags (mandatory): -d datatag and -t tag
#flags (optional):  -n total number of events ; -s starting point

cd ~/hatRecon/`nd280-system`

# Number of events
start=0 # starting from event #
nevent=0 # total number of events processed

# Parse command-line arguments
while getopts ":s:n:d:t:" opt; do
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
    t)
      tag="$OPTARG"
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

echo "File used: ${datafile}"


# Output file names
hatrecon_output_root="/sps/t2k/tdaret/public/Output_root/HATRecon_${tag}.root"
hatrecon_output_root_ref0="/sps/t2k/tdaret/public/Output_root/HATRecon_${datatag}_n1.root"
hatrecon_output_log="/sps/t2k/tdaret/public/Output_log/HATRecon_${tag}.log"
treemaker_output_root="/sps/t2k/tdaret/public/Output_root/TreeMaker_${tag}.root"
treemaker_output_log="/sps/t2k/tdaret/public/Output_log/TreeMaker_${tag}.log"


flags="-R"
# Handle cases with optional flags
if [ "$start" -ne 0 ]; then
  flags="${flags} -s ${start}"
fi

if [ "$nevent" -ne 0 ]; then
  flags="${flags} -n ${nevent}"
fi

geometry_root="/sps/t2k/uvirgine/Work/nd280_Software/anaCosmics20231002/geometry.root"
echo "Running with JPARC cosmics geometry ${geometry_root}"
echo "HATRecon tag: ${tag}"
echo "HATRecon flags: ${flags}"
echo "Running: HATRecon"
# ./bin/HATRECON.exe -G ${geometry_root} -m ${datafile} -o ${hatrecon_output_root} ${flags} &> ${hatrecon_output_log}
./bin/HATRECON.exe ${datafile} -o ${hatrecon_output_root} ${flags} &> ${hatrecon_output_log}
if [ "$nevent" -ne 1 ]; then
  if [[ ${datatag} == *"hatTop_cosmic"* ]]; then
    hadd -a ${hatrecon_output_root} ${hatrecon_output_root_ref0}
  fi
  echo "Running: TreeMaker"
  echo "treemaker_output_root: ${treemaker_output_root}"
  echo "treemaker_output_log: ${treemaker_output_log}"
  echo "hatrecon_output_root: ${hatrecon_output_root}"
  echo "hatrecon_output_log: ${hatrecon_output_log}"
  ./bin/HATRECONTREEMAKER.exe -R -O outfile=${treemaker_output_root} ${hatrecon_output_root} &> ${treemaker_output_log}
fi
# ./bin/HATRECONTREEMAKER.exe -R -O outfile=${treemaker_output_root} ${hatrecon_output_root} &> ${treemaker_output_log}
