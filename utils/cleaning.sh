#!/bin/bash

plot=false
log=true
gun=false
drs=false
hat=false
tree=false
calib=false
recon=false
anal=false
highland=false
all=false

while [[ "$#" -gt 0 ]]; do
   case $1 in
      --nolog) log=false ;;
      --plot) plot=true ;;
      --gun) gun=true ;;
      --drs) drs=true ;;
      --hat) hat=true ;;
      --tree) tree=true ;;
      --calib) calib=true ;;
      --recon) recon=true ;;
      --anal) anal=true ;;
      --highland) highland=true ;;
      --all) all=true ;;
   esac
   shift
done

rm -f $HOME/slurm-*.out
rm -f $HOME/nd280Geant4Sim.*
rm -f $HOME/hatRecon/${HATRECONCONFIG}/core*

if [ "$plot" = true ]; then
   rm -f $HOME/plots/*.pdf
fi

if [ "$log" = true ]; then
   rm -f $HOME/public/output_nd280/logs/*.log
   rm -f $HOME/public/output_hatRecon/logs/*.log
   rm -f $HOME/public/output_highland/logs/*.log
fi

if [ "$gun" = true ] || [ "$all" = true ]; then
   rm -f $HOME/public/data/MC/1_PG_*.root
fi

if [ "$drs" = true ] || [ "$all" = true ]; then
   rm -f $HOME/public/data/MC/*DRS_*.root
fi

if [ "$hat" = true ] || [ "$all" = true ]; then
   rm -f $HOME/public/output_hatRecon/root/*/*hatRecon_*.root
fi

if [ "$calib" = true ] || [ "$all" = true ]; then
   rm -f $HOME/public/output_nd280/root/*/3_eventCalib_*.root
fi

if [ "$recon" = true ] || [ "$all" = true ]; then
   rm -f $HOME/public/output_nd280/root/*/4_eventRecon_*.root
fi

if [ "$anal" = true ] || [ "$all" = true ]; then
   rm -f $HOME/public/output_nd280/root/*/*eventAnalysis_*.root
fi

if [ "$highland" = true ] || [ "$all" = true ]; then
   rm -f $HOME/public/output_highland/root/*/*.root
fi

if [ "$tree" = true ] || [ "$all" = true ]; then
   rm -f $HOME/public/output_hatRecon/root/*/*TreeMaker_*.root
fi