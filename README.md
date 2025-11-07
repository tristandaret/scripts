# scripts

This repository is a collection of site-specific shell wrappers and helper
scripts used during an analysis workflow. The scripts show common steps such as
particle-gun generation, detector simulation, reconstruction and tree-making, as
well as small utilities for installation, submission and housekeeping.

IMPORTANT: The files in this repository are documented for review and learning
purposes. They reference cluster schedulers, experiment binaries and local
paths. They are not intended to be executed from this public repository.

Top-level directories

- `execute/` - Execution wrappers that run a sequence of analysis steps.
- `submit/`  - Batch submission helpers that prepare and submit jobs.
- `t2k_utils/` - Installation and utility helpers used to setup the experiment
  environment and merge outputs.
- `utils/`   - Small utilities for housekeeping, file merging, renaming, and
  job management.

See the README.md file inside each directory for a short description of the
files it contains and what they are for.
