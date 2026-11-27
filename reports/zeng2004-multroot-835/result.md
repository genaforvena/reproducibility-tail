# zeng2004-multroot-835: reproduced (basis: patched)

Paper: Zeng, Algorithm 835, MultRoot: a MATLAB package for polynomial roots and multiplicities, ACM TOMS 30(2), 2004 (netlib TOMS 835.gz). The ACM article was not read (dl.acm.org returns 403 to automated fetch from this host); the code and the readme are from the netlib archive.

## Claim (as registered, not edited)

- The readme's worked example, `f = poly([ones(1,20),2*ones(1,20),3*ones(1,10),4*ones(1,5)])`, run through `multroot(f)`, gives multiplicities 5, 10, 20, 20 for roots 4, 3, 2, 1 (exact), and the roots within 1e-9 absolute of the printed values 4.000000000000002, 2.999999999999999, 2.000000000000000, 1.000000000000000.
- Queue commit 88873de. The registered values are a list (paper "5,10,20,20"). The gates need one number per value, so result.json splits them per root: the same numbers and tolerances, with multiplicities at tolerance 0 and roots at 1e-9.

## Result

| quantity | paper | ours (pass 3) | tol | ok |
|---|---|---|---|---|
| multiplicity of root 4 | 5 | 5 | 0 | yes |
| multiplicity of root 3 | 10 | 10 | 0 | yes |
| multiplicity of root 2 | 20 | 20 | 0 | yes |
| multiplicity of root 1 | 20 | 20 | 0 | yes |
| root 4 | 4.000000000000002 | 3.99999999999998 | 1e-9 | yes (2e-14) |
| root 3 | 2.999999999999999 | 3.00000000000001 | 1e-9 | yes (2e-14) |
| root 2 | 2.000000000000000 | 2 | 1e-9 | yes |
| root 1 | 1.000000000000000 | 1 | 1e-9 | yes |

The readme's structure-preserving condition number, 73.6821, also reproduced (not a registered value).

## Basis and original attempt

- Original attempt (G1, failed): `octave-cli` 10.3.0 run with the authors' directories on the path but without loading Octave's own m-library. The conda build's default load path lacks it, so `poly` is undefined and the authors' code is never reached. Log: `evidence/original-attempt-octave-nopath.log`.
- Patched: `impl/run_example.m` adds Octave's m-library (`addpath(genpath(...))`) and the authors' `Matlab/Src` and `Matlab/Drivers` directories, then calls `multroot` exactly as the readme does. No file of the authors' code is edited. The fault is the environment, so the workaround is recorded as a patch and the basis is `patched`.
- G2 (paper check) is marked pass for this harness only: the polynomial and the call are the readme's section 3 example, checked by reading `evidence/readme.txt`; the harness adds no algorithm of its own.
- No build step: Octave interprets the authors' code. The archive is a shell archive, not executed; `extract-tree.awk` (a copy of the bai helper that also accepts the quoted `"SHAR_EOF"` form) copies heredoc bodies verbatim. Listing: `evidence/unpack-listing.txt` (135 files).

## Determinism

- Multiplicities are the same in all three passes.
- Roots differ between passes by up to about 4e-14. The cause is the authors' code: `Matlab/Src/uminsv.m` and `zminsv.m` draw an unseeded `rand()` start vector. The recipe does not seed it; seeding would be a choice the paper does not state. The 1e-9 tolerance is far above the spread.
- Values: `evidence/values-pass2.txt` (post-split recipe pass), `evidence/values-pass3.txt` (recipe pass today); the pre-split pass is in `evidence/probe-run2.log`.

## Exact command and pins

- `bash reports/zeng2004-multroot-835/recipe.sh` (it needs `tools/sandbox.sh`; it is run under bash, the file is not executable in this checkout).
- Fetch: `835.gz`, sha256 `ce26ae432aeb7009b30e066a4da73092baaacc7fc2525668646fd307adfdb8ff`, checked by the recipe.
- Octave: GNU Octave 10.3.0 (`evidence/octave-version.txt`), from conda-forge via micromamba 2.10.0 into the sandbox scratch directory (`evidence/fetch-octave.log`).

## Evidence

- `evidence/original-attempt-octave-nopath.log`, `evidence/probe-run2.log`, `evidence/fetch-octave.log`, `evidence/unpack-listing.txt`, `evidence/recipe-run.log`, `evidence/recipe-run-raw.log`, `evidence/values-pass2.txt`, `evidence/values-pass3.txt`, `evidence/readme.txt`, `evidence/multroot.m`.

## Replay and recurrence

Not replayed yet (G5 na). The next replay is scheduled by the ledger's replay-due duty; `python3 tools/replay.py --repo . --id zeng2004-multroot-835` reruns it from an empty scratch directory.

## Limits

- Ran the authors' code under Octave, not MATLAB. The MATLAB behaviour of `rand` and the Octave one may differ; only the reproduced values are claimed here.
- The ACM article was not read. The claim rests on the archive's own printed table.
