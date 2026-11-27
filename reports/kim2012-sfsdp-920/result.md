# kim2012-sfsdp-920: SFSDPplus SDP-stage rmsd on the manual's printed inputs

**Verdict: blocked (on G2 paper check; the measured value is recorded below but `ours` is null in result.json).** **Basis: patched.**

## Claim

Algorithm 920 (SFSDP, Kim, Kojima, Waki, Yamashita, 2012; TOMS 920 archive, MATLAB). `SFSDPplus` on the 3-sensor, 4-anchor example with the inputs printed in the manual (`distanceMatrix0`, `xMatrix0`, `pars.eps = 1e-7`, `minDegree 4`, `objSW 1`, `free 0`). The registered value is the SDP-stage `rmsd = 6.21e-02` from the manual's transcript (`Doc/SFSDPmanual/UserManual.tex`, section SFSDPplus.m). Tolerance: absolute 5e-4, fixed in the queue entry. The article is paywalled and was not read.

## Result

| run | inputs | SDP-stage rmsd |
|---|---|---|
| pass 1 | manual's printed inputs | 6.21e-02 |
| pass 2 (fresh Octave process) | manual's printed inputs | 6.21e-02 |
| shipped `examples/example1.mat` | manual's stated command (`noisyFac 0`, `eps 1e-5`) | 2.13e-05 |

The printed-input value matches the registered claim (difference 0 at the printed precision, inside 5e-4).

The shipped example does not reproduce the transcript value. The manual's stated parameters (`noisyFac = 0`) also disagree with its transcript (estimated noisy factor 8.33e-02). The transcript's data is therefore not the shipped `example1.mat`. This is recorded as a finding about the artifact's documentation, not as a failed reproduction of the claim, which names the printed inputs.

## Why blocked and not reproduced

- The value reproduces only on the inputs the manual prints. Those inputs are not the shipped data file.
- No paper check (G2) was possible: the article is paywalled. A `patched` result may be graded `reproduced` only after G2 passes, and the gate derives the verdict from recorded values, so a matching value with G2 unpassed is rejected. Hence `blocked`, with ours null.
- Blocker: the article text (or a legitimate copy) to check the SFSDP parameters and the rmsd definition against. Resolver: the operator, who can supply the paper; no bounded action in this wake produces it.
- The run needed a compatibility shim (`impl/spones.m`, MATLAB semantics, because conda Octave lacks `spones`) and a BLAS workaround, so the basis is `patched`.

## Environment and patches

- Octave 8.4 (conda-forge) in place of MATLAB. Octave 10.3 fails with "No SOVERSION found in .mex file".
- SDPA 7.3.16 and the sdpam mex from the Debian noble debs, with scotch-int32 libraries, extracted under the scratch directory.
- `LD_PRELOAD` of the system reference BLAS/LAPACK. The conda OpenBLAS segfaults inside the Debian sdpam mex (`dscal_` -> `dsdot_k_ZEN`). `OMP_NUM_THREADS=1`.
- `impl/spones.m`: compatibility shim, basis `patched`.
- `drawPicture` aborts after the rmsd lines ("no graphics toolkits"). The rmsd is printed before the abort; the driver exits with status 1 for that reason, and the value is taken from the log.

## Original attempt

Run as documented in Octave 8.4 without the BLAS preload, the SDPA mex segfaulted after the relaxation was generated and before any rmsd line (`evidence/original-attempt-oct8.log`). Outcome `failed`; this is why the basis is `patched`.

## Exact command

`reports/kim2012-sfsdp-920/recipe.sh` (drivers `impl/driver-manual-printed.m`, `impl/driver-example1-shipped.m`, run through `tools/sandbox.sh`). Logs in `reports/kim2012-sfsdp-920/evidence/`.

## Next

- Scout to confirm the corrected claim location (commit 0558da1) matches this verdict.
- G5 replay is not yet done; the result is not `replayed` until a replay runs.
