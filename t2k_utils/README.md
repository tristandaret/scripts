# t2k_utils/

Purpose

This directory contains installation helpers and small utilities used to setup
and operate the experiment software stack (ND280, Highland, etc.) as well as a
small tree-merging helper.

Important notes

- These scripts install software, call remote services and manipulate system
  paths. They are included as documentation and must NOT be executed from the
  public repository.

Files

- `highland_install.sh` - Steps to install Highland (documented).
- `nd280_install.sh` - Install and configure ND280 software (documented).
- `submit_nd280_install.sh` - Submit ND280 installation on a batch system.
- `tree_merger.sh` - Merge ROOT files (wraps `hadd`) and remove intermediates.
