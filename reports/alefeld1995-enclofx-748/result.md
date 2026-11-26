# alefeld1995-enclofx-748: Algorithm 748 (ENCLOFX), enclosing zeros of continuous functions

**Verdict: reproduced. Basis: original.** The authors' own Fortran 77 code ran unchanged and reproduced its shipped reference output.

## Claim (registered, not edited)
- Value: ROOT for NPROB=1, N=1 (first line of testdata), from the shipped testout: 1.8954942670340.
- Tolerance: absolute 1e-8, fixed before the run.
- Source: `artifact-reference`. This is the code's own reference run, not a number printed in the paper. The ledger marks it as shipped reference output.

## Our value
- Both passes: 1.8954942670339809 (difference 2e-14).
- Pass 1: `-O2`. Pass 2: `-O0`. Both with conda-forge gfortran 16.2.0, same as in the greenberg recipe.
- Across all 154 roots in testout, every run root agrees within 1e-8 (max abs difference 4e-13). Evidence: `evidence/run1-stdout.txt`, `evidence/run2-stdout.txt`.

## Original attempt (G1)
- The archive `748.gz` (sha256 d82ccafd...) splits into driver.f, enclofx.f, exdrive.f, testdata, testout.
- `driver.f` and `enclofx.f` compile and run unchanged. Log: `evidence/original-attempt.log`.
- `exdrive.f` is a separate standalone program with its own MAIN, INIT and FUNC. Linking it with driver.f fails with duplicate symbols. That was my build-set mistake on the first try, not a failure of the authors' code. The log is kept as `evidence/original-attempt-mistaken-with-exdrive.log`.

## Gates
- G1 pass (original succeeded). G3 pass (two builds, same value). G2 not applicable (original basis).
- G5 pass: clean replay at 2026-11-26T18:26Z agrees with the record (`evidence/replay-2026-11-26T182618Z.log`).

## Command and pins
- `bash reports/alefeld1995-enclofx-748/recipe.sh`
- Fetch in sandbox: 748.gz, sha256 checked. Compiler: micromamba, conda-forge `gfortran_linux-64=16.2.0`.
- Helpers (CC0, ours): `impl/split_748.py`, `impl/extract_value.py`, `impl/compare_roots.py`.

## Limits
- Reproduces the archive's shipped reference output, which shows that the code still computes what its authors saw. It does not check the paper's own table, which was not read.
- Tested on Linux x86_64 with one compiler version.
