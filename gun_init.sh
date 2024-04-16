#!/bin/bash
cd ~/hatRecon/`nd280-system`

### Default configuration: focused horizontal beam of 600 MeV muonsg
# Gun type
N=10
particle="mu-"
energy="600"
# Position
X=50
Y=-75
Z=-300
DX=1
DY=1
DZ=1
# Direction
U=0
V=0
W=1

# Parallelization 
index=-999

# Tags
tag=""
label=""
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
        -u)
            if [ "$2" ]; then
                U=$2
                shift
            fi
            ;;
        -v)
            if [ "$2" ]; then
                V=$2
                shift
            fi
            ;;
        -w)
            if [ "$2" ]; then
                W=$2
                shift
            fi
            ;;
        -t)
            if [ "$2" ]; then
                tag=$2
                shift
            fi
            ;;
        -l)
            if [ "$2" ]; then
                label=$2
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
echo "gun_init flags:   -N ${N} ${particle} ${energy} -x ${X} -y ${Y} -z ${Z} --dx ${DX} --dy ${DY} --dz ${DZ} -u ${U} -v ${V} -w ${W}-l ${label} -i ${index} --rm ${rm_flag} -R"

XYZ="${X} ${Y} ${Z}"
UVW="${U} ${V} ${W}"

log="/sps/t2k/tdaret/public/Output_log/logs_${label}.log"

# Particle gun
gun_output="/sps/t2k/tdaret/public/Output_root/MC/1_gun_${label}.root"
gun_flags=(-p "${XYZ}" "${N}" -a -x "${DX} cm" -y "${DY} cm" -z "${DZ} cm" -n ${gun_output} -- "${particle}" "${energy}" "${U}" "${V}" "${W}")
echo "logs:             ${log}"
echo "gun_flags:        ${gun_flags[@]}"
echo "gun_output:       ${gun_output}"
echo "--- STEP 1:  PARTICLE GUN  ---" > "${log}"
~/scripts/gun_trigger.sh baseline-2023 "${gun_flags[@]}" &>> "${log}"

# DetResponseSim
DetResSim_output="/sps/t2k/tdaret/public/Output_root/MC/2_DetResSim_${label}.root"
echo "DetResSim_output: ${DetResSim_output}"
echo -e "\n--- STEP 2: DETRESPONSESIM ---" >> "${log}"
DETRESPONSESIM.exe -o ${DetResSim_output} ${gun_output} -R &>> ${log}

# HATRecon
HATRecon_output="/sps/t2k/tdaret/public/Output_root/MC/3_HATRecon_${label}.root"
echo "HATRecon_output:  ${HATRecon_output}"
echo -e "\n--- STEP 3:    HATRECON    ---" >> "${log}"
./bin/HATRECON.exe ${DetResSim_output} -o ${HATRecon_output} -R &>> ${log}

# TreeMaker
TreeMaker_output="/sps/t2k/tdaret/public/Output_root/TreeMaker_${label}.root"
echo "TreeMaker_output: ${TreeMaker_output}"
echo -e "\n--- STEP 4:    TREEMAKER   ---" >> "${log}"
./bin/HATRECONTREEMAKER.exe -O outfile=${TreeMaker_output} ${HATRecon_output} -R &>> ${log}

if $rm_flag; then
    rm ${HATRecon_output} ${DetResSim_output} ${gun_output} ${log}
fi