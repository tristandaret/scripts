#!/bin/bash

reco=""
simu=""
comment=""
run=""
N=5000
n=100

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -N)
            if [ "$2" ]; then
                N=$2
                shift
            fi
            ;;
        -n)
            if [ "$2" ]; then
                n=$2
                shift
            fi
            ;;
        --reco)
            if [ "$2" ]; then
                reco=$2
                shift
            fi
            ;;
        --simu)
            if [ "$2" ]; then
                simu=$2
                shift
            fi
            ;;
        --comment)
            if [ "$2" ]; then
                comment=$2
                shift
            fi
            ;;
        --run)
            if [ "$2" ]; then
                run=$2
                shift
            fi
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

if [ "$reco" != "" ]; then
    if [ "$reco" == "phi" ]; then
        files=(
            "MC_mu-_600MeV_x50_y-91_z-180_phi0_theta0_N5000"
            "MC_mu-_600MeV_x50_y-90_z-180_phi-10_theta0_N5000"
            "MC_mu-_600MeV_x50_y-85_z-180_phi-20_theta0_N5000"
            "MC_mu-_600MeV_x50_y-74_z-180_phi-30_theta0_N5000"
            "MC_mu-_600MeV_x50_y-64_z-180_phi-40_theta0_N5000"
            "MC_mu-_600MeV_x50_y-60_z-180_phi-45_theta0_N5000"
            "MC_mu-_600MeV_x50_y-55_z-180_phi-50_theta0_N5000"
            "MC_mu-_600MeV_x50_y-50_z-180_phi-60_theta0_N5000"
            "MC_mu-_600MeV_x50_y-43_z-180_phi-70_theta0_N5000"
            "MC_mu-_600MeV_x50_y-40_z-180_phi-80_theta0_N5000"
            "MC_mu-_600MeV_x50_y-39_z-180_phi-90_theta0_N5000"
        )
    elif [ "$reco" == "drift" ]; then
        files=(
            "MC_mu-_600MeV_x1_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x8_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x18_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x28_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x38_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x48_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x58_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x68_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x78_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x88_y-40_z-200_phi-90_theta0_N5000"
            "MC_mu-_600MeV_x97_y-40_z-200_phi-90_theta0_N5000"
        )
    elif [ "$reco" == "dog1" ]; then
        if [ "$run" == "920" ]; then
            for i in {0..8}; do
                index=$(printf "%04d" $i)
                files+=("dog1_00000920_${index}")
            done
        elif [ "$run" == "1022" ]; then
            for i in {0..45}; do
                index=$(printf "%04d" $i)
                files+=("dog1_00001022_${index}")
            done
        fi
    fi
    for file in "${files[@]}"; do
        ./scripts/submit_analysis.sh -d "${file}" -N ${N} -n ${n} --comment "${comment}" --rm
    done
fi

if [ "$simu" != "" ]; then
    if [ "$simu" == "phi" ]; then
        phi=(-90 -80 -70 -60 -50 -45 -40 -30 -20 -10 0)
        Y=(-39 -40 -43 -50 -55 -60 -64 -74 -85 -90 -91)
        for i in "${!phi[@]}"; do
            ./scripts/mc.sh -N ${N} -n 200 --phi "${phi[$i]}" -X "50" -Y "${Y[$i]}" --rm
        done
    elif [ "$simu" == "drift" ]; then
        values=(97 88 78 68 58 48 38 28 18 8 1)
        for val in "${values[@]}"; do
            ./scripts/mc.sh -N ${N} -n ${n} --X "${val}" --phi "-90" --rm
        done
    fi
fi