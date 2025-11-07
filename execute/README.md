# execute/

Purpose

The `execute/` directory contains wrappers that orchestrate analysis steps for
production and testing. Typical flows include generating a particle gun, running
detector response simulation, event calibration and reconstruction and finally
producing analysis trees.

Important notes

- These scripts assume a specific experiment software stack (ND280, HAT, Highland)
  and local $HOME paths. They are provided for documentation and should not be
  executed in the public repository.
- Each script contains a header that documents its purpose, flags used and a
  short example invocation.

Files

- `hat_MC_execute.sh` - Full MC pipeline for the HAT recon workflow.
- `hat_reco_execute.sh` - Run HAT reconstruction on a provided input file.
- `highland_execute.sh` - Wrapper to run Highland analysis packages.
- `nd280_MC_execute.sh` - ND280 MC workflow (particle gun -> sim -> recon).
- `nd280_reco_execute.sh` - ND280 reconstruction pipeline wrapper.
- `particle_gun.sh` - Build GPS macro files and run ND280GEANT4SIM (documented).
- `treeMaker_beam_execute.sh` - Run TreeMaker on a single beam HAT recon file.
