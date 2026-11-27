# cabay1997-vecpade-766: TOMS 766 (Pade'-Hermite and simultaneous Pade' approximants), driver1 entry

Claim: entry (row 2, column 3) of the z**1 coefficient matrix of Pade'-Hermite System S printed by driver1 (multiplied by 37), with the shipped RES1 value -131, tol_abs 0.5. Registered in the queue entry; not edited.

Verdict: reproduced. Basis: patched (build-only).

Paper value: not used (article not read, paywalled). The claim rests on the shipped RES1.

Our value: -131.0 in pass 1 and in pass 2 (both from clean build directories, same commands).

Original attempt (G1): the readme build set (driver1.f90, vector_pade.f90, linpack.f) does not link: linpack.f calls isamax, sscal, saxpy and sdot, which are in Src/Sp/blas1.f and missing from the readme list. Log: evidence/original-attempt.log.

Build fix (build-only): blas1.f is compiled separately with gfortran -ffree-form, because its continuation lines are free-form in a .f file. No source file is edited. The manifests pre, mid and post are identical (6 files); verify_sources record returned build-only (exit 0).

Command: `bash reports/cabay1997-vecpade-766/recipe.sh` (fetch is sha256-checked; the shar header above `#! /bin/sh` is removed before unpacking).

Environment: gfortran from conda-forge (micromamba) inside the sandbox; archive sha256 f62245620e2f3c48b7c5555c266adfbb9a496fc3d74d5cc9941cf96cb8d40acd.

Difference from RES1 (not in the claim): two entries in the S_star block print as -0. where RES1 has 0. Signed-zero print only.

Evidence: reports/cabay1997-vecpade-766/evidence/ (original-attempt.log, build.log, run.log, pass1-output.txt, pass2-output.txt, values.txt, manifest.pre/mid/post, reference/RES1).

Status: the G5 clean replay has not been run. replay-due will be RED for this result until `tools/replay.py --id cabay1997-vecpade-766` runs in its own wake.
