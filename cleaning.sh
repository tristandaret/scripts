#!/bin/bash

gun=false
res=false
hat=false
tree=false
all=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --gun) gun=true ;;
        --res) res=true ;;
        --hat) hat=true ;;
        --tree) tree=true ;;
        --all) all=true ;;
    esac
    shift
done

rm -f $HOME/slurm-*.out
rm -f $HOME/plots/*.pdf
rm -f $HOME/public/Output_log/*.log
rm -f $HOME/hatRecon/${HATRECONCONFIG}/nd280Geant4Sim.*
rm -f $HOME/hatRecon/${HATRECONCONFIG}/core*

if [ "$gun" = true ] || [ "$all" = true ]; then
    rm -f $HOME/public/Output_root/MC/1_gun_*.root
fi

if [ "$res" = true ] || [ "$all" = true ]; then
    rm -f $HOME/public/Output_root/MC/2_DetResSim_*.root
fi

if [ "$hat" = true ] || [ "$all" = true ]; then
    rm -f $HOME/public/Output_root/MC/3_HATRecon_*.root
fi

if [ "$tree" = true ] || [ "$all" = true ]; then
    rm -f $HOME/public/Output_root/MC/*TreeMaker_*.root
fi