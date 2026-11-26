# smith2010-fm-911: TOMS 911 (FM multiple-precision package), sample 2 root

Claim: the real root of x**5-3x**4+x**3-4x**2+x-6 printed by SampleFM sample 2 (500 decimal places), rounded to double, is 3.1206562153267265 (tol_abs 1e-15, registered in the queue entry).

Verdict: reproduced. Basis: patched (build-only).

Paper value: not used (article not read; the claim rests on the shipped SampleFM.out).
Our value: 3.1206562153267265 in pass 1 (gfortran -O3) and pass 2 (gfortran, no optimisation flags, clean directory). The first 80 digits of the printed root match the shipped SampleFM.out.

Original attempt (G1): the archive as shipped. `make` in the archive's Doc directory stops with "No rule to make target 'fmsave.f95'" because the Makefile looks for the sources beside it. Log: evidence/original-attempt.log.

Build: the authors' Doc/Makefile rules, run unedited from an output directory with VPATH pointing at the unedited tree, gfortran with -O3 on the command line. Nothing in the tree is edited. Manifests pre, mid and post are identical (6 files). Build-only, so the paper check (G2) is not needed.

Command: `bash reports/smith2010-fm-911/recipe.sh` (it runs everything in the sandbox; the fetch is sha256-checked).
Environment: gfortran from conda-forge via micromamba inside the sandbox; the archive sha256 is 7ab4881d8495c8eca2d633835827e5c14c037dd5c0d8d1ea4729facc8234065c.
Evidence: reports/smith2010-fm-911/evidence/ (original-attempt.log, pass1-build.log, pass1-run.log, pass2-run.log, pass1-output.txt, pass2-output.txt, values.txt, manifests, reference/SampleFM.out).

Status: not committed. The gates reject the queue entry because it has no `code.archive` field; see note-to-scout.md. The G5 clean replay has not been run.
