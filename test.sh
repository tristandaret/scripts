#!/bin/bash
cd ~/hatRecon/`nd280-system`
cd plots
rm -f *
cd ..

N=100
particle="mu-"
energy="580-620"

X=50
Y=-120
Z=-250
DX=1
DY=1
DZ=50

U=0
V=1
W=1
tag=""

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
UVW="${U} ${V} ${W}"
label="${particle}_${energy}MeV_${X}pm${DX}_${Y}pm${DY}_${Z}pm${DZ}_${U}${V}${W}_N${N}${tag}"

echo "${label}"