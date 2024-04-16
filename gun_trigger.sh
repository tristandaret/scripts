#!/bin/sh
#
# Generate a particle gun with vertices distributed in a box around the central
#   position.  This can generate one or more particles starting from the vertex
#   (only one vertex per event).  With one particle, this is basically just a
#   complicated script to make a simple particle gun.
#
# This takes a bunch of parameters:
#
# sim-particle-gun.sh <options> [baseline] [count] \
#                       [particle] [energy] [dx] [dy] [dz] \
#                       { [particle] [energy] [dx] [dy] [dz] } \
#
#     baseline -- The name of the macro describing the geometry (typically
#           "baseline-2022" for the upgrade and "baseline" for everything
#           else).
#
#     count -- The number of events to generate.
#
#     particle -- The G4 name for a particle to generate (e.g. mu+ mu- e+ e-
#           pi+ pi- pi0 gamma proton neutron kaon+ kaon-)
#
#     energy -- The kinetic energy of the particle in MeV.  A range of
#           energy can be specified as "low-high".
#
#     dx dy dz -- The direction for the particle.
#
#  The last five arguments can be repeated ad nauseum.
#
#  OPTIONS:
#
#    -p -- Set the central position (e.g. -p "0 0 0 cm")
#             Important approximately central positions --
#                                 SFG or P0D: "0 0 -230 cm"
#                                    top HAT: "0 50 -230 cm"
#                                    bot HAT: "0 -50 -230 cm"
#                                       FGD1: "0 0 20 cm"
#                                       FGD2: "0 0 165 cm"
#    -s -- DO NOT set the seed from the time.
#    -n -- Set the name field for the output file
#    -x -- Set the half x for a box around the position (e.g. -x "5 cm")
#    -y -- Set the half y for a box around the position (e.g. -y "5 cm")
#    -z -- Set the half z for a box around the position (e.g. -z "5 cm")
#
# EXAMPLE 2
#
# Make 10 fake QE like events (mu- and proton).  The muon is along the
# Z axis, and the proton is along the X axis.  The muon energy is
# between 400 MeV and 700 MeV.
#
#   sim-particle-gun.sh baseline-2022 10 mu- 400-700 0 0 1 proton 200 1 0 0
#

if ! which ND280GEANT4SIM.exe; then
    echo
    echo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    echo Cannot find ND280GEANT4SIM.exe.  Did you forget to run setup?
    echo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    exit 1
fi

# Set a default position in the P0D or superFGD (yes, I'm biased).
APPLY="no"
POSITION="0 0 -230 cm"
SEED_OPTION="-s"
# SUFFIX=""
HALFX="25 cm"
HALFY="5 cm"
HALFZ="30 cm"

# A variable to build the file name.
NAME=""

# Handle any input arguments
TEMP=$(getopt -o 'ap:sS:x:y:z:n:' -n "$0" -- "$@")
if [ $? -ne 0 ]; then
    echo "Error ..."
    exit 1
fi
eval set -- "$TEMP"
unset TEMP
while true; do
    case "$1" in
	'-a')
	    APPLY="yes"
	    shift
	    continue;;
	'-p')
	    POSITION="$2"
	    shift
	    shift
	    continue;;
        '-s')
            SEED_OPTION=""
            shift
            continue;;
	'-S')
	    SUFFIX="_$2"
	    shift
	    shift
	    continue;;
	'-x')
	    HALFX="$2"
	    shift
	    shift
	    continue;;
	'-y')
	    HALFY="$2"
	    shift
	    shift
	    continue;;
	'-z')
	    HALFZ="$2"
	    shift
	    shift
	    continue;;
	'-n')
	    NAME="$2"
	    shift
        shift
	    continue;;
	'--')
	    shift
	    break;
    esac
done


BASELINE=$1
shift
if [ "${BASELINE}"x = x ] ; then
    BASELINE=baseline-2023;
fi

COUNT=$1
shift
if [ "${COUNT}"x = x ] ; then
    COUNT=10;
fi

echo "#   Generate '$COUNT' events"
echo "#   Geometry '$BASELINE'"
echo "#   Central Position '$POSITION'"
echo "#   Half X '$HALFX'"
echo "#   Half Y '$HALFY'"
echo "#   Half Z '$HALFZ'"

