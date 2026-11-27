# benner2016-shheig-961: SHHEIG (TOMS 961), DGHFDF example

**Verdict: reproduced.** Basis: `patched` (build-only). Grades and gates are computed in `ledger.md` and `result.json`.

## Claim (registered before any run, queue/benner2016-shheig-961.json)

The ALPHAR, ALPHAI and BETA vectors printed by the shipped example driver `TDGHFDF.f` (input `examples/DGHFDF.dat`, a real 8 by 8 skew-Hamiltonian/Hamiltonian pencil) agree elementwise with the shipped reference output `examples/DGHFDF.res` within absolute tolerance 1e-3. The claim is the code's own reference output, not a value from the paper. Z, Q and U are not part of the claim, because the readme says some signs may differ between runs.

## Values

| vector | reference (paper) | ours |
|---|---|---|
| ALPHAR | 0.7353, 0.0000, 0.5168, -0.5168 | 0.7353, 0.0, 0.5168, -0.5168 |
| ALPHAI | 0.0000, 0.7190, 0.5610, 0.5610 | 0.0, 0.719, 0.561, 0.561 |
| BETA | 2.0000, 2.8284, 11.3137, 11.3137 | 2.0, 2.8284, 11.3137, 11.3137 |

All twelve agree at the four printed decimals; the largest difference is 0.

## What was tried (G1)

1. **Original attempt, logged** (`evidence/original-attempt.log`): the archive as shipped, `make.inc` unedited. The library builds (`lib_exit=0`). The example does not link: `cannot find ../libs/blas64.a`. The archive does not contain SLICOT, LAPACK or BLAS. Outcome: `failed`.
2. **Dependencies, pinned** (fetch and build in the sandbox):
   - SLICOT 5.9.1 source, `slicot_5.9.1.orig.tar.gz`, sha256 `c059f82128bfb8848bf3ad4edf1f034d4d1910e79440f149861e90b7ad793efc` (from the Ubuntu noble pool; the sha256 matches the `.dsc`). Built with cmake `-DSLICOT_INTEGER8=ON` into `libslicot64.a`, because `make.inc` compiles with `-fdefault-integer-8`.
   - LAPACK and BLAS, ILP64, Ubuntu noble 3.12.0-3build1.1 (`liblapack64-dev`, `libblas64-dev`, `liblapack64-3`, `libblas64-3`), sha256 checked against the apt index.
   - gfortran 16.2.0 (conda-forge, via micromamba).
3. **Patch, build-only**: the dependency libraries are copied to `Src/libs/` where the unedited `make.inc` looks (`slicot64.a`, `lapack64.a`, `blas64.a`, an empty `lpkaux64.a`). No source file changed: `verify_sources.py record` says build-only, 80 source files compared, zero modified, removed or added, before and after the build.

## Replay and independence

- **G3 (second pass):** a fresh unpack of the archive, the same libraries and the same commands. `evidence/DGHFDF.pass2.exa` is byte-identical to `evidence/DGHFDF.exa`.
- **G5 (scheduled replay):** not run yet. The `replayed` list is empty; the `replay-due` duty will pick this up.

## Limits

- The dependencies are not the 2013 SLICOT the authors used (the archive does not include it). SLICOT 5.9.1 is a later release. The example links against it, and the values match the reference, which is the only evidence here that the routines behave the same for this input. Each routine's signature was not compared by hand. The verdict is about this build, not about the 2013 library.
- This is a dependency substitution, so the basis is `patched`, not `original`.
- Only the 8 by 8 example is compared. The other SHHEIG examples are not claims.

## Reproduce

`bash reports/benner2016-shheig-961/recipe.sh` (about 3 minutes; network only in the fetch step, inside `tools/sandbox.sh --fetch`). Evidence: `reports/benner2016-shheig-961/evidence/`.
