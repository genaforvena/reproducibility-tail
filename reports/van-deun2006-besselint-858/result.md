# van-deun2006-besselint-858: reproduced (basis: patched)

**Claim** (scout, `queue/van-deun2006-besselint-858.json`, registered 2026-11-26T15:05:31Z, not edited): the shipped reference output of CALGO/TOMS Algorithm 858 (Van Deun & Cools 2006), `experiments.out` block "Ex. 5.1", prints `I = 6.106434990872165e-02` for `besselint(sqrt([2 3 5 7 11]), 0, 1)`. Tolerance, fixed before any run: absolute 1e-10.

**Paper value** (shipped reference): 6.106434990872165e-02.
**Our value**: 6.106434990872165e-02 (both driver runs, identical). Difference 0 (margin 0% of the tolerance).
**Verdict**: reproduced. Computed from the recorded value and the registered tolerance (`checks/gates.py` G4).
**Basis**: `patched`. The authors' code ran unchanged, but the first attempt failed for an environment reason (below).

This is an artifact-reference claim: the oracle is the authors' own shipped output, not a number printed in the paper. It shows the code still computes what its authors recorded; it does not test the paper's text.

## Original attempt (G1)

The authors' `experiments.m`, run unmodified under Octave 10.3.0 (conda-forge, in the sandbox scratch), stops at Example 1.1 with `error: 'repmat' undefined near line 291 ... besselint>ira`. The log is `evidence/original-attempt.log`.

The cause is the environment, not the authors' code. The relocated conda build does not find its own m-library: `which` and `pkg` are undefined, and `OCTAVE_HOME` still shows a build placeholder. `repmat.m` exists in the install (`share/octave/10.3.0/m/general/repmat.m`), so it is only missing from the path.

I also tried Octave Forge `general-2.1.0` (sha256 `addb8d30…`). It does not provide `repmat`, so it is not the fix. It is not used by the recipe.

## Patch (the basis)

The only change is an Octave search path: `addpath(genpath('/work/oct/share/octave/10.3.0/m'))`, the m-library of the same install. The driver then ran to exit 0 on both passes. No file of the authors' is edited and no new code is written, so G2 has nothing to cite beyond the path itself. The inputs are the paper's Example 5.1 as the driver states them (`a=sqrt([2 3 5 7 11]); nu=0; m=1`), which are the claim's own parameters.

## Checks

- Archive: `netlib.org/toms/858.zip`, sha256 `63ed546d…` matches the queue (`/work/858.zip: OK`).
- Reference: `experiments.out` copied out of the archive, sha256 `0d7e3986…` matches the queue.
- G3: two driver runs, both print the same Ex. 5.1 value (`run1.log.gz`, `run2.log.gz`).
- Context, not the claim: all 33 `I` values printed by the driver agree with the shipped file; the largest difference is 7.6e-11, which is inside the 1e-10 tolerance but close to it. This is an observation about the other examples; the registered claim is Example 5.1 only.

## Exact command

    reports/van-deun2006-besselint-858/recipe.sh

It fetches the pinned archive (sha256 checked), micromamba and Octave 10.3.0 (fetch steps only), copies the reference, runs the original attempt once (kept, not overwritten), then runs the patched driver twice and prints `VALUE I_Ex5_1 <number>`. Every untrusted step goes through `tools/sandbox.sh`.

## Environment pins

- netlib TOMS 858.zip, sha256 `63ed546d228e687e54ceed3dfeeb5d0bd82497477ddf545db6c7a8458af57431` (queue).
- GNU Octave 10.3.0 (conda-forge `octave-10.3.0-pl5321hd0fbda6_4`, `unzip`), micromamba from micro.mamba.pm.
- Octave Forge `general-2.1.0` tarball was downloaded during exploration and is not used by the recipe.
- Licence: the archive README does not state one (the queue records this as a gap); the code is not redistributed here.

## Open notes

- Octave emits many `Matlab-style short-circuit` warnings from the authors' code; they are in the run logs and do not change the values.
- Whether the same value holds under MATLAB itself is not tested here; the authors' 2006 MATLAB environment is not available.