# Make a temporary macro file in the local directory.
MACRO=`TMPDIR="." mktemp -t nd280Geant4Sim.XXXXXXXXXX` || exit 1

# Start building the macro
cat >> $MACRO <<EOF
/t2k/control ${BASELINE} 1.0
/t2k/update
/gps/source/clear
/gps/source/multiplevertex true
EOF

# Add the particles to the particle bomb.
SRC=0
while [ "x$1" != x ]; do
    PARTICLE=$1
    shift

    KE=$1
    shift

    # DX=$1
    # shift

    # DY=$1
    # shift

    # DZ=$1
    # shift

    PHI=$1
    shift

    DPHI=$1
    shift

    THETA=$1
    shift

    DTHETA=$1
    shift

    # echo "#>> '${PARTICLE}' @ '${KE}' MeV KE -> ('${DX}','${DY}','${DZ}')"
    echo "#>> '${PARTICLE}' @ '${KE}' MeV KE -> ('${PHI}±${DPHI}','${THETA}±${DTHETA}')"
    # NAME="${NAME}_${PARTICLE}_${KE}MeV"

    SRC=$(($SRC + 1))

    # Define the source number, particle type, and direction.
    cat >> $MACRO <<EOF
/gps/source/add $SRC
/gps/particle ${PARTICLE}
# /gps/direction ${DX} ${DY} ${DZ}
/gps/ang/mintheta ${PHI}-${DPHI} deg #theta and phi are inverted in ND280 geometry
/gps/ang/maxtheta ${PHI}+${DPHI} deg
/gps/ang/minphi ${THETA}-${DTHETA} deg
/gps/ang/maxphi ${THETA}+${DTHETA} deg
EOF

    # Parse the KE to see if there is a range.
    KE1=""
    KE2=""
    for e in $(echo ${KE} | sed 's/-/ /'); do
        if [ "${KE1}x" = "x" ]; then
            KE1=${e}
        elif [ "${KE2}x" = "x" ]; then
            KE2=${e}
        fi
    done

    if [ "${KE2}x" = "x" ]; then
       cat >> $MACRO <<EOF
/gps/ene/type Mono
/gps/ene/mono ${KE1} MeV
EOF
    else
       cat >> $MACRO <<EOF
/gps/ene/type Lin
/gps/ene/gradient 0.0
/gps/ene/intercept 1.0
/gps/ene/min ${KE1} MeV
/gps/ene/max ${KE2} MeV
EOF
    fi

    # For the first particle, a real vertex position must be generated.
    if [ "$SRC" = "1" ]; then
        cat >> $MACRO <<EOF
/gps/position ${POSITION}
/gps/pos/type Volume
/gps/pos/shape Para
/gps/pos/halfx ${HALFX}
/gps/pos/halfy ${HALFY}
/gps/pos/halfz ${HALFZ}
EOF
    fi
done

cat >> $MACRO <<EOF
/generator/add
EOF

# copy the first vertex position to all of the other particles.
while [ ${SRC} != "1" ]; do
    SRC=$(($SRC - 1))
    cat >> $MACRO <<EOF
/generator/copy 0 ${SRC}
EOF
done

# And run the beam.
cat >> $MACRO <<EOF
/run/beamOn ${COUNT}
EOF

# OUTPUT=gun${NAME}${SUFFIX}_g4mc
# echo "#   Output file '${OUTPUT}.root'"
echo "#   Output file '${NAME}'"

if [ ${APPLY} = "no" ]; then
    echo "ADD '-a' TO PROCESS EVENTS"
    echo "   See the macro in $MACRO which must be removed by hand."
    exit 1
fi

# if [ -f "${OUTPUT}.root" ]; then
    # echo "Must remove '${OUTPUT}.root' by hand"
if [ -f "${NAME}" ]; then
    echo "Must remove '${NAME}' by hand"
    rm $MACRO
    exit 1
fi
NAME="${NAME%.root}"
echo "SEED_OPTION: ${SEED_OPTION}"
echo "NAME: ${NAME}"
echo "MACRO: ${MACRO}"
# ND280GEANT4SIM.exe ${SEED_OPTION} -o $OUTPUT $MACRO
ND280GEANT4SIM.exe ${SEED_OPTION} -o $NAME $MACRO

rm $MACRO
