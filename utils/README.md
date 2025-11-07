# utils/

Purpose

Small helper scripts for housekeeping, file manipulation and basic job
management used alongside the analysis workflows.

Important notes

- Some utilities delete files or control scheduler jobs. They are included for
  documentation and must not be executed in the public repository.
- Each script contains a header explaining its purpose and a strong warning not
  to run it here.

Files

- `cleaning.sh` - Remove generated logs and intermediate files (destructive).
- `hadd.sh` - Example wrapper showing how `hadd` was used to merge ROOT files.
- `rename.sh` - Rename files by replacing substrings in filenames.
- `scancel.sh` - Cancel a range of scheduler jobs (uses `scancel`).
- `seff.sh` - Query job efficiency (`seff`) for a range of job IDs.
