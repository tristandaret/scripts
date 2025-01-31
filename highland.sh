#!/bin/bash

echo $IS_HIGHLAND_SETUP
if [ -z "$IS_HIGHLAND_SETUP" ] || [ "$IS_HIGHLAND_SETUP" -eq 0 ]; then
   source .sourcers.sh
   setup_highland
fi

start=0
nevent=0
datafile=""
tag=""
comment=""
pkg=""
app=""

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
      --pkg)
         if [ "$2" ]; then
            pkg=$2
            shift
         fi
         ;;
      --comment)
         if [ "$2" ]; then
            comment=$2
            shift
         fi
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

# Define default datafile
if [ -z "${datafile}" ]; then
   datafile="oa_nt_beam_90020000-0000_oe4wxnujyrna_anal_000_bsdv01_2"
fi
datapath="/sps/t2k/common/inputs/dirac/t2k.org/nd280/production008/validation/V04/mcp/neut_5.6.4.1_p7c3/2024/magnet/13a_p250kA/runA/anal/"
echo "Data folder:      ${datapath}"
datapath="${datapath}${datafile}.root"
echo "Data file:        ${datafile}"

# Define default pkg and app
if [ -z "${pkg}" ]; then
   pkg="upgradeGammaAnalysis"
   app="RunUpgradeGammaAnalysis"
fi
if [ ${pkg} = "upgradeNueCCAnalysis" ]; then
   app="RunUpgradeNueCCAnalysis"
fi

# Tag
tag="${datafile}"
if [ -n "$comment" ]; then
   tag="${tag}_${comment}"
fi
if [ "$start" -ne 0 ]; then
   tag="${tag}_s${start}"
fi
# Run process for # events (optional)
if [ "$nevent" -ne 0 ]; then
   tag="${tag}_n${nevent}"
fi

# Output file name
highland_output="$HOME/public/Output_highland/${pkg}_${tag}.root"
log="$HOME/public/Output_log/logs_${pkg}_${tag}.log"
echo "logs:             ${log}"
flags="-o ${highland_output}"

# Start process from event number # (optional)
if [ "$start" -ne 0 ]; then
   flags="${flags} -s ${start}"
fi

# Run process for # events (optional)
if [ "$nevent" -ne 0 ]; then
   flags="${flags} -n ${nevent}"
fi

# Check if output file already exists
if [ -f "${highland_output}" ]; then
   read -p "/!\ Output file already exists. Do you want to remove it?" confirm
   if [ -z "$confirm" ] || [ "$confirm" = "y" ]; then
      rm "${highland_output}"
   else
      echo "Exiting without running Highland."
      exit 1
   fi
fi

# Run Highland
echo "Running:          Highland"
echo "Highland flags:   ${flags}"
echo "Highland output:  ${highland_output}"
echo "---    HIGHLAND > ${app}    ---" > "${log}"

./highland/${pkg}/`nd280-system`/bin/${app}.exe ${flags} ${datapath} &>> ${log}