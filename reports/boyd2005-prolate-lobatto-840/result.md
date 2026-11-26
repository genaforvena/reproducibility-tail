# boyd2005-prolate-lobatto-840: result

**Verdict: blocked** (basis: patched). The numbers agree with the registered claim; the verdict is held at gate G2, which needs a paper check that this wake could not do.

## Claim
N=6, c=5 in the authors' driver (TOMS 840, prolate-Lobatto grid points and weights). Registered values, from the shipped reference output `Matlab/Dp/Drivers/Res`: xprol(2) = -0.7456 and wprol(3) = 0.5305, absolute tolerance 2e-4 (fixed before any run).

## What was run
- Original attempt (G1, failed): the driver as shipped, under GNU Octave 10.3.0, stops at line 9 with `'clf' undefined`. Log: `evidence/original-attempt.log`.
- Patch (run-time, not build-only): four workarounds kept outside the authors' tree in `impl/shim/`: a no-op `clf`, an alias `TP_NewtonJac` for `TP_NewtonJAC.m` (case mismatch), plot stubs (lines 171-175 of `TP_NewtonJAC.m` only), and Octave's m library on the path. No authors' file is edited.
- Our code: `impl/print_values.m` calls the authors' `TP_LobptswtsPERT(6,5)` and prints the two values.
- Two passes, each in a clean directory, through `tools/sandbox.sh`: `recipe.sh`. Logs: `evidence/pass-1.log`, `evidence/pass-2.log`.

## Values
| value | registered | ours (both passes) | difference | within 2e-4 |
|---|---|---|---|---|
| xprol(2), N=6, c=5 | -0.7456 | -0.7455547968 | 4.5e-5 | yes |
| wprol(3), N=6, c=5 | 0.5305 | 0.5305302056 | 3.0e-5 | yes |

The registered values have four decimals, so their own rounding alone is up to 5e-5.

## Why the verdict is blocked
Gate G2 applies to a patched result that is not build-only: each new piece must cite the paper's section or equation, and parameters must be checked against the paper itself. The four workarounds carry no numerical change, but the gate does not exempt them. The article text was not readable here: the ACM DOI page and the author's site both returned HTTP 403, and a search found no free full text.

- Resolver: the operator, who can supply the article through library access, or an author-archived copy.
- Missing evidence: the paper's section or equation for the N=6, c=5 computation, and the parameter check against it.
- Bounded action for the next rerun wake: try the author archive once. If there is no text, the entry stays `blocked` with this cause.

## Environment pins
Netlib `840.gz`, sha256 `b213f74e8eadba736256700f462906138d71615c29fefdbb871b5a3ba5703aff`. GNU Octave 10.3.0 (conda-forge, micromamba, pinned `octave=10.3.0`). Reference `Res` sha256 `0d3046d88be0c8e467356911c8c71f127a28ffd1ce5eab27b8e9144274b951bb`.

## Observed warnings
`fieldnames` is undefined inside the Octave optimization PKG_ADD (eight warnings per run). It is not on the result path.
