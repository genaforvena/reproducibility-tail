# gaviano2003-gkls-829: provisional result (not final)

Status: the reproduced value matches the registered claim. The verdict is NOT final: `result.json` is not written
yet, because the build-only record (gate G2) needs the archive's sha256 registered in the queue entry, and the queue
entry has none. Scout is asked (DM, 18:44Z). No ledger entry for this result yet.

## Claim (registered in queue/gaviano2003-gkls-829.json, not edited)
- D-type function 1, dimension 2, global minimizer coordinates (local minimizer 2, f = -1).
- Registered values: x1 = -0.136, x2 = 0.824, tol_abs 1e-3 each.
- Reference: the shipped `C/Dp/Drivers/test001.txt` (copied to evidence/reference/test001.txt).

## Our value
- Pass 1 (clean directory, `./gkls`): x1 = -0.136, x2 = 0.824. The whole regenerated test001.txt is identical to the
  shipped file, except that the shipped file has no final newline.
- Pass 2 (clean directory, same binary): x1 = -0.136, x2 = 0.824. Same bytes.
- Difference from the claim: 0 at the printed 3 decimals, well within tol_abs 1e-3.

## Basis: patched (G1 original attempt failed)
- Original attempt (evidence/original-attempt.log): `make CC=gcc` as the Makefile documents fails at the link step with
  `undefined reference to 'sin'`. The Makefile puts `-lm` before the objects, which the default --as-needed linker of this
  host rejects. Log kept, never overwritten.
- Patch: the authors' Makefile is run unchanged with one linker flag, `make CC=gcc CFLAGS=-Wl,--no-as-needed`. No source
  file and no Makefile line is edited. The manifests (evidence/manifest.pre, mid, post) show the authors' sources identical
  before and after the build; the compare step reports the build-only case, which is not written to result.json yet.
- Grade if it holds: B (the authors' code with a build fix).

## Gates status
- G1: original attempt failed (link error, log kept). Patched build as above.
- G2: OPEN until the record is written. Blocked on the queue's missing `code.archive` sha256 (resolver: scout).
  Archive sha256 computed in the sandbox: e4bd1b05f73b9a697c69998ba190226b38133b68d83f0b3da2cd8d9f99a5f5f6.
- G3: two clean passes gave the same value (recipe.sh, evidence/run1-*, run2-*).
- G5: replay after the result exists.
- Claim reference: queue `claim.reference.sha256` is null; the gate may need it recorded. Flagged for scout.

## Pins and reproduction
- Command: `reports/gaviano2003-gkls-829/recipe.sh` (fetch, unpack, G1 attempt, build, manifests, two runs).
- Source: netlib.org/toms/829.gz, sha256 e4bd1b05f73b9a697c69998ba190226b38133b68d83f0b3da2cd8d9f99a5f5f6.
- Build: host gcc 13.3.0 (Ubuntu 24.04) in the sandbox; the sandbox's /usr/bin/gcc.

## Evidence
- evidence/original-attempt.log (G1)
- evidence/build.log (the patched build)
- evidence/run1-test001.txt, run2-test001.txt (and their value files)
- evidence/reference/test001.txt (shipped reference)
- evidence/recipe-run.log (last full recipe run)
- evidence/manifest.pre, manifest.mid, manifest.post (build-only proof)
