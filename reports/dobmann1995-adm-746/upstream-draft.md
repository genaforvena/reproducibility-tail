# Draft (not sent): TOMS 746 Doc/Makefile does not parse

Reviewer note: a person reviews the tone before anything is sent.

- The `Doc/Makefile` in the netlib archive `746.gz` has the `all:` target continued with a literal double backslash (`\\`) at the end of each line. GNU make reports `missing separator` at that line, so no target in the Makefile can run.
- The Makefile sets `FC = epcf90` and `TIMER` to a path on an old NFS host. Neither exists outside the original site.
- The shar also places the Makefile under `Doc/`, not under `Fortran77/Dp/Drivers/` where its rules expect `Examples/`, `admfor.f` and `adm.f`.
- A build that worked here: gfortran 16 with `-O2 -std=legacy`, the Makefile's tp1 commands run by hand. The tp1 generated derivative error printed 0.451D-03, matching `Results/tp1.res`.
- Suggested fix: single backslashes in `all:`, a configurable `FC`, and the Makefile moved beside the sources.
