# goano1995-fermi-745: result

**Verdict:** reproduced
**Basis:** patched (build-only: `-finit-local-zero` passed to gfortran; no source byte changed)
**Paper:** Algorithm 745, complete and incomplete Fermi-Dirac integral (Goano, ACM TOMS 21(3), 1995). The article was not read; the claim rests on the shipped test input `FERTST.IN`.

## Claim

The authors' `FERTST` driver computes `FERMID(ORD=0.5, X=5.0)` for row 17 of the `FERMID` block in `FERTST.IN`. The value must equal the shipped reference `8.8442088952430` to relative tolerance 1e-10 (registered in the queue entry; recorded as absolute tolerance 8.844208895243e-10 at that value).

| Value | Paper (reference) | Ours | Tolerance | Result |
|---|---|---|---|---|
| FERMID(0.5, 5.0) | 8.844208895243 | 8.844208895243 | 1e-10 rel | agrees |

## Original attempt (G1, kept)

`src.f` compiled as shipped (`gfortran -O0` and `-O2`) runs to the end, but gives `FERMID(0.5, 5.0) = 3.1115013689941`, and 15 of the 36 `FERMID` rows disagree with their shipped references (several are NaN). The same 15 rows fail at both optimisation levels. The authors' own `FERTST.OUT` matches the reference. Log: `reports/goano1995-fermi-745/evidence/original-attempt.txt`.

## Diagnosis (not isolated)

With `-finit-local-zero`, the claimed point and all 36 rows match within 1e-10 relative (`evidence/diagnostic-uninit.txt`). This is consistent with a local variable that `src.f` reads before it is set (undefined behaviour), which the authors' compiler happened to leave zero. Which variable is not isolated: `gfortran -Wall` reports none, and `FDPOS` reads `LOGGAM` only after it is set on one path. This is a diagnosis with limits, not a confirmed cause.

## Command and pins

- Recipe: `reports/goano1995-fermi-745/recipe.sh`
- Build: `gfortran -O0 -finit-local-zero src.f -o fertst_O0` and `gfortran -O2 -finit-local-zero src.f -o fertst_O2`
- Archive: `netlib.org/toms/745.gz`, sha256 `575d82e32dfdbe780834f0d7cfb49bfd82f8394fd25c50c9c40cc7daccf89ae0`
- Build-only check: manifests `pre`, `mid`, `post` in `evidence/` are equal over the sources.

## Passes and replay

- Pass 1 (`-O0`) and pass 2 (`-O2`) both print `FERMID rows 36, matching reference to 1e-10 rel: 36` (`evidence/pass1-run.txt`, `evidence/pass2-run.txt`, `evidence/values.txt`).
- G5 clean replay, 2026-11-27T01:12:31Z: agrees with the record (`evidence/replay-2026-11-27T011231Z.log`).

## Evidence

`reports/goano1995-fermi-745/evidence/`: `original-attempt.txt`, `build.log`, `runs.log`, `pass1-run.txt`, `pass2-run.txt`, `values.txt`, `diagnostic-uninit.txt`, manifests, and the replay log. The machine-readable record is `result.json`.

## What would change the verdict

The article was not read, so the claim is the shipped test value, not a value checked against the paper. If the article states a different intended value, the claim needs review. The as-shipped mismatch stays recorded as the original attempt.

Result written 2026-11-27 from the committed `result.json` and evidence (the prose had not been written when the entry was first reproduced).
