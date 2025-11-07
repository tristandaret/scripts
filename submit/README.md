# submit/

Purpose

This directory contains helper scripts to submit analysis jobs to a cluster
scheduler (e.g., SLURM via `sbatch`). Scripts prepare flags and tags, split
work into sub-jobs, and optionally merge outputs.

Important notes

- Submission commands and sbatch options are site-specific and will not work in
  a public environment. Do not run these scripts from the public repository.
- Each script includes a header that documents its purpose and shows example
  usage for reviewers.

Files

- `hat_MC_submit.sh` - Submit particle-gun MC jobs for HAT recon (batch/local modes).
- `hat_reco_submit.sh` - Submit HAT reconstruction jobs (split/merge logic).
- `hat_reco_supersubmit.sh` - High-level dispatcher for large production runs.
- `nd280_MC_submit.sh` - Submit ND280 MC jobs.
- `nd280_reco_submit.sh` - Submit ND280 reconstruction jobs.
- `treeMaker_beam_submit.sh` - Submit TreeMaker jobs for beam recon outputs.
