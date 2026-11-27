# hong2003-snied-823: TOMS 823 (Snied), EI at I = 4096

**Verdict: not-reproduced (cause: other; not isolated).** The shipped reference output is not produced by the
archive's code under any toolchain or flag set tried here. Basis: `original` (no source file edited; see the
build caveat below). Could not reproduce under these conditions.

## Claim

- Quantity: `EI = SUM/I` at I = 4096 printed by TSNIED (Snied, IFLAG = 1 Owen-type scrambling, DIMEN = 2).
- Paper value (shipped reference, `Drivers/res1`, artifact-reference): **0.9999468969847435**.
- Tolerance (registered in the queue entry, not edited): absolute **1e-9**.
- Our value (pass 1, gfortran 16.2 -O2): **0.99994610736637701**.
- Difference: ours minus shipped = -7.9e-7, about 790 times the tolerance.

## Passes (all four agree on the claimed value)

| pass | build | value at I = 4096 |
|---|---|---|
| 1 | gfortran 16.2 -O2 (the original attempt) | 0.99994610736637701 |
| 2 | gfortran 16.2 -O2, clean rebuild (repeat) | 0.99994610736637701 |
| 3 | gfortran 16.2 -O0 | 0.99994610736637701 |
| 4 | gfortran 13 -O2 (different environment) | 0.99994610736637701 |

Passes 1 and 4 differ in toolchain and passes 1 and 3 in optimisation level; the timing line differs
only in the elapsed time. The verdict is confirmed by the second environment (pass 4).

## Diagnosis attempted (bounded, diagnostic only; none of these changed the claim)

- The miss is not a rounding or optimisation effect: the difference appears at every printed I, not
  only at 4096. Shipped vs ours: I = 512 0.9999562489621427 vs 0.99997540338373248 (1.2e-5);
  I = 1024 0.999713791146755 vs 0.99976773631485671; I = 2048 0.9999491497757775 vs 0.99995030938172536.
- Flag probes (`evidence/probe-*.txt`) leave the output bit-identical: `-O2 -fwrapv`,
  `-O2 -fdefault-integer-8`, `-O2 -fno-tree-vectorize`.
- Not tested, so still open: a different code version (the shipped `res1` may come from another release
  of `src.f`/`extra.f`), a different platform word size or a non-gfortran compiler, and any
  uninitialised-state behaviour that depends on the original system. Which one, if any, would settle it
  is unknown from here.

## Build caveat

`Drivers/Makefile` includes a `makefile.inc` that the archive does not ship, so the authors' documented
build cannot run as shipped. The compile lines in `recipe.sh` are ours (`gfortran <opt>` on `Src/src.f`,
`Src/extra.f`, `Drivers/driver.f`, then linked). No source file is edited. This is the same situation as
`renka1997-ssrfpack-773`, which also recorded basis `original` with compile lines of its own.

## Command and pins

- `reports/hong2003-snied-823/recipe.sh` (fetch, four builds, four runs, `VALUE` line).
- Archive: `https://netlib.org/toms/823.zip`, sha256 `de5eaa5face30d4590a8679a94f0b830229771087afbdd4bdc1b75d11b3f9785` (checked).
- Toolchains: conda-forge gfortran 16.2 (env16) and gfortran 13 (env13), via micromamba inside the sandbox.
  Exact build strings are in the sandbox logs, not pinned further here.

## Evidence

- `reports/hong2003-snied-823/evidence/pass{1..4}-build.log`, `pass{1..4}-run.log`, `pass{1..4}-stdout.txt`.
- `reports/hong2003-snied-823/evidence/probe-*.txt` (flag probes).
- `reports/hong2003-snied-823/evidence/recipe-run.log`.
- The shipped output is `Drivers/res1` inside the archive (not copied into evidence).
