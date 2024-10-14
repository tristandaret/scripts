#!/bin/bash

type=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --type)
            if [[ "$2" == "reco" || "$2" == "simu" ]]; then
                type="$2"
                shift
            else
                echo "Invalid type: $2. Use 'reco' or 'simu'."
                exit 1
            fi
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

if [ -z "$type" ]; then
    echo "Type is required. Use --type with 'reco' or 'simu'."
    exit 1
fi

if [ "$type" == "reco" ]; then
    files=(
        "MC_mu-_600MeV_x-50_y-91_z-180_phi0_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-90_z-179_phi-10_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-85_z-180_phi-20_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-74_z-180_phi-30_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-64_z-180_phi-40_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-60_z-180_phi-45_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-55_z-180_phi-50_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-50_z-180_phi-60_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-43_z-180_phi-70_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-40_z-180_phi-80_theta0_N5000"
        "MC_mu-_600MeV_x-50_y-39_z-180_phi-90_theta0_N5000"
    )
    make_hatRecon
    for file in "${files[@]}"; do
        ./scripts/analysis.sh -d "${file}" -N 5000 -n 200 --comment "_DDm5" --rm
    done

elif [ "$type" == "simu" ]; then
    drifts=(-98 -88 -78 -68 -58 -48 -38 -28 -18 -8 0)
    for drift in "${drifts[@]}"; do
        ./scripts/mc.sh -N 5000 -n 100 -X "${drift}" --rm
    done
fi