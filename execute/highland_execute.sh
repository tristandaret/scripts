#!/bin/bash
#
# highland_execute.sh
# Purpose: Wrapper to run Highland analysis packages on input ROOT files. Sets up
#          environment (calls setup_highland) and runs the requested package.
#
# WARNING (Documentation-only):
#   This script is provided for documentation and learning; it is NOT intended to
#   be executed from the public repository. It references site-specific setup
#   and build targets.
#
# Example (documentation only):
#   ./highland_execute.sh --pkg gammaHAT -d myfile.root -n 100
#
# Notes:
#   The original script checks/sets up Highland. The operational body is left
#   as-is below for readers.

if [ -z "$IS_HIGHLAND_SETUP" ] || [ "$IS_HIGHLAND_SETUP" -eq 0 ]; then
   source $HOME/scripts/t2k_utils/.sourcers.sh
   setup_highland
fi

start=0
nevent=0
pkg="gammaHAT"
datafile="eventAnalysis_MC_mu-_600MeV_x-50_y0_z-300_phi0_theta0_N10000" # Default
# datafile="oa_nt_beam_90020000-0000_oe4wxnujyrna_anal_000_bsdv01_2" # Default
datafolder="$HOME/public/output_nd280/root/MC" # Default
# datafolder="/sps/t2k/common/inputs/dirac/t2k.org/nd280/production008/validation/V04/mcp/neut_5.6.4.1_p7c3/2024/magnet/13a_p250kA/runA/anal" # Default
tag=""
comment=""
make_flag=false

flags=""

# Parse command-line arguments
while :; do
   case $1 in
      -c)
         flags="${flags} -c" # run in cosmics mode
         ;;
      -v)
         flags="${flags} -v" # ignore highland compiler version
         ;;
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
      --make)
         make_flag=true
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

# ----- APP -----------------------------------------------------------------------------------------------------------
if [ "$pkg" = "gammaHAT" ]; then
   echo "Package:          gammaHAT"
   package="upgradeGammaHATAnalysis"
   app="RunUpgradeGammaHATAnalysis"
elif [ "$pkg" = "gamma" ]; then
   echo "Package:          gamma"
   package="upgradeGammaAnalysis"
   app="RunUpgradeGammaAnalysis"
else
   echo "ERROR: Unknown pkg"
   exit 1
fi

# ----- MAKE ----------------------------------------------------------------------------------------------------------
if [ "$make_flag" = true ]; then
   echo "Making upgradeGammaHATAnalysis"
   source $HOME/scripts/t2k_utils/.sourcers.sh
   make_gamma
fi


#  ----- DATAFILE -----------------------------------------------------------------------------------------------------
# Precise data folder for each data file type
if [[ ${datafile} == *"MC"* ]]; then # MC data
   datafolder="$HOME/public/output_nd280/root/MC"
fi
echo "Data folder:      ${datafolder}"
datapath="${datafolder}/${datafile}.root"
echo "Data path:        ${datapath}"

# ----- TAG -----------------------------------------------------------------------------------------------------------
tag="${datafile#eventAnalysis_}" # remove prefix
if [ "$start" -ne 0 ]; then
   tag="${tag}_s${start}"
fi
# Run process for # events (optional)
if [ "$nevent" -ne 0 ]; then
   tag=$(echo "$tag" | sed 's/_N[0-9]*//g') # remove previous Nevent
   tag="${tag}_n${nevent}"
fi
if [ -n "$comment" ]; then
   tag="${tag}_${comment}"
fi

#  ----- OUTPUT & LOGS ------------------------------------------------------------------------------------------------
highland_output="$HOME/public/output_highland/root/MC/${pkg}_${tag}.root"
log="$HOME/public/output_highland/logs/logs_${pkg}_${tag}.log"
echo "logs:             ${log}"

#  ----- FLAGS --------------------------------------------------------------------------------------------------------
# Start process from event number # (optional)
if [ "$start" -ne 0 ]; then
   flags="${flags} -s ${start}"
fi

# Run process for # events (optional)
if [ "$nevent" -ne 0 ]; then
   flags="${flags} -n ${nevent}"
fi

flags="${flags} -o ${highland_output}"

#  ----- RUN HIGHLAND -------------------------------------------------------------------------------------------------
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
echo "Running:          ${package}"
echo "Highland flags:   ${flags}"
echo "Highland output:  ${highland_output}"
echo "---    HIGHLAND ${package} SELECTION    ---" > "${log}"

${app}.exe ${flags} ${datapath} &>> ${log}
DrawUpgradeGammaHATAnalysis.exe ${highland_output} all &>> ${log}