#!/bin/bash

#######################################################################################################################
# ND280 Software and hatRecon
setup_nd280() {
   if [ -n "${1}" ]; then
      version=${1}
   else
      version=14.29
   fi
   echo "SOURCING: ND280Software"
   source /pbs/throng/t2k/t2k_setup.sh
   pbs_nd280 ${version}
   echo "SOURCING: My hatRecon"
   source $HOME/hatRecon/bin/setup.sh
}

setup_my_nd280() {
   if [ -n "${1}" ]; then
      version=${1}
   else
      version=14.29
   fi
   echo "SOURCING: my ND280Software"
   echo -e "\nSOURCING: SoftwarePilot"
   source /sps/t2k/tdaret/nd280_${version}/nd280SoftwarePilot/nd280SoftwarePilot.profile
   export CC=$(which gcc)
   export CXX=$(which g++)
   export PATH=/pbs/throng/t2k/davix/install/bin:$PATH
   export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/pbs/throng/t2k/davix/install/lib64/pkgconfig/
   export GL2PS_DIR=/pbs/throng/t2k/gl2ps/install
   export LD_LIBRARY_PATH=/pbs/throng/t2k/gl2ps/install/lib:$LD_LIBRARY_PATH
   echo "  --> ND280 Pilot Version : ${version}"
   echo -e "\nSOURCING: SoftwareMaster"
   source /sps/t2k/tdaret/nd280_${version}/nd280SoftwareMaster_${version}/bin/setup.sh
   echo -e "\nSOURCING: SoftwareControl"
   source /sps/t2k/tdaret/nd280_${version}/nd280SoftwareControl_*/bin/setup.sh
   echo -e "\nSOURCING: My hatRecon"
   source $HOME/hatRecon/bin/setup.sh
}

cmake_hatRecon() {
   source $HOME/hatRecon/bin/setup.sh
   (cd $HOME/hatRecon/$(nd280-system)
   cmake ../cmake/
   make -j16)
}

make_hatRecon() {
   (cd $HOME/hatRecon/$(nd280-system)
   make -j16)
}



#######################################################################################################################
export IS_HIGHLAND_SETUP=0
setup_highland() {
   source /pbs/throng/t2k/t2k_setup.sh
   source $HOME/highland/nd280SoftwarePilot/nd280SoftwarePilot.profile
   source $HOME/highland/highland2SoftwarePilot/highland2SoftwarePilot.profile
   source $HOME/highland/highland2Master_4.14/bin/setup.sh
   source $HOME/highland/upgradeNueCCAnalysis/bin/setup.sh
   source $HOME/highland/upgradeGammaAnalysis/bin/setup.sh
   export CC=$(which gcc)
   export CXX=$(which g++)
   export PATH=/pbs/throng/t2k/davix/install/bin:$PATH
   export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/pbs/throng/t2k/davix/install/lib64/pkgconfig/
   export GL2PS_DIR=/pbs/throng/t2k/gl2ps/install
   export LD_LIBRARY_PATH=/pbs/throng/t2k/gl2ps/install/lib:$LD_LIBRARY_PATH
   export IS_HIGHLAND_SETUP=1
}

make_highland() {
  highland-install -s -r -j10 -p prod8_V03 4.14
}


#######################################################################################################################
# Grid
source_grid() {
   source /cvmfs/dirac.egi.eu/dirac/bashrc_gridpp
   export PATH=/pbs/home/t/tdaret/.local/bin:${PATH}
   dirac-proxy-init -g t2k.org_user -M
}
