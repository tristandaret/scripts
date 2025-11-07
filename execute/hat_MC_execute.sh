#!/bin/bash
#
# hat_MC_execute.sh
# Purpose: Orchestrates the Monte Carlo (MC) workflow for "hat" reconstruction.
#          Sequence: particle gun -> detector response simulation -> event calibration
#          -> hat reconstruction -> TreeMaker. This header documents flags, inputs,
#          and outputs for readability. The script body below is kept for context.
#
# WARNING (Documentation-only):
#   These scripts are included for documentation and review. They are NOT intended
#   to be executed from the public repository. Running them without the original
#   software stack, data, and permissions may be unsafe or ineffective.
#
# Usage example (for reading / documentation only):
#   ./hat_MC_execute.sh -N 100 -p mu- -e 600 --tags demo
#
# Inputs:
#   - Command-line flags parsed in the script (examples): -N, -p, -e, -x, -y, -z,
#     --dx, --dy, --dz, --phi, --dphi, --theta, --dtheta, --tags, -i, --rm
#   - Environment variables and binaries expected in the original environment
#     (e.g., DETRESPONSESIM.exe, RunEventCalib.exe, hatRecon binaries under $HOME).
#
# Outputs (as used in this script):
#   - ROOT files written under $HOME/public/data/MC and $HOME/public/output_hatRecon
#   - A log file under $HOME/public/output_hatRecon/logs
#
# Notes:
#   - This header was added to make the repository understandable when viewed.
#   - Do not rely on the paths or binaries shown here; they point to the original
#     working environment and are preserved for reference only.

### Default configuration: focused horizontal beam of 600 MeV muons
# Gun type
N=100
particle="mu-"
energy="600"
# Position
X=-50
Y=-75
Z=-375
DX=0
DY=0
DZ=0
# Direction
phi=0
dphi=0
theta=0
dtheta=0

# Parallelization 
index=-999

# Tags
tags=""
rm_flag=false


while :; do
    case $1 in
        -N)
            if [ "$2" ]; then
                N=$2
                shift
            fi
            ;;
        -p)
            if [ "$2" ]; then
                particle=$2
                shift
            fi
            ;;
        -e)
            if [ "$2" ]; then
                energy=$2
                shift
            fi
            ;;
        -x)
            if [ "$2" ]; then
                X=$2
                shift
            fi
            ;;
        -y)
            if [ "$2" ]; then
                Y=$2
                shift
            fi
            ;;
        -z)
            if [ "$2" ]; then
                Z=$2
                shift
            fi
            ;;
        --dx)
            if [ "$2" ]; then
                DX=$2
                shift
            fi
            ;;
        --dy)
            if [ "$2" ]; then
                DY=$2
                shift
            fi
            ;;
        --dz)
            if [ "$2" ]; then
                DZ=$2
                shift
            fi
            ;;
        --phi)
            if [ "$2" ]; then
                phi=$2
                shift
            fi
            ;;
        --dphi)
            if [ "$2" ]; then
                dphi=$2
                shift
            fi
            ;;
        --theta)
            if [ "$2" ]; then
                theta=$2
                shift
            fi
            ;;
        --dtheta)
            if [ "$2" ]; then
                dtheta=$2
                shift
            fi
            ;;
        --tags)
            if [ "$2" ]; then
                tags=$2
                shift
            fi
            ;;
        -i)
            if [ "$2" ]; then
                index=$2
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
        *) # No more options
            break
    esac
    shift
done

XYZ="${X} ${Y} ${Z}"
log="$HOME/public/output_hatRecon/logs/logs_${tags}.log"

# Particle gun
gun_output="$HOME/public/data/MC/1_gun_${tags}.root"
gun_flags="-b baseline-2024 -N ${N} -x ${X} -y ${Y} -z ${Z} --dx ${DX} --dy ${DY} --dz ${DZ} -n ${gun_output} -- ${particle} ${energy} ${phi} ${dphi} ${theta} ${dtheta}"
echo "logs:             ${log}"
echo "gun_flags:        ${gun_flags}"
echo "gun_output:       ${gun_output}"
echo "--- STEP 1:  PARTICLE GUN  ---" > "${log}"
time $HOME/scripts/execute/particle_gun.sh ${gun_flags} &>> "${log}"

# DetResponseSim
DetResSim_output="$HOME/public/data/MC/2_DRS_${tags}.root"
echo "DetResSim_output: ${DetResSim_output}"
echo -e "\n--- STEP 2: DETRESPONSESIM ---" >> "${log}"
time DETRESPONSESIM.exe ${gun_output} -o ${DetResSim_output} -R -O hat-only &>> ${log}

# EventCalib
EventCalib_output="$HOME/public/output_hatRecon/root/MC/3_EventCalib_${tags}.root"
echo "EventCalib_output: ${EventCalib_output}"
echo -e "\n--- STEP 3:   EVENTCALIB   ---" >> "${log}"
time RunEventCalib.exe ${DetResSim_output} -o ${EventCalib_output} -R &>> ${log}

# hatRecon
hatRecon_output="$HOME/public/output_hatRecon/root/MC/4_hatRecon_${tags}.root"
echo "hatRecon_output:  ${hatRecon_output}"
echo -e "\n--- STEP 4:    HATRECON    ---" >> "${log}"
time $HOME/hatRecon/`nd280-system`/bin/HATRECON.exe ${EventCalib_output} -o ${hatRecon_output} -R &>> ${log}

# TreeMaker
TreeMaker_output="$HOME/public/output_hatRecon/root/MC/TreeMaker_${tags}.root"
echo "TreeMaker_output: ${TreeMaker_output}"
echo -e "\n--- STEP 5:    TREEMAKER   ---" >> "${log}"
time $HOME/hatRecon/`nd280-system`/bin/HATRECONTREEMAKER.exe ${hatRecon_output} -O outfile=${TreeMaker_output} -R &>> ${log}

if [[ "$rm_flag" = true ]]; then
    rm ${gun_output} ${EventCalib_output} #${hatRecon_output}
fi