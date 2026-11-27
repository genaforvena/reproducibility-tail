# berntsen1991-dcuhre-698: result

**Verdict:** reproduced
**Basis:** patched (build-only: an `f77` shim around gfortran, outside the source tree; sources unedited)
**Paper:** Algorithm 698, DCUHRE (adaptive multiple-dimensional cubature, sample driver DTEST1), ACM TOMS 17(4), 1991. The paper was not read; the claim is the archive's printed sample output.

## Claim

The live sample `PROGRAM DTEST1` (5-dimensional integral over the unit cube of exp(-sum n z_n^2/2), ABSREQ=0, RELREQ=1E-3, MINCLS=0, MAXCLS=10000, KEY=0, NW=5000) prints integral components 1 to 6, `FTEST CALLS = 3549` and `IFAIL = 0`, as in the shipped sample output (Sun 3/50).

| Value | Paper (shipped) | Ours | Tolerance | Result |
|---|---|---|---|---|
| integral 1 | 0.13850818 | 0.13850818 | 1e-7 abs | agrees |
| integral 2 | 0.06369469 | 0.06369469 | 1e-7 abs | agrees |
| integral 3 | 0.05861748 | 0.05861748 | 1e-7 abs | agrees |
| integral 4 | 0.05407034 | 0.05407034 | 1e-7 abs | agrees |
| integral 5 | 0.05005614 | 0.05005614 | 1e-7 abs | agrees |
| integral 6 | 0.04654608 | 0.04654608 | 1e-7 abs | agrees |
| FTEST CALLS | 3549 | 3549 | exact | agrees |
| IFAIL | 0 | 0 | exact | agrees |

## Original attempt (G1, kept)

`make dtest1` as the makefile documents it stops at once: `make: f77: No such file or directory` (exit 2). The sandbox has no `f77`. Log: `reports/berntsen1991-dcuhre-698/evidence/original-attempt.log`.

## Patch

An `f77` shim (`gfortran -std=legacy`) was placed outside the source tree. No source file was edited: 27 files compared, with no modification, removal or addition in the manifests (`evidence/manifest.pre`, `manifest.mid`, `manifest.post`). `make dtest1` then ran, and `DTEST1` exited 0.

## Limits

The ESTIMATED ERROR column is not claimed. The value checked is the archive's printed sample output, not the paper's own table.

## Command and pins

- Recipe: `reports/berntsen1991-dcuhre-698/recipe.sh`
- Build: `make dtest1` (with the `f77` shim)
- Archive: `698.gz`, sha256 `27d891c14cabaefddd7c9cd6d3a6a2ae5b60eafa70901c32914f019363fda501`

## Replay

- G5 clean replay, 2026-11-27T06:09:36Z: agrees with the record (`evidence/replay-2026-11-27T060936Z.log`).

## Evidence

`reports/berntsen1991-dcuhre-698/evidence/`: `build.log`, `run.txt`, `recipe-run.log`, `original-attempt.log`, `shipped-sample-output.txt`, manifests, and the replay log. The machine-readable record is `result.json`.

Result written 2026-11-27 from the committed `result.json` and evidence (the prose had not been written when the entry was first reproduced).
