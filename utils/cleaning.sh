#!/bin/bash

gun=false
res=false
hat=false
tree=false
highland=false
all=false
log=true

while [[ "$#" -gt 0 ]]; do
   case $1 in
      --gun) gun=true ;;
      --res) res=true ;;
      --hat) hat=true ;;
      --tree) tree=true ;;
      --highland) highland=true ;;
      --all) all=true ;;
      --nolog) log=false ;;
   esac
   shift
done

rm -f $HOME/slurm-*.out
rm -f $HOME/plots/*.pdf
rm -f $HOME/nd280Geant4Sim.*
rm -f $HOME/hatRecon/${HATRECONCONFIG}/core*

if [ "$log" = true ]; then
    rm -f $HOME/public/Output_log/*.log
fi

if [ "$gun" = true ] || [ "$all" = true ]; then
    rm -f $HOME/public/Output_root/*/1_gun_*.root
fi

if [ "$res" = true ] || [ "$all" = true ]; then
    rm -f $HOME/public/Output_root/*/2_DetResSim_*.root
fi

if [ "$hat" = true ] || [ "$all" = true ]; then
    rm -f $HOME/public/Output_root/*/3_HATRecon_*.root
fi

if [ "$highland" = true ] || [ "$all" = true ]; then
    rm -f $HOME/public/Output_highland/highland_*.root
fi

if [ "$tree" = true ] || [ "$all" = true ]; then
    rm -f $HOME/public/Output_root/*/*TreeMaker_*.root
fi