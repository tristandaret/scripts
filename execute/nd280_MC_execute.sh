#!/bin/bash

### Default configuration: focused horizontal beam of 600 MeV muons
# Gun type
N=100
particle="gamma"
energy="600"
# Position
X=-50
Y=-75
Z=-350
DX=0
DY=0
DZ=0
# Direction
phi=0
dphi=0
theta=0
dtheta=0

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

logs="$HOME/public/output_nd280/logs/logs_${tags}.log"

# Particle gun
gun_output="$HOME/public/data/MC/1_PG_${tags}.root"
gun_flags="-b baseline-2024 -N ${N} -x ${X} -y ${Y} -z ${Z} --dx ${DX} --dy ${DY} --dz ${DZ} -n ${gun_output} -- ${particle} ${energy} ${phi} ${dphi} ${theta} ${dtheta}"
echo "logs:                  ${logs}"
echo "gun flags:             ${gun_flags}"
echo "gun output:            ${gun_output}"
echo "--- STEP 1: PARTICLE GUN  ---" > "${logs}"
time $HOME/scripts/execute/particle_gun.sh ${gun_flags} &>> "${logs}"

# DetResponseSim
DetResSim_output="$HOME/public/data/MC/2_DRS_${tags}.root"
echo "DetResponseSim output: ${DetResSim_output}"
echo -e "\n--- STEP 2: DETRESPONSESIM ---" >> "${logs}"
time DETRESPONSESIM.exe ${gun_output} -o ${DetResSim_output} -R &>> ${logs}

# EventCalib
eventCalib_output="$HOME/public/output_nd280/root/MC/3_eventCalib_${tags}.root"
echo "eventCalib output:     ${eventCalib_output}"
echo -e "\n--- STEP 3: EVENTCALIB    ---" >> "${logs}"
time RunEventCalib.exe ${DetResSim_output} -o ${eventCalib_output} -R &>> ${logs}

# EventRecon
eventRecon_output="$HOME/public/output_nd280/root/MC/4_eventRecon_${tags}.root"
echo "eventRecon output:     ${eventRecon_output}"
echo -e "\n--- STEP 4: EVENTRECON   ---" >> "${logs}"
time RunEventRecon.exe ${eventCalib_output} -o ${eventRecon_output} -R &>> ${logs}

# EventAnalysis
eventAnalysis_output="$HOME/public/output_nd280/root/MC/5_eventAnalysis_${tags}.root"
echo "eventAnalysis output:  ${eventAnalysis_output}"
echo -e "\n--- STEP 5: EVENTANALYSIS ---" >> "${logs}"
time RunEventAnalysis.exe ${eventRecon_output} -o ${eventAnalysis_output} -R &>> ${logs}

if [[ "$rm_flag" = true ]]; then
    rm ${gun_output} ${eventCalib_output} ${eventRecon_output}
fi