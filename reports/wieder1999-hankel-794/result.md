# wieder1999-hankel-794: TOMS 794 (HANKEL), numerical Hankel transform

**Verdict: reproduced.** Basis: `patched`. Build-only in the record sense (no authors' source file edited; three manifests agree), but the patch supplies a missing dependency: the machine constants `D1MACH` and `I1MACH`, written in `impl/machine.f`.

**Gate state: not yet committable.** `checks/gates.py` reports one violation: `patch.archive_sha256` must equal the sha256 the queue entry registers for the archive, and the entry does not register one (see "Open item"). Until that is fixed, `result.json` and `ledger.md` are not committed.

## Claim

- Quantity: HT(XI=5.0, NU=1.0) as printed by the authors' driver into its result file.
- Paper (shipped reference, `Fortran77/Drivers/Dp/res` in netlib 794.gz): **0.208245531E-01**.
- Tolerance (registered in the queue entry, not edited): absolute **1e-9**.
- Our value (two passes, identical): **0.208245531E-01**, which is the same printed value to all nine digits. Difference is 0 at the printed precision, far inside 1e-9.

## Passes

| pass | build | value |
|---|---|---|
| original attempt (G1) | gfortran 16.2.0 -O2, authors' sources, no machine constants | link failed (`link_exit=1`) |
| 1 | gfortran 16.2.0 -O2, authors' sources + `impl/machine.f` | 0.208245531E-01 |
| 2 | gfortran 16.2.0 -O0, clean rebuild | 0.208245531E-01 |

## Basis and the original attempt

- The archive's PackingList names `SrcLibs: port`, but the archive does not ship it. `specfun.f` and `src.f` call `D1MACH` and `I1MACH`, so the authors' own build fails at link. Log: `evidence/original-attempt-link.log` (undefined references to `d1mach_` and `i1mach_`).
- `impl/machine.f` supplies those two functions with IEEE double-precision values, written from the PORT description. It was not tuned to the output. A third pass would be needed only if the driver needed more I1MACH units than 1 to 4; it does not, as the link and run show.
- The archive was unpacked by `impl/unshar.py` (a parser; the shell archive is never executed).
- Manifests `evidence/manifests/manifest.{pre,mid,post}` agree (`pre` = `mid`, `mid` = `post`). `verify_sources.py record` classifies the patch as build-only, with five build commands recorded between the second and third manifest calls.

## Command and pins

- Rebuild and rerun: `reports/wieder1999-hankel-794/recipe.sh` (all runs inside `tools/sandbox.sh`).
- Toolchain: `GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0` (`evidence/gfortran-version.txt`), installed by micromamba into the sandbox scratch.
- Archive: netlib `794.gz`, sha256 `bdbd599bf88d0062a161aa01880b4a271a9fca31df3b13bd662c0ecfc83cab29` (checked by `sha256sum -c` inside the sandbox fetch step).
- Shipped reference: `evidence/shipped-res.txt`, sha256 `848121f728e527a1f83dc8f8c5a1d016b140149ccbb61d3c7801cd37fe0e3acd`. Its XI=5.0 row reads `0.100000000D+01 0.208245531D-01`, the same value.

## Evidence

- `evidence/recipe-run.log`, `evidence/pass1-res.txt`, `evidence/pass2-res.txt` (status lines and the result row), `evidence/original-attempt-link.log`.
- `evidence/diff-shipped-vs-run1.txt`: the shipped `res` is the full driver transcript; our `res` file contains the result row only, so the diff is large but the registered number is the one row above.

## Open item (blocks gates, not the verdict)

- The queue entry `queue/wieder1999-hankel-794.json` does not register the archive sha256. The rerun fetched the archive and the sandbox check matched `bdbd599b…cab29`, but I did not write it into the queue. Editing that entry changes its bytes, and gate G0 requires the registered entry to match the commit the run was made against. The provenance change needs to be a scout commit, not a rerun edit.
- Resolver: scout (owner of queue entries). Action: add `sha256 bdbd599bf88d0062a161aa01880b4a271a9fca31df3b13bd662c0ecfc83cab29` to `code.archive`, commit it, then tell the rerun the new commit so `queue_commit` can be set.

## Limits

- The ACM article was not read (dl.acm.org refuses automated fetch from this host). The claim rests on the shipped reference value, as registered.
- The machine constants are our own: the number shows the code path works with IEEE double-precision constants, not that it matches the original PORT library bit for bit.

## What would change the verdict

- A replay that disagrees with 0.208245531E-01 by more than 1e-9 absolute makes the entry CHANGED; diagnose it first.
- If the registered archive sha differs from the one recorded here, the fetch is not the registered archive and the run must be redone against the registered bytes.
