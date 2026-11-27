# verschelde1999-phcpack-795: reproduced (basis: patched)

**Paper.** Jan Verschelde, "Algorithm 795: PHCpack: A General-Purpose Solver for Polynomial Systems by Homotopy Continuation", ACM TOMS 25(2), 1999, pp. 251-276. The author's copy (homepages.math.uic.edu/~jan/acmtomsphcpack.pdf) was read as text; the ACM page returns 403 from this host.

**Claim (registered, not edited).** The black-box solver (`phc -b`) on the shipped system `Demo/cyclic5` (cyclic 5-roots) finds 70 isolated solutions. Tolerance: exact (0).

**Paper's value.** Table VI, row cyclic5: n = 5, D = 120, BZ = 120, BS = 106, V = 70, #sols = 70 (the caption says "#sols is number of isolated solutions found by PHC"). The shipped `Demo/READ_ME` table has the same row; its hash matches the registered reference (91a8a0ed...).

**Our value.** 70 regular solutions in both passes: `Number of regular solutions : 70`, singular 0, real 10, complex 60, clustered 0, failures 0. Tolerance 0, so 70 = 70.

**Verdict.** reproduced. **Basis.** patched: the authors' code, with two source compatibility fixes and the GNAT 13 toolchain.

## What was run

- Source: netlib TOMS 795.gz, sha256 `6ff06dbb...` checked. Unpacked with the authors' here-document layout (`impl/extract-tree.awk`, no shell archive run), then the authors' own `make links` in each `GNAT/` directory.
- Compiler: GNAT 13.3.0 (`gnat-13` and its runtime, from the Ubuntu noble `.deb` packages, unpacked into the sandbox under `/work/root`; no GNAT on the host). gcc 13 for the C parts of the toolchain.
- Build: `impl/build-phc.sh` runs `gnatmake -O1` on `GNAT/Main/dispatch.adb` (the driver that calls `mainphc`), with all `GNAT/` directories on the search path.
- Run: `phc -b cyclic5 out.txt` in a fresh directory, twice, in the sandbox (`tools/sandbox.sh`).
- Exact command: `reports/verschelde1999-phcpack-795/recipe.sh`.

## Original attempt (G1)

The authors' tree as shipped (no patch) builds, but its batch run does not finish. Across the runs the failure showed as `raised STORAGE_ERROR : stack overflow or erroneous memory access` (log: `evidence/original-attempt-run.log`) or as SIGSEGV. Diagnosis (by reading the source and fixing one thing at a time, not by seeding anything):

1. `GNAT/System/unix_resource_usage.ads` declares the `rusage` record with 32-bit `integer` fields (72 bytes). The `getrusage` call writes glibc's LP64 `struct rusage` (144 bytes) into it, so the call overflows the stack.
2. After fix 1, the run gets further and fails with `CONSTRAINT_ERROR: multivariate_polynomials.adb:855 discriminant check failed`. The expression `(vp(j).k = number) or (vp(j).p /= null)` evaluates both operands in Ada (`or` is not short-circuit), so when `k = number` the discriminant of `vp(j).p` is checked and fails under GNAT 13. The intended test is short-circuit.

## Patches (basis `patched`), in `impl/patch-src.sh`

- `unix_resource_usage.ads`: the private record fields `integer` become `long_long_integer`; the accessors in `unix_resource_usage.adb` convert explicitly. This feeds only the TIMING INFORMATION printout.
- `multivariate_polynomials.adb` (lines 855, 904) and `multivariate_laurent_polynomials.adb` (the same pattern): `or` becomes `or else`.

Neither patch touches the homotopy, the start system, the solver's parameters or the root refinement.

## G2 (fidelity) — how it was checked

The patched result is not build-only (the patches edit sources before the build), so G2 needs a paper check. The check: the paper's Table VI row (above) gives V = 70 and #sols = 70 for cyclic5, the same as the registered claim and the shipped table. The patched pieces are a timing record and a logical-operator fix; neither is a paper algorithm piece, and neither changes a parameter the paper specifies. This is a judgement a person may want to read; the evidence is the paper excerpt in `evidence/paper-table-VI-excerpt.txt`.

## Evidence

- `evidence/shipped-Demo-READ_ME.txt` (reference, hash-checked), `evidence/paper-table-VI-excerpt.txt` (the paper's row).
- `evidence/original-attempt-run.log`, `evidence/original-build.txt` (original build, no error count).
- `evidence/patched-build.txt`, `evidence/patched-run-pass1.log`, `evidence/patched-run-pass2.log`: both passes print 70 regular solutions.
- `evidence/unpack-listing.txt` (646 files), `evidence/gnat-version.txt`, `evidence/recipe-run.log`.

## Pins

GNAT 13.3.0-6ubuntu2~24.04.1 (Ubuntu noble packages), gcc 13.3.0, binutils 2.42, TOMS 795 archive sha256 `6ff06dbb...`, shipped reference sha256 `91a8a0ed...`. Host kernel 6.8.0-149-generic.

## Open

- G5 replay is scheduled by the replay-due duty (`tools/replay.py --id verschelde1999-phcpack-795`), not run here.
- The root count is one number on one system. Other systems in the table are not claimed.
- The paper is read from the author's PDF; the ACM copy was not read.
