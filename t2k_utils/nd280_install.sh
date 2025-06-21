#!/bin/bash

version="master"
clone=false
skip=false
cores=16
dir="."

while getopts ":v:csj:d:" opt; do
   case ${opt} in
      v )
         version=$OPTARG
         ;;
      c )
         clone=true
         ;;
      s )
         skip=true
         ;;
      j )
         cores=$OPTARG
         ;;
      d)
         dir=$OPTARG
         ;;
      \? )
         echo "Invalid option: -$opt" 1>&2
         exit 1
         ;;
      : )
         echo "Invalid option: -$opt requires an argument" 1>&2
         exit 1
         ;;
   esac
done
shift $((OPTIND -1))

echo "install flags: version=$version, clone=$clone, skip=$skip, cores=$cores, dir=$dir"

dir0=$(pwd)
cd $dir

if [ "$clone" = true ]; then
   git clone https://oauth2:glpat-Sz2MfxNAKrNrjbh_nMCd@git.t2k.org/nd280/pilot/nd280SoftwarePilot.git
fi
cd nd280SoftwarePilot
./configure.sh
source nd280SoftwarePilot.profile
cd ..
source /pbs/throng/t2k/t2k_setup.sh
export CC=$(which gcc)                                                                           
export CXX=$(which g++)                                                                          
export PATH=/pbs/throng/t2k/davix/install/bin:$PATH                                                            
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/pbs/throng/t2k/davix/install/lib64/pkgconfig/                                           
export GL2PS_DIR=/pbs/throng/t2k/gl2ps/install                                                               
export LD_LIBRARY_PATH=/pbs/throng/t2k/gl2ps/install/lib:$LD_LIBRARY_PATH

if [ "$clone" = true ]; then
   nd280-install -c -j${cores} ${version}
   cp /pbs/throng/t2k/nd280Software_14.29/ROOT_6.32.02.01/cmake/CMakeLists.txt ROOT_6.32.02.02/cmake
fi

if [ "$skip" = true ]; then
   nd280-install -s -j${cores} ${version}
fi

cd $dir0