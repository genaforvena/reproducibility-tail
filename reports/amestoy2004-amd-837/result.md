# amestoy2004-amd-837: Algorithm 837 (AMD, approximate minimum degree ordering), TOMS 837, C

**Claim (pre-registered, unchanged):** the shipped demo output Demo/amd_demo.out, section for can_24, prints
`LDL' flop count for real A: 647`. The registered value is 647, tolerance exact integer equality (tol_abs 0).

**Our value:** 647 on both clean passes.

**Verdict:** `reproduced`. **Basis:** `original`. The authors' Makefiles ran unchanged; no patch, no build flag.

## What ran

- Fetch: `https://netlib.org/toms/837.zip`, unpacked inside the sandbox scratch. The sha256 served today is
  `d15f725ac0a540a4830972fd4b503669121ae9bd26fb0539c94cc4860f72d96a`. The queue entry registers
  `f9ae8b203a77bbb267a78f86416185b782c00ff845ef6c7e544abeaecce2418d`, which does not match. The claim's own
  reference file, `Demo/amd_demo.out`, hashes to `63a791ae537cb1126fad775dbc9a629a8787568812f8cc47f1a3bf660c9702f0`,
  which is the registered reference hash, so the shipped output the claim rests on is the one registered.
- Original attempt (G1, succeeded): `make lib` in the unpacked top directory (builds Source, then the Demo targets),
  exit 0. The Demo `diff` of its own output against the shipped `amd_demo.out` printed nothing, so the outputs match.
  Log: `evidence/original-attempt.log`.
- Runs (G3): two clean directories, the demo binary from the original build. Each stdout is byte-identical to the
  shipped `amd_demo.out` (`evidence/run1-stdout.txt`, `evidence/run2-stdout.txt`).
- Environment pins: gcc 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1), GNU make, `cc -O -DNBLAS -DDINT`, sandboxed via `tools/sandbox.sh`.

## Command

`reports/amestoy2004-amd-837/recipe.sh` (rebuilds from the archive and reruns both passes; the log is
`evidence/recipe-run.log`).

## Open items

- Scout: the registered archive sha256 (`f9ae8b20...`) does not match the file netlib serves now (`d15f725a...`).
  The claim's reference file matches, so the verdict is not affected. Scout may want to re-register the archive hash.
- G5 replay not yet run; the ledger shows it as due after the first clean replay.
