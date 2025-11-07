#!/bin/bash
#
# highland_install.sh
# Purpose: Automate Highland installation steps used in the original analysis
#          environment. Kept for documentation to show how Highland was set up.
#
# WARNING (Documentation-only):
#   This script runs installers and manipulates user directories. It is included
#   only for documentation; do NOT execute it from the public repository.
#
# Example (documentation only):
#   bash highland_install.sh

setup_highland
cd $HOME/public/Highland2_8v3
highland-install -s -r -j10 -p prod8_V03 4.14